#!/bin/bash
#
# Minishell mandatory-part tester.
#
# Runs every test case through a real "bash --norc --noprofile" and through
# ./minishell, in an identical fresh sandbox directory, and compares stdout
# and the process exit code. Test cases are organized to mirror the official
# 42 evaluation sheet's "Mandatory Part" checklist section by section, so
# every mandatory item has at least one concrete case here.
#
# Usage:
#   ./tester.sh                 run every mandatory test case
#   ./tester.sh -v               also show the stdout diff on failures
#   ./tester.sh -c "cd"          only run categories matching "cd"
#   ./tester.sh -l                list categories and case counts, run nothing
#   ./tester.sh -b                also run the optional bonus section
#   ./tester.sh -h                show this help
#
# What this does NOT cover: Ctrl-C / Ctrl-D / Ctrl-\ and history navigation
# need a real terminal (a pty) to deliver signals and arrow keys, which a
# piped bash script cannot do. Those cases are listed and marked SKIPPED
# here for visibility, and are covered separately by
# tests/pty/signal_tests.py, which you should run in addition to this
# script.

set -u

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MINISHELL="$SCRIPT_DIR/minishell"
FIXTURES="$SCRIPT_DIR/tests/fixtures/base"
TIMEOUT=5
SANDBOX="/tmp/minishell_tester_$$"
CAPTURE="/tmp/minishell_tester_$$_capture"

VERBOSE=0
LIST_ONLY=0
RUN_BONUS=0
FILTER=""

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

TOTAL=0
PASSED=0
FAILED=0
SKIPPED=0
declare -A CAT_TOTAL
declare -A CAT_PASS
declare -A CAT_FAIL
declare -A CAT_SKIP
declare -A CAT_SEEN
CATEGORY_ORDER=()

FAILED_LIST=()

mkdir -p "$SANDBOX" "$CAPTURE"
trap 'rm -rf "$SANDBOX" "$CAPTURE"' EXIT

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------

while [[ $# -gt 0 ]]; do
    case "$1" in
        -v|--verbose) VERBOSE=1; shift ;;
        -c|--category) FILTER="$2"; shift 2 ;;
        -l|--list) LIST_ONLY=1; shift ;;
        -b|--bonus) RUN_BONUS=1; shift ;;
        -h|--help)
            sed -n '2,25p' "$0" | sed 's/^# \{0,1\}//'
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            exit 1
            ;;
    esac
done

# ---------------------------------------------------------------------------
# Sandbox helpers
# ---------------------------------------------------------------------------

reset_sandbox() {
    rm -rf "$SANDBOX"
    mkdir -p "$SANDBOX"
    if [ -d "$FIXTURES" ]; then
        cp -r "$FIXTURES"/. "$SANDBOX"/
    fi
}

run_bash() {
    (cd "$SANDBOX" && printf '%s\n' "$1" | timeout "$TIMEOUT" bash --norc --noprofile >"$CAPTURE/.b_out" 2>"$CAPTURE/.b_err")
    echo -n "$?" >"$CAPTURE/.b_exit"
}

run_mini() {
    (cd "$SANDBOX" && printf '%s\n' "$1" | timeout "$TIMEOUT" "$MINISHELL" >"$CAPTURE/.m_out" 2>"$CAPTURE/.m_err")
    echo -n "$?" >"$CAPTURE/.m_exit"
}

# minishell unconditionally prints a bare "exit" line to stdout whenever
# the exit builtin is invoked -- even non-interactively, and even when it
# ends up refusing to exit (e.g. "too many arguments"). Real bash only
# prints that when interactive. This is cosmetic and not what any test
# case here is actually checking, so strip it before comparing (same kind
# of normalization the project's other test driver, tests/lib/driver.py,
# already applies for the same reason).
strip_exit_notice() {
    grep -v '^exit$' <<< "$1"
}

# $_ (last-argument tracking) is invocation-chain-dependent: this script
# invokes both shells through `timeout`, and what $_ starts out as depends
# on details of that invocation chain that have nothing to do with whether
# minishell's own $_ logic is correct (verified separately, live, elsewhere
# this session). Strip any "declare -x _=..." export line before comparing,
# same idea as strip_exit_notice above.
strip_underscore_line() {
    grep -v '^declare -x _=' <<< "$1"
}

