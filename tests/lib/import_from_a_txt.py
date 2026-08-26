#!/usr/bin/env python3
"""
Converts the raw 'Minishell Map' spreadsheet export (../../a.txt, tab-separated,
Excel-quoted multi-line cells) into per-category case files under tests/cases/*.tsv.

Rerun this whenever a.txt is replaced/extended:
    python3 tests/lib/import_from_a_txt.py

It does NOT trust the spreadsheet's own "Comportement attendu" / exit-code columns
as the pass/fail oracle (those were captured on the original author's machine, with
their own $HOME/paths/env, and would legitimately mismatch here). They are carried
along only as human-readable `note` text. The real oracle is a live bash run,
done later by driver.py.

Categories that are bonus-scope (&&/||, parentheses, wildcard) or that fundamentally
require a real terminal (SIGNAUX, HISTORIQUE) are not written as diff-mode cases here;
they're reported on stdout so nothing silently disappears.
"""
import csv
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from tsv_codec import encode_cell, decode_cell

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
A_TXT = os.path.join(ROOT, "a.txt")
CASES_DIR = os.path.join(ROOT, "tests", "cases")

# category (as it literally appears in a.txt) -> (slug for the output file, mandatory?)
CATEGORY_MAP = {
    "CARACTERES A LA VOLEE (SYNTAXE)  🌦": ("01_syntax", True),
    "💰": ("01_syntax", True),  # mislabeled section in the source sheet; same theme (bare word/$VAR expansion as a command)
    "ECHO   🎉": ("02_echo", True),
    "CD 💿 PWD": ("03_cd_pwd", True),
    "🛫 ENV & EXPORT & UNSET 🛬": ("04_env_export_unset", True),
    "EXIT  ⛔": ("05_exit", True),
    "HEREDOC ⏮️": ("06_heredoc", True),
    "PIPES 🚬": ("07_pipes", True),
    "<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>": ("08_redirections", True),
    "FICHIERS BINAIRES 0️⃣ 1️⃣": ("09_binaries", True),
    "BÂTARDS 🖕": ("10_batards", True),
    # excluded from the .sh runner on purpose:
    "SIGNAUX 🛰": ("__signaux__", False),        # -> needs a real pty, see tests/pty/
    "HISTORIQUE 🏦": ("__historique__", False),  # -> needs arrow-key/readline history, not scriptable via a pipe
    "&&  🍒  ||": ("__bonus__", False),          # bonus, not implemented yet (step 9)
    "( PARENTHESES )": ("__bonus__", False),
    "WILDCARD ⭐": ("__bonus__", False),
}

# Filenames our fixture snapshot (tests/fixtures/base/) actually provides.
KNOWN_FIXTURE_FILES = {
    "bonjour", "hello", "hola",
    "srcs/bonjour", "srcs/hello",
    "Docs/bonjour", "Docs/hey",
}
KNOWN_FIXTURE_DIRS = {"srcs", "Docs"}

PLACEHOLDER_MAP = {
    "\\n (touche entrée)": "",
    "[que des espaces]": "   ",
    "[que des tabulations]": "\t\t",
}


def load_rows():
    with open(A_TXT, newline="", encoding="utf-8", errors="replace") as f:
        rows = list(csv.reader(f, delimiter="\t"))
    # Excel drops trailing empty tabs; pad every row back out to 10 fixed columns.
    return [row + [""] * (10 - len(row)) for row in rows]


def looks_like_input_redir_target(cmd, word):
    """True if `word` is used as a `<` or `<<`... wait heredocs use a delimiter,
    not a file, so only plain `<` matters here."""
    return re.search(r"<\s*" + re.escape(word) + r"(?:\s|$)", cmd) is not None


def command_creates_word(cmd, word):
    """True if `cmd` itself writes `word` via `>`/`>>` before it could be read."""
    return re.search(r">>?\s*" + re.escape(word) + r"(?:\s|$)", cmd) is not None


# Bash builtin shell variables that are NOT part of the inherited environment
# (envp) -- the 42 subject only requires expanding real env vars plus $?, so a
# minishell legitimately (and correctly) expands these to nothing, while real
# bash prints its own dynamic value. Not a bug to chase; not diff-comparable.
BASH_ONLY_VARS = re.compile(
    r"\$\{?(UID|EUID|PPID|RANDOM|SECONDS|LINENO|BASH\w*|HOSTTYPE|OSTYPE|MACHTYPE|GROUPS|HISTSIZE|REPLY|FUNCNAME|DIRSTACK)\b"
)


# Bash builtins/features outside the 42 subject's required set (echo, cd, pwd,
# export, unset, env, exit) -- a minishell correctly does NOT implement these,
# so bash's own behavior for them isn't a valid oracle. Also: a literal tab
# byte piped as "input" is intercepted by GNU readline's own tab-completion
# binding (not passed through to the tokenizer at all) regardless of which
# shell is reading it, so that specific input can't be compared meaningfully
# over a plain pipe either.
OUT_OF_SCOPE_BARE = {":", "!"}


