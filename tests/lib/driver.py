#!/usr/bin/env python3
"""
Core engine for tests/run_tests.sh. Runs each case in tests/cases/*.tsv against
both a real bash and ./minishell, in byte-identical sandboxes, and reports where
they diverge (stdout, stderr, exit code) plus, by default, whether minishell
leaked memory or raised a valgrind error while doing it.

Why a live bash instead of the spreadsheet's own recorded "expected" text:
the spreadsheet's expected output was captured on someone else's machine, with
their own $HOME/paths/PATH -- diffing against a live bash run in the same
sandbox is the only oracle that's actually valid on this machine.

Why the two known normalizations below (and nothing else):
1. minishell always echoes "<prompt><line>" to stdout via readline when stdin
   isn't a tty, and its `exit` builtin/EOF path always print a bare "exit" --
   real bash run non-interactively (as we run it here) does neither. This is
   not a minishell bug, it's how GNU readline behaves off a pipe; stripping it
   is required for ANY output comparison to be meaningful at all.
2. minishell's own error messages are intentionally prefixed "minishell: ...”
   where bash says "bash: ...” -- only that leading program-name token is
   normalized away; the rest of stderr is compared byte-for-byte, so a genuine
   wording/content difference (e.g. a missing argument name in a message)
   still shows up as a real failure.
"""
import argparse
import difflib
import os
import re
import shutil
import signal
import subprocess
import sys
import tempfile
import time

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from tsv_codec import decode_cell

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
CASES_DIR = os.path.join(ROOT, "tests", "cases")
FIXTURES = os.path.join(ROOT, "tests", "fixtures", "base")
MINISHELL_BIN = os.path.join(ROOT, "minishell")

RED, GREEN, YELLOW, CYAN, BOLD, NC = (
    "\033[0;31m", "\033[0;32m", "\033[1;33m", "\033[0;36m", "\033[1m", "\033[0m",
)

PROG_PREFIX_RE = re.compile(r"^(bash|minishell): (line \d+: )?")
SYNTAX_ERR_RE = re.compile(r"syntax error near unexpected token")
ECHOED_SOURCE_LINE_RE = re.compile(r"^`.*'$")


def load_cases(category_filter=None):
    cases = []
    for fname in sorted(os.listdir(CASES_DIR)):
        if not fname.endswith(".tsv"):
            continue
        slug = fname[:-4]
        if category_filter and category_filter not in slug:
            continue
        with open(os.path.join(CASES_DIR, fname), encoding="utf-8") as f:
            lines = f.read().splitlines()
        for line in lines[1:]:  # skip header
            if not line.strip():
                continue
            parts = line.split("\t")
            cmd_raw, mode = parts[0], parts[1]
            note = parts[2] if len(parts) > 2 else ""
            cases.append({"category": slug, "command": decode_cell(cmd_raw), "mode": mode, "note": note})
    return cases


def fresh_sandbox(tmproot, name):
    d = os.path.join(tmproot, name)
    shutil.copytree(FIXTURES, d)
    return d


def run_shell(argv, cwd, input_text, timeout):
    proc = subprocess.Popen(
        argv, cwd=cwd, stdin=subprocess.PIPE, stdout=subprocess.PIPE,
        stderr=subprocess.PIPE, start_new_session=True,
    )
    try:
        out, err = proc.communicate(input=input_text.encode(), timeout=timeout)
        rc = proc.returncode
    except subprocess.TimeoutExpired:
        try:
            os.killpg(os.getpgid(proc.pid), signal.SIGKILL)
        except ProcessLookupError:
            pass
        out, err = proc.communicate()
        rc = "TIMEOUT"
    return out.decode(errors="replace"), err.decode(errors="replace"), rc


def normalize_mini_stdout(raw_stdout, input_lines):
    # Substring-based, not line-based: if a command's own output doesn't end in
    # a newline (e.g. `echo -n`), the *next* prompt-echo glues onto the same
    # physical line instead of starting a fresh one, so line-splitting alone
    # would miss it. Each prompt-echo unit is "<prompt><typed line>\n" --
    # readline always terminates its echo with the newline the user "typed",
    # independent of whatever the previous command printed.
    s = raw_stdout
    pos = 0
    for line in input_lines:
        for prompt in ("minishell$ ", "> "):
            token = f"{prompt}{line}\n"
            idx = s.find(token, pos)
            if idx != -1:
                s = s[:idx] + s[idx + len(token):]
                pos = idx
                break
    # Trailing artifact(s) from however the session ended. There can be TWO:
    # `exit` with bad/extra args prints its unconditional "exit\n" but doesn't
    # actually terminate the shell (matching bash), so the loop then hits a
    # real EOF and prints a second one -- bash only ever prints "exit" at all
    # when interactive, so neither has a counterpart in bash's own output here.
    for _ in range(2):  # at most: the builtin's own print, then the EOF print
        for suffix in ("minishell$ exit\n", "minishell$ exit", "exit\n", "exit"):
            if s.endswith(suffix):
                s = s[: -len(suffix)]
                break
        else:
            break
    return s