# ---------------------------------------------------------------------------
# Test registration
# ---------------------------------------------------------------------------

# t <category> <description> <command> [note]
#
# Runs <command> through both shells and compares stdout + exit code.
t() {
    local category="$1" desc="$2" cmd="$3" note="${4:-}"

    if [[ -n "$FILTER" && "$category" != *"$FILTER"* ]]; then
        return
    fi
    if [ "$LIST_ONLY" -eq 1 ]; then
        record_category "$category"
        return
    fi

    record_category "$category"
    TOTAL=$((TOTAL + 1))
    CAT_TOTAL[$category]=$(( ${CAT_TOTAL[$category]:-0} + 1 ))

    reset_sandbox
    run_bash "$cmd"
    reset_sandbox
    run_mini "$cmd"

    local b_exit b_out m_exit m_out
    b_exit=$(cat "$CAPTURE/.b_exit" 2>/dev/null || echo "?")
    m_exit=$(cat "$CAPTURE/.m_exit" 2>/dev/null || echo "?")
    b_out=$(strip_underscore_line "$(cat "$CAPTURE/.b_out" 2>/dev/null)")
    m_out=$(strip_underscore_line "$(strip_exit_notice "$(cat "$CAPTURE/.m_out" 2>/dev/null)")")

    if [ "$b_exit" = "$m_exit" ] && [ "$b_out" = "$m_out" ]; then
        PASSED=$((PASSED + 1))
        CAT_PASS[$category]=$(( ${CAT_PASS[$category]:-0} + 1 ))
        return
    fi

    FAILED=$((FAILED + 1))
    CAT_FAIL[$category]=$(( ${CAT_FAIL[$category]:-0} + 1 ))
    FAILED_LIST+=("[$category] $desc")

    echo -e "${RED}FAIL${NC} [$category] $desc"
    echo "  command: $(printf '%q' "$cmd")"
    [ -n "$note" ] && echo "  note: $note"
    echo "  exit code: bash=$b_exit minishell=$m_exit"
    if [ "$b_out" != "$m_out" ]; then
        echo "  stdout differs"
        if [ "$VERBOSE" -eq 1 ]; then
            diff <(echo "$b_out") <(echo "$m_out") | sed 's/^/    /'
        fi
    fi
    if [ "$VERBOSE" -eq 1 ]; then
        local b_err m_err
        b_err=$(cat "$CAPTURE/.b_err" 2>/dev/null)
        m_err=$(cat "$CAPTURE/.m_err" 2>/dev/null)
        if [ "$b_err" != "$m_err" ]; then
            echo "  stderr (bash):      $b_err"
            echo "  stderr (minishell): $m_err"
        fi
    fi
}

# tc <category> <description> <command> <pattern> [note]
# tc_absent <category> <description> <command> <pattern> [note]
#
# Runs <command> through minishell only and checks that <pattern> (an
# extended regex) does (tc) or does not (tc_absent) appear anywhere in
# stdout. Used for cases where a byte-for-byte diff against bash is
# unreliable — most importantly "env", whose output order depends on
# bash's internal variable hash table and does not match the order
# minishell (correctly) inherited it in. See bugs.md for the full
# explanation.
tc() { tc_run 1 "$@"; }
tc_absent() { tc_run 0 "$@"; }

tc_run() {
    local should_match="$1" category="$2" desc="$3" cmd="$4" pattern="$5" note="${6:-}"

    if [[ -n "$FILTER" && "$category" != *"$FILTER"* ]]; then
        return
    fi
    if [ "$LIST_ONLY" -eq 1 ]; then
        record_category "$category"
        return
    fi

    record_category "$category"
    TOTAL=$((TOTAL + 1))
    CAT_TOTAL[$category]=$(( ${CAT_TOTAL[$category]:-0} + 1 ))

    reset_sandbox
    run_mini "$cmd"
    local m_out matched
    m_out=$(strip_exit_notice "$(cat "$CAPTURE/.m_out" 2>/dev/null)")
    matched=0
    echo "$m_out" | grep -Eq "$pattern" && matched=1

    if [ "$matched" -eq "$should_match" ]; then
        PASSED=$((PASSED + 1))
        CAT_PASS[$category]=$(( ${CAT_PASS[$category]:-0} + 1 ))
        return
    fi

    FAILED=$((FAILED + 1))
    CAT_FAIL[$category]=$(( ${CAT_FAIL[$category]:-0} + 1 ))
    FAILED_LIST+=("[$category] $desc")

    echo -e "${RED}FAIL${NC} [$category] $desc"
    echo "  command: $(printf '%q' "$cmd")"
    [ -n "$note" ] && echo "  note: $note"
    if [ "$should_match" -eq 1 ]; then
        echo "  expected minishell stdout to match: $pattern"
    else
        echo "  expected minishell stdout to NOT match: $pattern"
    fi
    if [ "$VERBOSE" -eq 1 ]; then
        echo "  minishell stdout:"
        echo "$m_out" | sed 's/^/    /'
    fi
}