def guess_mode(cmd):
    if BASH_ONLY_VARS.search(cmd):
        return "crash_check"
    if cmd.strip() in OUT_OF_SCOPE_BARE:
        return "crash_check"
    if "\t" in cmd:
        return "crash_check"
    if "./minishell" in cmd:
        return "crash_check"
    """
    diff  -> safe to strictly compare against a live bash run in the sandbox
    crash_check -> only assert "doesn't crash / exit code looks sane"; used when
                   the command references a file we can't confidently fabricate
                   (e.g. the original author's own project files/dirs).
    """
    if re.search(r"\bCtlr-|Ctrl-", cmd):
        return None  # shouldn't happen (SIGNAUX rows are filtered out earlier), safety net
    words = re.findall(r"[./\w-]+", cmd)
    referenced_paths = set()
    for w in words:
        if looks_like_input_redir_target(cmd, w) or (
            w not in ("cat", "ls", "wc", "rm", "grep", "rev") and re.match(r"^\.*/?[\w./-]+$", w)
        ):
            pass  # too noisy a heuristic on its own; refined check below
    # Specifically: any bare-word argument to cat/ls/rm/wc/grep -e or `<` target
    # that is NOT itself created earlier in the same line via > / >>.
    suspects = re.findall(r"(?:<\s*|(?:^|\|)\s*(?:cat|rm)(?:\s+-\w+)?\s+)([\w./-]+)", cmd)
    for s in suspects:
        if s.startswith("-"):
            continue
        if command_creates_word(cmd, s):
            continue
        referenced_paths.add(s)
    for p in referenced_paths:
        top = p.split("/")[0]
        if p in KNOWN_FIXTURE_FILES or top in KNOWN_FIXTURE_DIRS:
            continue
        return "crash_check"
    return "diff"


def extract_heredoc_body(attendu_raw):
    """
    The sheet's "Comportement attendu" column records the full interactive
    transcript, including whatever was typed to satisfy a heredoc -- each such
    line is shown with the sheet's own "> " secondary-prompt notation, e.g.
    "> $HOME\n> hola\n/home/vietdu91\n$>" for `cat << hola` (two typed lines,
    "$HOME" then the closing "hola"). The *command* column only ever captured
    the opening line, so without this the heredoc has no body/delimiter to
    read at all. Grab every leading "> "-prefixed line; the first line that
    isn't one marks where the heredoc closed and real output begins.
    """
    body = []
    for line in attendu_raw.split("\n"):
        if line.startswith("> "):
            body.append(line[2:])
        elif line == ">":
            body.append("")
        else:
            break
    return body


def main():
    rows = load_rows()
    cur_category = None
    by_slug = {}
    excluded_report = {}
    seen = set()

    for row in rows:
        cat_cell = row[0].strip()
        if cat_cell:
            cur_category = cat_cell
        cmd_cell = row[1].strip()
        if not cmd_cell.startswith("$>"):
            continue
        raw = cmd_cell[2:].strip()
        note_bits = [b for b in (row[7].strip(), row[8].strip(), row[9].strip()) if b]
        note = " | ".join(note_bits).replace("\n", " ").replace("\t", " ")

        if cur_category not in CATEGORY_MAP:
            excluded_report.setdefault(cur_category or "?", []).append(raw)
            continue
        slug, mandatory = CATEGORY_MAP[cur_category]
        if not mandatory:
            excluded_report.setdefault(cur_category, []).append(raw)
            continue

        if slug == "06_heredoc" and "<<" in raw:
            heredoc_lines = extract_heredoc_body(row[7])
            if heredoc_lines:
                marker = re.search(r"\n\$>\s*", raw)
                if marker:
                    first_part, rest = raw[: marker.start()], raw[marker.start():]
                else:
                    first_part, rest = raw, ""
                raw = first_part + "\n" + "\n".join(heredoc_lines) + rest

        # Some spreadsheet rows encode a whole multi-command scenario in one cell,
        # e.g. "echo hola > bonjour\n$> cat bonjour" -- each subsequent line is
        # marked with the sheet's own "$> " prompt notation, not literal shell text.
        raw = re.sub(r"\n\$>\s*", "\n", raw)

        if raw in PLACEHOLDER_MAP:
            raw = PLACEHOLDER_MAP[raw]
        elif re.search(r"Ctlr-|Ctrl-|\[touche", raw):
            excluded_report.setdefault(cur_category + " (stray interactive row)", []).append(raw)
            continue

        mode = guess_mode(raw)
        if mode is None:
            continue

        key = (slug, raw)
        if key in seen:
            continue
        seen.add(key)
        by_slug.setdefault(slug, []).append((raw, mode, note))

    os.makedirs(CASES_DIR, exist_ok=True)
    total = 0
    for slug, entries in sorted(by_slug.items()):
        path = os.path.join(CASES_DIR, slug + ".tsv")
        with open(path, "w", encoding="utf-8") as f:
            f.write("# command\tmode\tnote\n")
            for raw, mode, note in entries:
                escaped = encode_cell(raw)
                assert decode_cell(escaped) == raw, f"lossy round-trip for: {raw!r}"
                f.write(f"{escaped}\t{mode}\t{note}\n")
        print(f"wrote {len(entries):4d} cases -> {os.path.relpath(path, ROOT)}")
        total += len(entries)
    print(f"TOTAL imported: {total}")

    print("\n--- excluded from the .sh runner (see reasons) ---")
    for cat, items in excluded_report.items():
        print(f"  {cat}: {len(items)} rows skipped")


if __name__ == "__main__":
    main()
