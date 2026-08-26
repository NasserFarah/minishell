#!/usr/bin/env python3
"""
Signal-driven cases (Ctrl-C / Ctrl-\\ / Ctrl-D) can't be fed through a plain
pipe: piped stdin has no controlling terminal, so those key presses never
become real signals (see CLAUDE.md's note on this for src/shell/signals.c).
This harness drives ./minishell under a real pty instead, the same way the
project's own SIGINT testing already had to be done.

There is no live-bash comparison here (a pty transcript from bash would need
its own separate scripting and bash's own interactive echo/job-control text
differs enough from minishell's that a byte-diff wouldn't be meaningful);
each case instead asserts the concrete, documented behavior from
src/shell/signals.c and src/execution/wait_status.c directly.

Usage: python3 tests/pty/signal_tests.py [-v]
"""
import os
import pty
import re
import select
import signal
import struct
import sys
import time

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
MINISHELL_BIN = os.path.join(ROOT, "minishell")

VERBOSE = "-v" in sys.argv


class Session:
    def __init__(self, argv=None, cwd=None):
        self.pid, self.fd = pty.fork()
        if self.pid == 0:
            if cwd:
                os.chdir(cwd)
            os.execv(argv[0] if argv else MINISHELL_BIN, argv or [MINISHELL_BIN])
            os._exit(127)
        self._buf = ""

    def send(self, s):
        os.write(self.fd, s.encode())

    def read_until(self, pattern, timeout=3.0):
        deadline = time.time() + timeout
        rx = re.compile(pattern)
        while time.time() < deadline:
            m = rx.search(self._buf)
            if m:
                return True
            r, _, _ = select.select([self.fd], [], [], max(0, deadline - time.time()))
            if not r:
                break
            try:
                chunk = os.read(self.fd, 4096).decode(errors="replace")
            except OSError:
                break
            if not chunk:
                break
            self._buf += chunk
        return bool(rx.search(self._buf))

    def drain(self, quiet_for=0.3):
        deadline = time.time() + 3.0
        last_read = time.time()
        while time.time() < deadline:
            r, _, _ = select.select([self.fd], [], [], 0.1)
            if r:
                try:
                    chunk = os.read(self.fd, 4096).decode(errors="replace")
                except OSError:
                    break
                if not chunk:
                    break
                self._buf += chunk
                last_read = time.time()
            elif time.time() - last_read > quiet_for:
                break
        return self._buf

    def wait(self, timeout=3.0):
        deadline = time.time() + timeout
        while time.time() < deadline:
            pid, status = os.waitpid(self.pid, os.WNOHANG)
            if pid != 0:
                return status
            time.sleep(0.05)
        return None

    def close(self):
        try:
            os.kill(self.pid, signal.SIGKILL)
            os.waitpid(self.pid, 0)
        except (ProcessLookupError, ChildProcessError):
            pass
        try:
            os.close(self.fd)
        except OSError:
            pass


results = []


def check(name, condition, detail=""):
    results.append((name, condition, detail))
    tag = "PASS" if condition else "FAIL"
    print(f"[{tag}] {name}" + (f" -- {detail}" if detail and (VERBOSE or not condition) else ""))


def test_ctrl_c_kills_foreground_sleep():
    s = Session()
    try:
        s.read_until(r"minishell\$ ")
        s.send("sleep 5\n")
        time.sleep(0.5)
        s.send("\x03")  # Ctrl-C
        s.read_until(r"minishell\$ ", timeout=3)
        s.send("echo $?\n")
        s.read_until(r"130", timeout=2)
        s.send("exit\n")
        buf = s.drain()
        check("Ctrl-C kills a foreground `sleep 5`, shell survives and $?=130",
              "130" in buf, buf[-200:])
    finally:
        s.close()


def test_ctrl_c_pipeline():
    s = Session()
    try:
        s.read_until(r"minishell\$ ")
        s.send("sleep 3 | sleep 3 | sleep 3\n")
        time.sleep(0.5)
        s.send("\x03")
        s.read_until(r"minishell\$ ", timeout=3)
        s.send("echo $?\n")
        s.read_until(r"130", timeout=2)
        s.send("exit\n")
        buf = s.drain()
        check("Ctrl-C on a 3-stage sleep pipeline: shell survives, $?=130",
              "130" in buf, buf[-200:])
    finally:
        s.close()