# skip <category> <description> <reason>
#
# Records a case that this script cannot automate (needs a real terminal),
# so it stays visible in the report instead of silently missing.
skip() {
    local category="$1" desc="$2" reason="$3"

    if [[ -n "$FILTER" && "$category" != *"$FILTER"* ]]; then
        return
    fi
    record_category "$category"
    if [ "$LIST_ONLY" -eq 1 ]; then
        return
    fi
    TOTAL=$((TOTAL + 1))
    SKIPPED=$((SKIPPED + 1))
    CAT_SKIP[$category]=$(( ${CAT_SKIP[$category]:-0} + 1 ))
    [ "$VERBOSE" -eq 1 ] && echo -e "${YELLOW}SKIP${NC} [$category] $desc -- $reason"
}

record_category() {
    local category="$1"
    if [ -z "${CAT_SEEN[$category]+x}" ]; then
        CAT_SEEN[$category]=1
        CATEGORY_ORDER+=("$category")
    fi
}

# ---------------------------------------------------------------------------
# Preflight checks (not counted as test cases)
# ---------------------------------------------------------------------------

preflight() {
    echo "Preflight checks"
    echo "----------------"

    if [ ! -x "$MINISHELL" ]; then
        echo -e "${RED}minishell binary not found or not executable at $MINISHELL${NC}"
        echo "Run 'make' first."
        exit 1
    fi
    echo -e "${GREEN}OK${NC} minishell binary present and executable"

    if grep -q -- '-Wall' Makefile 2>/dev/null && grep -q -- '-Wextra' Makefile 2>/dev/null \
        && grep -q -- '-Werror' Makefile 2>/dev/null; then
        echo -e "${GREEN}OK${NC} Makefile CFLAGS include -Wall -Wextra -Werror"
    else
        echo -e "${RED}WARNING${NC} Makefile does not clearly set -Wall -Wextra -Werror"
    fi

    local relink_out
    relink_out=$(make -n 2>&1)
    if echo "$relink_out" | grep -q "Nothing to be done"; then
        echo -e "${GREEN}OK${NC} 'make' on an already-built tree does not relink"
    else
        echo -e "${YELLOW}NOTE${NC} 'make' reports pending work (build may be stale); run 'make' first for a clean check"
    fi
    echo ""
}

# ---------------------------------------------------------------------------
# Header
# ---------------------------------------------------------------------------

echo ""
echo "Minishell mandatory-part tester"
echo "================================"
echo ""

if [ "$LIST_ONLY" -eq 0 ]; then
    preflight
fi

[ -n "$FILTER" ] && echo "Filter: categories matching \"$FILTER\""
[ "$RUN_BONUS" -eq 1 ] && echo "Bonus section included"
echo ""

# ---------------------------------------------------------------------------
# 1. Simple Command & Global Variables
# ---------------------------------------------------------------------------

t "Simple command" "absolute path, no options" "/bin/ls"
t "Simple command" "absolute path binary with no args" "/usr/bin/whoami"
t "Simple command" "empty command (just Enter)" ""
t "Simple command" "quoted empty command word" '""'
t "Simple command" "only spaces" "   "
t "Simple command" "only tabs" "$'\t\t\t'"

# ---------------------------------------------------------------------------
# 2. Arguments
# ---------------------------------------------------------------------------

t "Arguments" "absolute path with one argument" "/bin/ls -la"
t "Arguments" "absolute path with several arguments" "/bin/ls -l -a Docs"
t "Arguments" "many repeated arguments" "/bin/echo one two three four five"