def canon(raw):
    return "\n".join(raw.splitlines())


def normalize_stderr(raw_stderr, is_bash=False):
    lines = [PROG_PREFIX_RE.sub("", l) for l in raw_stderr.splitlines()]
    if not is_bash:
        return "\n".join(lines)
    # bash-only: a "syntax error near unexpected token" line is always followed,
    # in non-interactive/script mode, by a second line that just echoes the raw
    # source ("`|'") -- that's bash's own script-diagnostic convention, nothing
    # a minishell is expected to reproduce, so it's dropped before comparing.
    out = []
    i = 0
    while i < len(lines):
        out.append(lines[i])
        if SYNTAX_ERR_RE.search(lines[i]) and i + 1 < len(lines) and ECHOED_SOURCE_LINE_RE.match(lines[i + 1]):
            i += 1
        i += 1
    return "\n".join(out)


def run_valgrind(cwd, input_text, timeout, log_path):
    argv = [
        "valgrind", "--leak-check=full", "--show-leak-kinds=all",
        "--trace-children=yes", "--track-origins=yes", "-q",
        f"--log-file={log_path}", MINISHELL_BIN,
    ]
    proc = subprocess.Popen(
        argv, cwd=cwd, stdin=subprocess.PIPE, stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL, start_new_session=True,
    )
    try:
        proc.communicate(input=input_text.encode(), timeout=timeout)
    except subprocess.TimeoutExpired:
        try:
            os.killpg(os.getpgid(proc.pid), signal.SIGKILL)
        except ProcessLookupError:
            pass
        proc.communicate()
        return False, "timed out under valgrind"

    if not os.path.exists(log_path):
        return True, ""
    with open(log_path, encoding="utf-8", errors="replace") as f:
        log = f.read()
    bad_bytes = 0
    for kind in ("definitely lost", "indirectly lost", "possibly lost"):
        m = re.search(rf"{kind}: ([\d,]+) bytes", log)
        if m:
            bad_bytes += int(m.group(1).replace(",", ""))
    err_m = re.search(r"ERROR SUMMARY: (\d+) errors", log)
    err_count = int(err_m.group(1)) if err_m else 0
    if bad_bytes == 0 and err_count == 0:
        return True, ""
    return False, f"{bad_bytes} bytes leaked, {err_count} valgrind errors (see {log_path})"


def crashed(rc):
    return rc == "TIMEOUT" or (isinstance(rc, int) and rc < 0)


def show_diff(label, a, b):
    diff = list(difflib.unified_diff(a.splitlines(), b.splitlines(), lineterm="", fromfile="bash", tofile="minishell"))
    print(f"   {CYAN}{label}:{NC}")
    for l in diff[:12]:
        print(f"     {l}")
    if len(diff) > 12:
        print(f"     ... ({len(diff) - 12} more lines)")