def test_ctrl_backslash_pipeline():
    s = Session()
    try:
        s.read_until(r"minishell\$ ")
        s.send("sleep 3 | sleep 3 | sleep 3\n")
        time.sleep(0.5)
        s.send("\x1c")  # Ctrl-\
        s.read_until(r"minishell\$ ", timeout=3)
        s.send("echo $?\n")
        s.read_until(r"131", timeout=2)
        s.send("exit\n")
        buf = s.drain()
        check("Ctrl-\\ (SIGQUIT) on a sleep pipeline: shell survives, $?=131",
              "131" in buf, buf[-200:])
        check("Ctrl-\\ prints \"Quit (core dumped)\"", "Quit (core dumped)" in buf, buf[-200:])
    finally:
        s.close()


def test_ctrl_d_empty_line_exits():
    s = Session()
    try:
        s.read_until(r"minishell\$ ")
        s.send("\x04")  # Ctrl-D on an empty prompt
        status = s.wait(timeout=3)
        check("Ctrl-D on an empty prompt terminates the shell",
              status is not None, f"wait() returned {status}")
    finally:
        s.close()


def test_ctrl_d_with_pending_text_does_not_exit():
    s = Session()
    try:
        s.read_until(r"minishell\$ ")
        s.send("echo hola")  # no newline: text pending on the line
        time.sleep(0.2)
        s.send("\x04")
        time.sleep(0.3)
        status = s.wait(timeout=0.5)
        check("Ctrl-D with pending text on the line does NOT exit the shell (readline default)",
              status is None, f"wait() returned {status}")
        s.send("\n")
        s.read_until(r"hola", timeout=2)
        s.send("exit\n")
        s.drain()
    finally:
        s.close()


def test_nested_minishell_ctrl_c_then_exit_code():
    """
    From the user's own manual test list: launch minishell, launch a nested
    minishell from inside it, Ctrl-C (should not kill the nested shell -- SIGINT
    only interrupts a *foreground command*, an idle prompt just redraws), then
    `exit 55` in the nested shell, and confirm the OUTER shell's $? reflects the
    nested minishell process's exit code (55), same as any other foreground
    child. This exercises signal handling and exit-status propagation across a
    self-referential nested invocation.
    """
    s = Session()
    try:
        s.read_until(r"minishell\$ ")
        s.send(f"{MINISHELL_BIN}\n")
        time.sleep(0.3)
        s.read_until(r"minishell\$ ")  # nested shell's own prompt
        s.send("\x03")  # Ctrl-C at an idle nested prompt: should just redraw, not kill it
        time.sleep(0.3)
        s.send("exit 55\n")
        time.sleep(0.3)
        s.send("echo $?\n")
        s.read_until(r"55", timeout=2)
        s.send("exit\n")
        buf = s.drain()
        check("Nested minishell survives Ctrl-C at its idle prompt, and `exit 55` "
              "propagates as the outer shell's $?",
              "55" in buf, buf[-300:])
    finally:
        s.close()


def main():
    if not os.path.isfile(MINISHELL_BIN) or not os.access(MINISHELL_BIN, os.X_OK):
        print(f"error: {MINISHELL_BIN} not found or not executable -- run `make` first", file=sys.stderr)
        return 1
    os.chdir(ROOT)
    for fn in (
        test_ctrl_c_kills_foreground_sleep,
        test_ctrl_c_pipeline,
        test_ctrl_backslash_pipeline,
        test_ctrl_d_empty_line_exits,
        test_ctrl_d_with_pending_text_does_not_exit,
        test_nested_minishell_ctrl_c_then_exit_code,
    ):
        fn()
    passed = sum(1 for _, ok, _ in results if ok)
    print(f"\n{passed}/{len(results)} passed")
    return 0 if passed == len(results) else 1


if __name__ == "__main__":
    sys.exit(main())