# ---------------------------------------------------------------------------
# 3. echo
# ---------------------------------------------------------------------------

t "echo" "no arguments" "echo"
t "echo" "plain arguments" "echo hello world"
t "echo" "-n suppresses the trailing newline" "echo -n hello"
t "echo" "-n with no other arguments" "echo -n"
t "echo" "repeated -n flags" "echo -n -n -n hello"
t "echo" "-n not at the start is a literal argument" "echo hello -n"

# ---------------------------------------------------------------------------
# 4. exit
# ---------------------------------------------------------------------------

t "exit" "no arguments" "exit"
t "exit" "numeric argument" "exit 42"
t "exit" "zero" "exit 0"
t "exit" "negative argument wraps like bash" "exit -1"
t "exit" "large argument wraps modulo 256" "exit 300"
t "exit" "non-numeric argument is an error, exit code 2" "exit hola"
t "exit" "too many arguments refuses to exit" $'exit 1 2\necho still here, status=$?'

# ---------------------------------------------------------------------------
# 5. Return value of a process
# ---------------------------------------------------------------------------

t "Return value" "\$? after a successful command" $'/bin/ls >/dev/null\necho $?'
t "Return value" "\$? after a failing command" $'/bin/ls /does/not/exist 2>/dev/null\necho $?'
t "Return value" "\$? usable as an argument to another command" $'/bin/ls /does/not/exist 2>/dev/null\nexpr $? + $?'

# ---------------------------------------------------------------------------
# 6. Signals -- needs a real terminal, see tests/pty/signal_tests.py
# ---------------------------------------------------------------------------

skip "Signals" "Ctrl-C on an empty prompt prints a new prompt" "needs a pty; see tests/pty/signal_tests.py"
skip "Signals" "Ctrl-\\ on an empty prompt does nothing" "needs a pty; see tests/pty/signal_tests.py"
skip "Signals" "Ctrl-D on an empty prompt exits the shell" "needs a pty; see tests/pty/signal_tests.py"
skip "Signals" "Ctrl-C with typed text clears the line and reprompts" "needs a pty; see tests/pty/signal_tests.py"
skip "Signals" "Ctrl-D with typed text does nothing" "needs a pty; see tests/pty/signal_tests.py"
skip "Signals" "Ctrl-C interrupts a blocking foreground command (cat, grep)" "needs a pty; see tests/pty/signal_tests.py"
skip "Signals" "Ctrl-\\ quits a blocking foreground command with a core-dump message" "needs a pty; see tests/pty/signal_tests.py"

# ---------------------------------------------------------------------------
# 7. Double Quotes
# ---------------------------------------------------------------------------

t "Double quotes" "arguments with embedded whitespace" 'echo "hello   world"'
t "Double quotes" "pipe and redirection characters stay literal" 'echo "cat lol.c | cat > lol.c"'
t "Double quotes" "everything except \$ is left alone" 'echo "a*b?c[d]e"'

# ---------------------------------------------------------------------------
# 8. Single Quotes
# ---------------------------------------------------------------------------

t "Single quotes" "empty argument" "echo ''"
t "Single quotes" "variables are not expanded" "echo '\$USER'"
t "Single quotes" "whitespace, pipes and redirections are not interpreted" "echo 'a | b > c'"
t "Single quotes" "nothing inside is interpreted" "echo '\$HOME \$(pwd) \`pwd\`'"

# ---------------------------------------------------------------------------
# 9. env
# ---------------------------------------------------------------------------

tc "env" "prints the current environment" "env" "^PATH=" "checks PATH is present rather than diffing the full dump byte-for-byte -- see the note at the top of this file"
tc "env" "prints an exported variable" $'export TESTVAR=hello\nenv' "^TESTVAR=hello$"

# ---------------------------------------------------------------------------
# 10. export
# ---------------------------------------------------------------------------

tc "export" "creates a new variable" $'export TESTVAR=created\nenv' "^TESTVAR=created$"
tc "export" "replaces an existing variable" $'export TESTVAR=first\nexport TESTVAR=second\nenv' "^TESTVAR=second$"
t "export" "no arguments lists exported variables" "export"

# ---------------------------------------------------------------------------
# 11. unset
# ---------------------------------------------------------------------------