def main():
    ap = argparse.ArgumentParser(description="Compare ./minishell against bash, case by case.")
    ap.add_argument("-c", "--category", default=None, help="only run case files whose slug contains this substring")
    ap.add_argument("-v", "--verbose", action="store_true", help="show diffs for every failure (default: first N)")
    ap.add_argument("--no-leaks", action="store_true", help="skip the valgrind pass (much faster iteration)")
    ap.add_argument("--timeout", type=float, default=5.0)
    ap.add_argument("--valgrind-timeout", type=float, default=20.0)
    ap.add_argument("--list", action="store_true", help="list matching cases and exit, run nothing")
    ap.add_argument("--max-fail-details", type=int, default=40)
    args = ap.parse_args()

    if not os.path.isfile(MINISHELL_BIN) or not os.access(MINISHELL_BIN, os.X_OK):
        print(f"{RED}error: {MINISHELL_BIN} not found or not executable -- run `make` first{NC}")
        return 1

    cases = load_cases(args.category)
    if args.list:
        for c in cases:
            print(f"[{c['category']}][{c['mode']}] {c['command']!r}")
        print(f"{len(cases)} cases match")
        return 0

    print(f"{BOLD}Running {len(cases)} cases"
          f"{' (leak-checking every case, this is slow)' if not args.no_leaks else ''}...{NC}\n")

    totals = {"pass": 0, "fail": 0, "crash": 0, "leak_fail": 0}
    per_cat = {}
    shown_details = 0

    with tempfile.TemporaryDirectory(prefix="minishell_tests_") as tmproot:
        for idx, case in enumerate(cases, 1):
            cat = case["category"]
            per_cat.setdefault(cat, {"pass": 0, "fail": 0})
            cmd = case["command"]
            input_text = cmd + "\n"
            input_lines = cmd.split("\n")

            # bash and minishell run at the *same* absolute path, one after the
            # other (not two differently-named sibling dirs) -- otherwise any
            # command that prints its own cwd (pwd, $PWD, error messages with
            # full paths...) would trivially "differ" for a reason that has
            # nothing to do with minishell's correctness.
            sandbox = os.path.join(tmproot, f"t{idx}")
            shutil.copytree(FIXTURES, sandbox)
            b_out, b_err, b_rc = run_shell(["bash", "--norc", "--noprofile"], sandbox, input_text, args.timeout)
            shutil.rmtree(sandbox)
            shutil.copytree(FIXTURES, sandbox)
            m_out, m_err, m_rc = run_shell([MINISHELL_BIN], sandbox, input_text, args.timeout)
            shutil.rmtree(sandbox)

            m_out_n = canon(normalize_mini_stdout(m_out, input_lines))
            b_out_n = canon(b_out)
            m_err_n = normalize_stderr(m_err)
            b_err_n = normalize_stderr(b_err, is_bash=True)

            ok = True
            reason = []
            if case["mode"] == "crash_check":
                if crashed(m_rc):
                    ok = False
                    reason.append(f"minishell crashed/timed out (rc={m_rc})")
            else:
                if crashed(m_rc):
                    ok = False
                    reason.append(f"minishell crashed/timed out (rc={m_rc})")
                else:
                    if m_rc != b_rc:
                        ok = False
                        reason.append(f"exit code: bash={b_rc} minishell={m_rc}")
                    if m_out_n != b_out_n:
                        ok = False
                        reason.append("stdout differs")
                    if m_err_n != b_err_n:
                        ok = False
                        reason.append("stderr differs")

            leak_ok = True
            leak_msg = ""
            if not args.no_leaks and not crashed(m_rc):
                leak_dir = fresh_sandbox(tmproot, f"l{idx}")
                log_path = os.path.join(tmproot, f"vg{idx}.log")
                leak_ok, leak_msg = run_valgrind(leak_dir, input_text, args.valgrind_timeout, log_path)
                shutil.rmtree(leak_dir, ignore_errors=True)
                if os.path.exists(log_path) and leak_ok:
                    os.remove(log_path)

            if ok and leak_ok:
                totals["pass"] += 1
                per_cat[cat]["pass"] += 1
            else:
                per_cat[cat]["fail"] += 1
                if not ok:
                    if any("crashed" in r for r in reason):
                        totals["crash"] += 1
                    totals["fail"] += 1
                if not leak_ok:
                    totals["leak_fail"] += 1

                if shown_details < args.max_fail_details:
                    shown_details += 1
                    print(f"{RED}FAIL{NC} [{cat}] {cmd!r}")
                    if reason:
                        print(f"   {', '.join(reason)}")
                    if not leak_ok:
                        print(f"   {YELLOW}leak: {leak_msg}{NC}")
                    if case["note"]:
                        print(f"   {CYAN}sheet note: {case['note'][:100]}{NC}")
                    if args.verbose:
                        if m_out_n != b_out_n:
                            show_diff("stdout", b_out_n, m_out_n)
                        if m_err_n != b_err_n:
                            show_diff("stderr", b_err_n, m_err_n)

    total = totals["pass"] + totals["fail"]
    print(f"\n{BOLD}=== RESULTS ==={NC}")
    print(f"Total:  {total}")
    print(f"{GREEN}Passed: {totals['pass']} ({(totals['pass']*100//total) if total else 0}%){NC}")
    print(f"{RED}Failed: {totals['fail']}{NC}  (of which crashed/timed out: {totals['crash']})")
    if not args.no_leaks:
        print(f"{YELLOW}Leak/valgrind-error failures: {totals['leak_fail']}{NC}")
    print()
    for cat in sorted(per_cat):
        p, f = per_cat[cat]["pass"], per_cat[cat]["fail"]
        t = p + f
        pct = (p * 100 // t) if t else 0
        print(f"  {cat:30s} {t:4d} | pass {p:4d} fail {f:4d} | {pct:3d}%")

    return 1 if totals["fail"] else 0


if __name__ == "__main__":
    sys.exit(main())
