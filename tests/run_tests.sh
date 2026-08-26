#!/usr/bin/env bash
# Compares ./minishell against a real bash, case by case (output + exit code +
# leaks by default), over the case bank imported from a.txt into tests/cases/*.tsv.
#
# Usage:
#   tests/run_tests.sh                    # everything, with valgrind (slow)
#   tests/run_tests.sh --no-leaks         # fast: output/exit-code diff only
#   tests/run_tests.sh -c echo            # only tests/cases/02_echo.tsv
#   tests/run_tests.sh -c echo -v         # + show the actual diff on failures
#   tests/run_tests.sh --list -c heredoc  # just list matching cases, run nothing
#
# Rerun tests/lib/import_from_a_txt.py after replacing/extending a.txt to
# regenerate tests/cases/*.tsv. See tests/README-ish notes at the top of
# tests/lib/driver.py for what is and isn't compared and why.

set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

if ! command -v python3 >/dev/null 2>&1; then
    echo "python3 is required to run the test driver" >&2
    exit 1
fi

if [ ! -x ./minishell ]; then
    echo "./minishell not found or not built -- run 'make' first" >&2
    exit 1
fi

exec python3 tests/lib/driver.py "$@"