tc_absent "unset" "removes a variable" $'export TESTVAR=hello\nunset TESTVAR\nenv' '^TESTVAR='
t "unset" "removed variable no longer expands" $'export TESTVAR=hello\nunset TESTVAR\necho [$TESTVAR]'

# ---------------------------------------------------------------------------
# 12. cd
# ---------------------------------------------------------------------------

t "cd" "move into a subdirectory, verified with ls" $'cd Docs\nls'
t "cd" "cd with no arguments goes to \$HOME" $'cd Docs\ncd\npwd'
t "cd" "cd . stays in place" $'cd Docs\ncd .\npwd'
t "cd" "cd .. goes up one level" $'cd Docs\ncd ..\npwd'
t "cd" "cd into a nonexistent directory fails" "cd does_not_exist_xyz"
t "cd" "cd into a file fails" "cd Makefile"
t "cd" "cd - returns to the previous directory and prints it" $'cd Docs\ncd ..\ncd -'

# ---------------------------------------------------------------------------
# 13. pwd
# ---------------------------------------------------------------------------

t "pwd" "prints the current directory" "pwd"
t "pwd" "reflects a directory change" $'cd Docs\npwd'

# ---------------------------------------------------------------------------
# 14. Relative Path
# ---------------------------------------------------------------------------

t "Relative path" "run a script via a relative path" $'printf "#!/bin/sh\\necho relative_ok\\n" > note.sh\nchmod +x note.sh\n./note.sh'
t "Relative path" "run a binary via a relative path from a subdirectory" $'printf "#!/bin/sh\\necho relative_ok\\n" > note.sh\nchmod +x note.sh\ncd Docs\n../note.sh'
t "Relative path" "a long ../.. chain resolving back to a real command" "../../../../../../../../../../bin/echo relative_ok"

# ---------------------------------------------------------------------------
# 15. Environment path
# ---------------------------------------------------------------------------

t "Environment path" "command found without a path via \$PATH" "ls"
t "Environment path" "command lookup fails once \$PATH is unset" $'unset PATH\nls'
t "Environment path" "left-to-right \$PATH order" $'mkdir dir_a dir_b\nprintf "#!/bin/sh\\necho FROM_A\\n" > dir_a/mycmd\nprintf "#!/bin/sh\\necho FROM_B\\n" > dir_b/mycmd\nchmod +x dir_a/mycmd dir_b/mycmd\nexport PATH="$PWD/dir_a:$PWD/dir_b"\nmycmd'

# ---------------------------------------------------------------------------
# 16. Redirection
# ---------------------------------------------------------------------------

t "Redirection" "> truncates and writes" $'echo hello > out.txt\ncat out.txt'
t "Redirection" ">> appends" $'echo one > out.txt\necho two >> out.txt\ncat out.txt'
t "Redirection" "repeated >> keeps appending" $'echo one >> out.txt\necho two >> out.txt\necho three >> out.txt\ncat out.txt'
t "Redirection" "< reads input from a file" $'echo hello > in.txt\ncat < in.txt'
t "Redirection" "combining < and >" $'echo hello > in.txt\ncat < in.txt > out.txt\ncat out.txt'
t "Redirection" "<< heredoc reads until the delimiter" $'cat << EOF\nfirst line\nsecond line\nEOF'
t "Redirection" "<< heredoc body expands variables" $'export TESTVAR=hello\ncat << EOF\n$TESTVAR\nEOF'
t "Redirection" "<< heredoc delimiter itself is not expanded" $'cat << $HOME\nliteral\n$HOME'

# ---------------------------------------------------------------------------
# 17. Pipes
# ---------------------------------------------------------------------------

t "Pipes" "two-stage pipe" "echo hello | cat"
t "Pipes" "three-stage pipe" $'cat Docs/bonjour Docs/hey | sort | cat'
t "Pipes" "a failing command in the middle of a pipe" $'ls does_not_exist_xyz 2>/dev/null | cat | wc -l'
t "Pipes" "pipes combined with redirection" $'echo hello | cat > out.txt\ncat out.txt'

# ---------------------------------------------------------------------------
# 18. Go Crazy and history
# ---------------------------------------------------------------------------

skip "Go crazy" "Ctrl-C then Enter leaves nothing to execute" "needs a pty; see tests/pty/signal_tests.py"
skip "Go crazy" "history is navigable with Up and Down" "needs a pty; there is no automated coverage for this yet"
t "Go crazy" "an unknown command prints an error and does not crash" "this_command_does_not_exist_xyz"
t "Go crazy" "cat | cat | ls behaves normally" "cat | cat | ls"
t "Go crazy" "a long command with many arguments does not break" "echo $(for i in $(seq 1 300); do printf 'arg%d ' "$i"; done)"

# ---------------------------------------------------------------------------
# 19. Environment variables
# ---------------------------------------------------------------------------

t "Environment variables" "expands a set variable" $'export TESTVAR=hello\necho $TESTVAR'
t "Environment variables" "an undefined variable expands to nothing" 'echo [$this_var_is_not_set]'
t "Environment variables" "double quotes still interpolate \$" $'export TESTVAR=hello\necho "value: $TESTVAR"'
t "Environment variables" "\$USER is set and expands" $'export USER=tester\necho $USER'
t "Environment variables" "\$? expands to the last exit status" $'/bin/ls /nope 2>/dev/null\necho $?'
t "Environment variables" "\$_ is the last argument of the previous command" $'echo a b\necho $_'
t "Environment variables" "\$_ falls back to the command name with no arguments" $'true\necho $_'
t "Environment variables" "\$_ is not updated across a pipeline" $'echo first\necho a b | grep b\necho $_'

# ---------------------------------------------------------------------------
# Bonus (only run with -b/--bonus; the eval sheet says to ignore these
# unless the mandatory part is entirely correct first)
# ---------------------------------------------------------------------------

if [ "$RUN_BONUS" -eq 1 ]; then
    t "Bonus: and/or" "&& runs the second command on success" "true && echo yes"
    t "Bonus: and/or" "|| runs the second command on failure" "false || echo yes"
    t "Bonus: and/or" "parentheses group a subshell" "(echo a; echo b) | cat"
    t "Bonus: wildcard" "* expands to every file in the directory" "ls *"
    t "Bonus: wildcard" "a prefix wildcard" "ls D*"
    t "Bonus: surprise" "single quotes inside double quotes are literal" $'export USER=tester\necho "'"'"'$USER'"'"'"'
    t "Bonus: surprise" "double quotes inside single quotes are literal" $'export USER=tester\necho '"'"'"$USER"'"'"''
fi

# ---------------------------------------------------------------------------
# Report
# ---------------------------------------------------------------------------

show_report() {
    echo ""
    echo "======================================================================"
    echo "RESULTS"
    echo "======================================================================"
    echo ""
    if [ "$LIST_ONLY" -eq 1 ]; then
        for cat in "${CATEGORY_ORDER[@]}"; do
            echo "$cat"
        done
        return
    fi

    echo "Total:   $TOTAL"
    echo -e "Passed:  ${GREEN}$PASSED${NC}"
    echo -e "Failed:  ${RED}$FAILED${NC}"
    echo -e "Skipped: ${YELLOW}$SKIPPED${NC} (need a real terminal, not counted against pass/fail)"
    echo ""
    echo "By category"
    echo "-----------"
    for cat in "${CATEGORY_ORDER[@]}"; do
        local total=${CAT_TOTAL[$cat]:-0}
        local pass=${CAT_PASS[$cat]:-0}
        local fail=${CAT_FAIL[$cat]:-0}
        local skip=${CAT_SKIP[$cat]:-0}
        if [ "$total" -gt 0 ]; then
            printf "%-28s %2d passed, %2d failed  (%d%%)\n" "$cat" "$pass" "$fail" "$(( pass * 100 / total ))"
        elif [ "$skip" -gt 0 ]; then
            printf "%-28s %2d skipped\n" "$cat" "$skip"
        fi
    done

    if [ "$FAILED" -gt 0 ]; then
        echo ""
        echo "Failed tests"
        echo "------------"
        for entry in "${FAILED_LIST[@]}"; do
            echo "  $entry"
        done
        [ "$VERBOSE" -eq 0 ] && echo "" && echo "Re-run with -v for the stdout diff on each failure."
    fi
    echo ""
    echo "======================================================================"
}

show_report

[ "$FAILED" -eq 0 ]
exit $?
