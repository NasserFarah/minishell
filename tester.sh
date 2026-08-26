#!/bin/bash

# ============================================================================
# MINISHELL COMPREHENSIVE TESTER
# Auto-generated from: Minishell Map - GitHub _ @vietdu91 @QnYosa.xlsx
# Total test cases: 744
# ============================================================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Configuration
MINISHELL="./minishell"
TIMEOUT=5
TEST_DIR="/tmp/minishell_test_$$"
VERBOSE=0
SHOW_PASSED=0
FILTER_CATEGORY=""

# Statistics
TOTAL=0
PASSED=0
FAILED=0
SKIPPED=0

declare -A CAT_TOTAL
declare -A CAT_PASS
declare -A CAT_FAIL

# Setup
mkdir -p "$TEST_DIR"
trap 'rm -rf "$TEST_DIR"' EXIT

# Functions
run_bash() {
    cd "$TEST_DIR" >/dev/null 2>&1
    echo -e "$1" | timeout $TIMEOUT bash --norc --noprofile >"$TEST_DIR/b_out" 2>&1
    echo $? > "$TEST_DIR/b_exit"
    cd - >/dev/null 2>&1
}

run_mini() {
    cd "$TEST_DIR" >/dev/null 2>&1
    echo -e "$1\nexit" | timeout $TIMEOUT "$MINISHELL" >"$TEST_DIR/m_out" 2>&1
    echo $? > "$TEST_DIR/m_exit"
    cd - >/dev/null 2>&1
}

test_cmd() {
    local cat="$1"
    local cmd="$2"
    local exp="$3"
    local note="$4"
    
    TOTAL=$((TOTAL + 1))
    CAT_TOTAL[$cat]=$((${CAT_TOTAL[$cat]:-0} + 1))
    
    # Skip interactive tests
    if [[ "$cmd" =~ (Ctrl|\\n|touche|Enter|\[que) ]]; then
        SKIPPED=$((SKIPPED + 1))
        [ $VERBOSE -eq 1 ] && echo -e "${YELLOW}⊘${NC} [$TOTAL] Skip: ${cmd:0:50}"
        return
    fi
    
    rm -rf "$TEST_DIR"/*
    run_bash "$cmd"
    run_mini "$cmd"
    
    local b_exit=$(cat "$TEST_DIR/b_exit" 2>/dev/null || echo "999")
    local m_exit=$(cat "$TEST_DIR/m_exit" 2>/dev/null || echo "999")
    
    if [ "$b_exit" = "$m_exit" ]; then
        PASSED=$((PASSED + 1))
        CAT_PASS[$cat]=$((${CAT_PASS[$cat]:-0} + 1))
        [ $SHOW_PASSED -eq 1 ] && echo -e "${GREEN}✓${NC} [$TOTAL] ${cmd:0:60}"
    else
        FAILED=$((FAILED + 1))
        CAT_FAIL[$cat]=$((${CAT_FAIL[$cat]:-0} + 1))
        echo -e "${RED}✗${NC} [$TOTAL] [${cat:0:20}] ${cmd:0:45}"
        echo -e "   Expected: $exp | Bash: $b_exit | Mini: $m_exit"
        [ -n "$note" ] && echo -e "   ${BLUE}Note: ${note:0:70}${NC}"
        
        if [ $VERBOSE -eq 1 ]; then
            echo -e "   ${CYAN}Bash:${NC}"
            head -2 "$TEST_DIR/b_out" 2>/dev/null | sed 's/^/     /'
            echo -e "   ${CYAN}Mini:${NC}"
            head -2 "$TEST_DIR/m_out" 2>/dev/null | sed 's/^/     /'
        fi
    fi
}

show_stats() {
    echo ""
    echo -e "${PURPLE}${BOLD}═══════════════════════════════════════════════${NC}"
    echo -e "${PURPLE}${BOLD}              TEST RESULTS                      ${NC}"
    echo -e "${PURPLE}${BOLD}═══════════════════════════════════════════════${NC}"
    echo ""
    echo -e "Total:    ${BOLD}$TOTAL${NC} tests"
    echo -e "Passed:   ${GREEN}${BOLD}$PASSED${NC} ($([ $TOTAL -gt 0 ] && echo $(($PASSED * 100 / $TOTAL)) || echo 0)%)"
    echo -e "Failed:   ${RED}${BOLD}$FAILED${NC} ($([ $TOTAL -gt 0 ] && echo $(($FAILED * 100 / $TOTAL)) || echo 0)%)"
    echo -e "Skipped:  ${YELLOW}$SKIPPED${NC}"
    echo ""
    echo -e "${PURPLE}${BOLD}═══════════════════════════════════════════════${NC}"
    echo -e "${PURPLE}${BOLD}           CATEGORY BREAKDOWN                   ${NC}"
    echo -e "${PURPLE}${BOLD}═══════════════════════════════════════════════${NC}"
    echo ""
    
    for cat in "${!CAT_TOTAL[@]}"; do
        local t=${CAT_TOTAL[$cat]}
        local p=${CAT_PASS[$cat]:-0}
        local f=${CAT_FAIL[$cat]:-0}
        local pct=$([ $t -gt 0 ] && echo $(($p * 100 / $t)) || echo 0)
        printf "%-30s %3d | ${GREEN}✓%3d${NC} ${RED}✗%3d${NC} | %3d%%\n" "${cat:0:30}" "$t" "$p" "$f" "$pct"
    done | sort -t'|' -k3 -n
    
    echo ""
    echo -e "${PURPLE}${BOLD}═══════════════════════════════════════════════${NC}"
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -v|--verbose) VERBOSE=1; shift ;;
        -p|--show-passed) SHOW_PASSED=1; shift ;;
        -c|--category) FILTER_CATEGORY="$2"; shift 2 ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo "Options:"
            echo "  -v  --verbose       Detailed output"
            echo "  -p  --show-passed   Show passed tests"
            echo "  -c  --category CAT  Filter by category"
            echo "  -h  --help          Show help"
            exit 0 ;;
        *) echo "Unknown: $1"; exit 1 ;;
    esac
done

# Header
echo -e "${PURPLE}${BOLD}"
echo "╔═══════════════════════════════════════════════╗"
echo "║       MINISHELL COMPREHENSIVE TESTER          ║"
echo "║           Generated from Excel                ║"
echo "╚═══════════════════════════════════════════════╝"
echo -e "${NC}"

[ ! -f "$MINISHELL" ] && echo -e "${RED}Error: $MINISHELL not found${NC}" && exit 1
[ -n "$FILTER_CATEGORY" ] && echo -e "${CYAN}Filter: $FILTER_CATEGORY${NC}"
echo -e "${CYAN}Running 744 tests...${NC}"
echo ""

# ============================================================================
# TEST CASES
# ============================================================================


# Test 1: CARACTERES A LA VOLEE (SYNTAXE)  🌦
[[ -z "$FILTER_CATEGORY" || "CARACTERES A LA VOLEE (SYNTAXE)  🌦" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'CARACTERES A LA VOLEE (SYNTAXE)  🌦' '\n (touche entrée)' '0' ''

# Test 2: CARACTERES A LA VOLEE (SYNTAXE)  🌦
[[ -z "$FILTER_CATEGORY" || "CARACTERES A LA VOLEE (SYNTAXE)  🌦" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'CARACTERES A LA VOLEE (SYNTAXE)  🌦' '[que des espaces]' '0' ''

# Test 3: CARACTERES A LA VOLEE (SYNTAXE)  🌦
[[ -z "$FILTER_CATEGORY" || "CARACTERES A LA VOLEE (SYNTAXE)  🌦" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'CARACTERES A LA VOLEE (SYNTAXE)  🌦' '[que des tabulations]' '0' 'Crl + V + Tab'

# Test 4: CARACTERES A LA VOLEE (SYNTAXE)  🌦
[[ -z "$FILTER_CATEGORY" || "CARACTERES A LA VOLEE (SYNTAXE)  🌦" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'CARACTERES A LA VOLEE (SYNTAXE)  🌦' ':' '0' 'Marche aussi pour \"#\"'

# Test 5: CARACTERES A LA VOLEE (SYNTAXE)  🌦
[[ -z "$FILTER_CATEGORY" || "CARACTERES A LA VOLEE (SYNTAXE)  🌦" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'CARACTERES A LA VOLEE (SYNTAXE)  🌦' '!' '1' ''

# Test 6: CARACTERES A LA VOLEE (SYNTAXE)  🌦
[[ -z "$FILTER_CATEGORY" || "CARACTERES A LA VOLEE (SYNTAXE)  🌦" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'CARACTERES A LA VOLEE (SYNTAXE)  🌦' '>' '2' ''

# Test 7: CARACTERES A LA VOLEE (SYNTAXE)  🌦
[[ -z "$FILTER_CATEGORY" || "CARACTERES A LA VOLEE (SYNTAXE)  🌦" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'CARACTERES A LA VOLEE (SYNTAXE)  🌦' '<' '2' ''

# Test 8: CARACTERES A LA VOLEE (SYNTAXE)  🌦
[[ -z "$FILTER_CATEGORY" || "CARACTERES A LA VOLEE (SYNTAXE)  🌦" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'CARACTERES A LA VOLEE (SYNTAXE)  🌦' '>>' '2' ''

# Test 9: CARACTERES A LA VOLEE (SYNTAXE)  🌦
[[ -z "$FILTER_CATEGORY" || "CARACTERES A LA VOLEE (SYNTAXE)  🌦" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'CARACTERES A LA VOLEE (SYNTAXE)  🌦' '<<' '2' ''

# Test 10: CARACTERES A LA VOLEE (SYNTAXE)  🌦
[[ -z "$FILTER_CATEGORY" || "CARACTERES A LA VOLEE (SYNTAXE)  🌦" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'CARACTERES A LA VOLEE (SYNTAXE)  🌦' '<>' '2' ''

# Test 11: CARACTERES A LA VOLEE (SYNTAXE)  🌦
[[ -z "$FILTER_CATEGORY" || "CARACTERES A LA VOLEE (SYNTAXE)  🌦" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'CARACTERES A LA VOLEE (SYNTAXE)  🌦' '>>>>>' '2' ''

# Test 12: CARACTERES A LA VOLEE (SYNTAXE)  🌦
[[ -z "$FILTER_CATEGORY" || "CARACTERES A LA VOLEE (SYNTAXE)  🌦" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'CARACTERES A LA VOLEE (SYNTAXE)  🌦' '>>>>>>>>>>>>>>>' '2' ''

# Test 13: CARACTERES A LA VOLEE (SYNTAXE)  🌦
[[ -z "$FILTER_CATEGORY" || "CARACTERES A LA VOLEE (SYNTAXE)  🌦" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'CARACTERES A LA VOLEE (SYNTAXE)  🌦' '<<<<<' '2' ''

# Test 14: CARACTERES A LA VOLEE (SYNTAXE)  🌦
[[ -z "$FILTER_CATEGORY" || "CARACTERES A LA VOLEE (SYNTAXE)  🌦" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'CARACTERES A LA VOLEE (SYNTAXE)  🌦' '<<<<<<<<<<<<<<<<' '2' ''

# Test 15: CARACTERES A LA VOLEE (SYNTAXE)  🌦
[[ -z "$FILTER_CATEGORY" || "CARACTERES A LA VOLEE (SYNTAXE)  🌦" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'CARACTERES A LA VOLEE (SYNTAXE)  🌦' '> > > >' '2' 'Marche aussi pour <'

# Test 16: CARACTERES A LA VOLEE (SYNTAXE)  🌦
[[ -z "$FILTER_CATEGORY" || "CARACTERES A LA VOLEE (SYNTAXE)  🌦" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'CARACTERES A LA VOLEE (SYNTAXE)  🌦' '>> >> >> >>' '2' 'Marche aussi pour <'

# Test 17: CARACTERES A LA VOLEE (SYNTAXE)  🌦
[[ -z "$FILTER_CATEGORY" || "CARACTERES A LA VOLEE (SYNTAXE)  🌦" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'CARACTERES A LA VOLEE (SYNTAXE)  🌦' '>>>> >> >> >>' '2' 'Marche aussi pour <'

# Test 18: CARACTERES A LA VOLEE (SYNTAXE)  🌦
[[ -z "$FILTER_CATEGORY" || "CARACTERES A LA VOLEE (SYNTAXE)  🌦" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'CARACTERES A LA VOLEE (SYNTAXE)  🌦' '/' '126' ''

# Test 19: CARACTERES A LA VOLEE (SYNTAXE)  🌦
[[ -z "$FILTER_CATEGORY" || "CARACTERES A LA VOLEE (SYNTAXE)  🌦" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'CARACTERES A LA VOLEE (SYNTAXE)  🌦' '//' '126' ''

# Test 20: CARACTERES A LA VOLEE (SYNTAXE)  🌦
[[ -z "$FILTER_CATEGORY" || "CARACTERES A LA VOLEE (SYNTAXE)  🌦" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'CARACTERES A LA VOLEE (SYNTAXE)  🌦' '/.' '126' ''

# Test 21: CARACTERES A LA VOLEE (SYNTAXE)  🌦
[[ -z "$FILTER_CATEGORY" || "CARACTERES A LA VOLEE (SYNTAXE)  🌦" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'CARACTERES A LA VOLEE (SYNTAXE)  🌦' '/./../../../../..' '126' ''

# Test 22: CARACTERES A LA VOLEE (SYNTAXE)  🌦
[[ -z "$FILTER_CATEGORY" || "CARACTERES A LA VOLEE (SYNTAXE)  🌦" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'CARACTERES A LA VOLEE (SYNTAXE)  🌦' '///////' '126' ''

# Test 23: CARACTERES A LA VOLEE (SYNTAXE)  🌦
[[ -z "$FILTER_CATEGORY" || "CARACTERES A LA VOLEE (SYNTAXE)  🌦" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'CARACTERES A LA VOLEE (SYNTAXE)  🌦' '\\' '127' ''

# Test 24: CARACTERES A LA VOLEE (SYNTAXE)  🌦
[[ -z "$FILTER_CATEGORY" || "CARACTERES A LA VOLEE (SYNTAXE)  🌦" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'CARACTERES A LA VOLEE (SYNTAXE)  🌦' '\\\\' '127' ''

# Test 25: CARACTERES A LA VOLEE (SYNTAXE)  🌦
[[ -z "$FILTER_CATEGORY" || "CARACTERES A LA VOLEE (SYNTAXE)  🌦" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'CARACTERES A LA VOLEE (SYNTAXE)  🌦' '\\\\\\\\' '127' ''

# Test 26: CARACTERES A LA VOLEE (SYNTAXE)  🌦
[[ -z "$FILTER_CATEGORY" || "CARACTERES A LA VOLEE (SYNTAXE)  🌦" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'CARACTERES A LA VOLEE (SYNTAXE)  🌦' '-' '127' 'Marche aussi pour \"_@°]=+£$?\"'

# Test 27: CARACTERES A LA VOLEE (SYNTAXE)  🌦
[[ -z "$FILTER_CATEGORY" || "CARACTERES A LA VOLEE (SYNTAXE)  🌦" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'CARACTERES A LA VOLEE (SYNTAXE)  🌦' '|' '2' 'Marche aussi pour les metacharacters \"&();\"'

# Test 28: CARACTERES A LA VOLEE (SYNTAXE)  🌦
[[ -z "$FILTER_CATEGORY" || "CARACTERES A LA VOLEE (SYNTAXE)  🌦" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'CARACTERES A LA VOLEE (SYNTAXE)  🌦' '| hola' '2' ''

# Test 29: CARACTERES A LA VOLEE (SYNTAXE)  🌦
[[ -z "$FILTER_CATEGORY" || "CARACTERES A LA VOLEE (SYNTAXE)  🌦" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'CARACTERES A LA VOLEE (SYNTAXE)  🌦' '| | |' '2' ''

# Test 30: CARACTERES A LA VOLEE (SYNTAXE)  🌦
[[ -z "$FILTER_CATEGORY" || "CARACTERES A LA VOLEE (SYNTAXE)  🌦" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'CARACTERES A LA VOLEE (SYNTAXE)  🌦' '||' '2' ''

# Test 31: CARACTERES A LA VOLEE (SYNTAXE)  🌦
[[ -z "$FILTER_CATEGORY" || "CARACTERES A LA VOLEE (SYNTAXE)  🌦" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'CARACTERES A LA VOLEE (SYNTAXE)  🌦' '|||||' '2' ''

# Test 32: CARACTERES A LA VOLEE (SYNTAXE)  🌦
[[ -z "$FILTER_CATEGORY" || "CARACTERES A LA VOLEE (SYNTAXE)  🌦" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'CARACTERES A LA VOLEE (SYNTAXE)  🌦' '|||||||||||||' '2' ''

# Test 33: CARACTERES A LA VOLEE (SYNTAXE)  🌦
[[ -z "$FILTER_CATEGORY" || "CARACTERES A LA VOLEE (SYNTAXE)  🌦" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'CARACTERES A LA VOLEE (SYNTAXE)  🌦' '>>|><' '2' ''

# Test 34: CARACTERES A LA VOLEE (SYNTAXE)  🌦
[[ -z "$FILTER_CATEGORY" || "CARACTERES A LA VOLEE (SYNTAXE)  🌦" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'CARACTERES A LA VOLEE (SYNTAXE)  🌦' '&&' '2' ''

# Test 35: CARACTERES A LA VOLEE (SYNTAXE)  🌦
[[ -z "$FILTER_CATEGORY" || "CARACTERES A LA VOLEE (SYNTAXE)  🌦" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'CARACTERES A LA VOLEE (SYNTAXE)  🌦' '&&&&&' '2' ''

# Test 36: CARACTERES A LA VOLEE (SYNTAXE)  🌦
[[ -z "$FILTER_CATEGORY" || "CARACTERES A LA VOLEE (SYNTAXE)  🌦" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'CARACTERES A LA VOLEE (SYNTAXE)  🌦' '&&&&&&&&&&&&&&' '2' ''

# Test 37: CARACTERES A LA VOLEE (SYNTAXE)  🌦
[[ -z "$FILTER_CATEGORY" || "CARACTERES A LA VOLEE (SYNTAXE)  🌦" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'CARACTERES A LA VOLEE (SYNTAXE)  🌦' ';;' '2' ''

# Test 38: CARACTERES A LA VOLEE (SYNTAXE)  🌦
[[ -z "$FILTER_CATEGORY" || "CARACTERES A LA VOLEE (SYNTAXE)  🌦" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'CARACTERES A LA VOLEE (SYNTAXE)  🌦' ';;;;;' '2' ''

# Test 39: CARACTERES A LA VOLEE (SYNTAXE)  🌦
[[ -z "$FILTER_CATEGORY" || "CARACTERES A LA VOLEE (SYNTAXE)  🌦" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'CARACTERES A LA VOLEE (SYNTAXE)  🌦' ';;;;;;;;;;;;;;;' '2' ''

# Test 40: CARACTERES A LA VOLEE (SYNTAXE)  🌦
[[ -z "$FILTER_CATEGORY" || "CARACTERES A LA VOLEE (SYNTAXE)  🌦" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'CARACTERES A LA VOLEE (SYNTAXE)  🌦' '()' '2' ''

# Test 41: CARACTERES A LA VOLEE (SYNTAXE)  🌦
[[ -z "$FILTER_CATEGORY" || "CARACTERES A LA VOLEE (SYNTAXE)  🌦" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'CARACTERES A LA VOLEE (SYNTAXE)  🌦' '( ( ) )' '2' ''

# Test 42: CARACTERES A LA VOLEE (SYNTAXE)  🌦
[[ -z "$FILTER_CATEGORY" || "CARACTERES A LA VOLEE (SYNTAXE)  🌦" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'CARACTERES A LA VOLEE (SYNTAXE)  🌦' '( ( ( ( ) ) ) )' '2' ''

# Test 43: CARACTERES A LA VOLEE (SYNTAXE)  🌦
[[ -z "$FILTER_CATEGORY" || "CARACTERES A LA VOLEE (SYNTAXE)  🌦" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'CARACTERES A LA VOLEE (SYNTAXE)  🌦' '\"\"' '127' ''

# Test 44: CARACTERES A LA VOLEE (SYNTAXE)  🌦
[[ -z "$FILTER_CATEGORY" || "CARACTERES A LA VOLEE (SYNTAXE)  🌦" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'CARACTERES A LA VOLEE (SYNTAXE)  🌦' '\"hola\"' '127' ''

# Test 45: CARACTERES A LA VOLEE (SYNTAXE)  🌦
[[ -z "$FILTER_CATEGORY" || "CARACTERES A LA VOLEE (SYNTAXE)  🌦" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'CARACTERES A LA VOLEE (SYNTAXE)  🌦' ''\''hola'\''' '127' ''

# Test 46: CARACTERES A LA VOLEE (SYNTAXE)  🌦
[[ -z "$FILTER_CATEGORY" || "CARACTERES A LA VOLEE (SYNTAXE)  🌦" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'CARACTERES A LA VOLEE (SYNTAXE)  🌦' ''\'''\''' '127' ''

# Test 47: CARACTERES A LA VOLEE (SYNTAXE)  🌦
[[ -z "$FILTER_CATEGORY" || "CARACTERES A LA VOLEE (SYNTAXE)  🌦" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'CARACTERES A LA VOLEE (SYNTAXE)  🌦' '*' '127' '[BONUS]'

# Test 48: CARACTERES A LA VOLEE (SYNTAXE)  🌦
[[ -z "$FILTER_CATEGORY" || "CARACTERES A LA VOLEE (SYNTAXE)  🌦" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'CARACTERES A LA VOLEE (SYNTAXE)  🌦' '*/*' '127' '[BONUS]'

# Test 49: CARACTERES A LA VOLEE (SYNTAXE)  🌦
[[ -z "$FILTER_CATEGORY" || "CARACTERES A LA VOLEE (SYNTAXE)  🌦" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'CARACTERES A LA VOLEE (SYNTAXE)  🌦' '*/*' '127' '[BONUS] S'\''il n'\''y aucun dossier à l'\''intérieur'

# Test 50: CARACTERES A LA VOLEE (SYNTAXE)  🌦
[[ -z "$FILTER_CATEGORY" || "CARACTERES A LA VOLEE (SYNTAXE)  🌦" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'CARACTERES A LA VOLEE (SYNTAXE)  🌦' '.' '2' ''

# Test 51: CARACTERES A LA VOLEE (SYNTAXE)  🌦
[[ -z "$FILTER_CATEGORY" || "CARACTERES A LA VOLEE (SYNTAXE)  🌦" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'CARACTERES A LA VOLEE (SYNTAXE)  🌦' '..' '127' ''

# Test 52: CARACTERES A LA VOLEE (SYNTAXE)  🌦
[[ -z "$FILTER_CATEGORY" || "CARACTERES A LA VOLEE (SYNTAXE)  🌦" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'CARACTERES A LA VOLEE (SYNTAXE)  🌦' '~' '126' ''

# Test 53: CARACTERES A LA VOLEE (SYNTAXE)  🌦
[[ -z "$FILTER_CATEGORY" || "CARACTERES A LA VOLEE (SYNTAXE)  🌦" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'CARACTERES A LA VOLEE (SYNTAXE)  🌦' 'ABC=hola' '0' '/!\ A gerer comme une erreur'

# Test 54: CARACTERES A LA VOLEE (SYNTAXE)  🌦
[[ -z "$FILTER_CATEGORY" || "CARACTERES A LA VOLEE (SYNTAXE)  🌦" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'CARACTERES A LA VOLEE (SYNTAXE)  🌦' '4ABC=hola' '127' ''

# Test 55: CARACTERES A LA VOLEE (SYNTAXE)  🌦
[[ -z "$FILTER_CATEGORY" || "CARACTERES A LA VOLEE (SYNTAXE)  🌦" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'CARACTERES A LA VOLEE (SYNTAXE)  🌦' 'hola' '127' ''

# Test 56: CARACTERES A LA VOLEE (SYNTAXE)  🌦
[[ -z "$FILTER_CATEGORY" || "CARACTERES A LA VOLEE (SYNTAXE)  🌦" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'CARACTERES A LA VOLEE (SYNTAXE)  🌦' 'hola que tal' '127' ''

# Test 57: CARACTERES A LA VOLEE (SYNTAXE)  🌦
[[ -z "$FILTER_CATEGORY" || "CARACTERES A LA VOLEE (SYNTAXE)  🌦" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'CARACTERES A LA VOLEE (SYNTAXE)  🌦' 'Makefile' '127' ''

# Test 58: ECHO   🎉
[[ -z "$FILTER_CATEGORY" || "ECHO   🎉" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'ECHO   🎉' 'echo' '0' ''

# Test 59: ECHO   🎉
[[ -z "$FILTER_CATEGORY" || "ECHO   🎉" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'ECHO   🎉' 'echo -n' '0' ''

# Test 60: ECHO   🎉
[[ -z "$FILTER_CATEGORY" || "ECHO   🎉" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'ECHO   🎉' 'echo Hola' '0' ''

# Test 61: ECHO   🎉
[[ -z "$FILTER_CATEGORY" || "ECHO   🎉" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'ECHO   🎉' 'echoHola' '127' ''

# Test 62: ECHO   🎉
[[ -z "$FILTER_CATEGORY" || "ECHO   🎉" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'ECHO   🎉' 'echo-nHola' '127' ''

# Test 63: ECHO   🎉
[[ -z "$FILTER_CATEGORY" || "ECHO   🎉" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'ECHO   🎉' 'echo -n Hola' '0' ''

# Test 64: ECHO   🎉
[[ -z "$FILTER_CATEGORY" || "ECHO   🎉" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'ECHO   🎉' 'echo \"-n\" Hola' '0' ''

# Test 65: ECHO   🎉
[[ -z "$FILTER_CATEGORY" || "ECHO   🎉" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'ECHO   🎉' 'echo -nHola' '0' ''

# Test 66: ECHO   🎉
[[ -z "$FILTER_CATEGORY" || "ECHO   🎉" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'ECHO   🎉' 'echo Hola -n' '0' ''

# Test 67: ECHO   🎉
[[ -z "$FILTER_CATEGORY" || "ECHO   🎉" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'ECHO   🎉' 'echo Hola Que Tal' '0' ''

# Test 68: ECHO   🎉
[[ -z "$FILTER_CATEGORY" || "ECHO   🎉" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'ECHO   🎉' 'echo         Hola' '0' ''

# Test 69: ECHO   🎉
[[ -z "$FILTER_CATEGORY" || "ECHO   🎉" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'ECHO   🎉' 'echo    Hola     Que    Tal' '0' ''

# Test 70: ECHO   🎉
[[ -z "$FILTER_CATEGORY" || "ECHO   🎉" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'ECHO   🎉' 'echo      \n hola' '0' 'A gerer ?'

# Test 71: ECHO   🎉
[[ -z "$FILTER_CATEGORY" || "ECHO   🎉" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'ECHO   🎉' 'echo \"         \" | cat -e' '0' ''

# Test 72: ECHO   🎉
[[ -z "$FILTER_CATEGORY" || "ECHO   🎉" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'ECHO   🎉' 'echo           | cat -e' '0' ''

# Test 73: ECHO   🎉
[[ -z "$FILTER_CATEGORY" || "ECHO   🎉" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'ECHO   🎉' '\"\"'\'''\''echo hola\"\"'\'''\'''\'''\'' que\"\"'\'''\'' tal\"\"'\'''\''' '0' ''

# Test 74: ECHO   🎉
[[ -z "$FILTER_CATEGORY" || "ECHO   🎉" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'ECHO   🎉' 'echo -n -n' '0' ''

# Test 75: ECHO   🎉
[[ -z "$FILTER_CATEGORY" || "ECHO   🎉" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'ECHO   🎉' 'echo -n -n Hola Que' '0' ''

# Test 76: ECHO   🎉
[[ -z "$FILTER_CATEGORY" || "ECHO   🎉" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'ECHO   🎉' 'echo -p' '0' ''

# Test 77: ECHO   🎉
[[ -z "$FILTER_CATEGORY" || "ECHO   🎉" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'ECHO   🎉' 'echo -nnnnn' '0' ''

# Test 78: ECHO   🎉
[[ -z "$FILTER_CATEGORY" || "ECHO   🎉" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'ECHO   🎉' 'echo -n -nnn -nnnn' '0' ''

# Test 79: ECHO   🎉
[[ -z "$FILTER_CATEGORY" || "ECHO   🎉" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'ECHO   🎉' 'echo -n-nnn -nnnn' '0' ''

# Test 80: ECHO   🎉
[[ -z "$FILTER_CATEGORY" || "ECHO   🎉" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'ECHO   🎉' 'echo -n -nnn hola -nnnn' '0' ''

# Test 81: ECHO   🎉
[[ -z "$FILTER_CATEGORY" || "ECHO   🎉" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'ECHO   🎉' 'echo -n -nnn-nnnn' '0' ''

# Test 82: ECHO   🎉
[[ -z "$FILTER_CATEGORY" || "ECHO   🎉" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'ECHO   🎉' 'echo --------n' '0' ''

# Test 83: ECHO   🎉
[[ -z "$FILTER_CATEGORY" || "ECHO   🎉" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'ECHO   🎉' 'echo -nnn --------n' '0' ''

# Test 84: ECHO   🎉
[[ -z "$FILTER_CATEGORY" || "ECHO   🎉" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'ECHO   🎉' 'echo -nnn -----nn---nnnn' '0' ''

# Test 85: ECHO   🎉
[[ -z "$FILTER_CATEGORY" || "ECHO   🎉" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'ECHO   🎉' 'echo -nnn --------nnnn' '0' ''

# Test 86: ECHO   🎉
[[ -z "$FILTER_CATEGORY" || "ECHO   🎉" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'ECHO   🎉' 'echo $' '0' ''

# Test 87: ECHO   🎉
[[ -z "$FILTER_CATEGORY" || "ECHO   🎉" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'ECHO   🎉' 'echo $?' '0' 'Renvoie le code de retour du dernier pipeline exécuté à l'\''avant-plan'

# Test 88: ECHO   🎉
[[ -z "$FILTER_CATEGORY" || "ECHO   🎉" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'ECHO   🎉' 'echo $?$' '0' ''

# Test 89: ECHO   🎉
[[ -z "$FILTER_CATEGORY" || "ECHO   🎉" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'ECHO   🎉' 'echo $? | echo $? | echo $?' '0' ''

# Test 90: ECHO   🎉
[[ -z "$FILTER_CATEGORY" || "ECHO   🎉" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'ECHO   🎉' 'echo $:$= | cat -e' '0' ''

# Test 91: ECHO   🎉
[[ -z "$FILTER_CATEGORY" || "ECHO   🎉" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'ECHO   🎉' 'echo \" $ \" | cat -e' '0' ''

# Test 92: ECHO   🎉
[[ -z "$FILTER_CATEGORY" || "ECHO   🎉" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'ECHO   🎉' 'echo '\'' $ '\'' | cat -e' '0' ''

# Test 93: ECHO   🎉
[[ -z "$FILTER_CATEGORY" || "ECHO   🎉" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'ECHO   🎉' 'echo $HOME' '0' ''

# Test 94: ECHO   🎉
[[ -z "$FILTER_CATEGORY" || "ECHO   🎉" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'ECHO   🎉' 'echo \$HOME' '0' ''

# Test 95: ECHO   🎉
[[ -z "$FILTER_CATEGORY" || "ECHO   🎉" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'ECHO   🎉' 'echo my shit terminal is [$TERM]' '0' ''

# Test 96: ECHO   🎉
[[ -z "$FILTER_CATEGORY" || "ECHO   🎉" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'ECHO   🎉' 'echo my shit terminal is [$TERM4' '0' ''

# Test 97: ECHO   🎉
[[ -z "$FILTER_CATEGORY" || "ECHO   🎉" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'ECHO   🎉' 'echo my shit terminal is [$TERM4]' '0' ''

# Test 98: ECHO   🎉
[[ -z "$FILTER_CATEGORY" || "ECHO   🎉" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'ECHO   🎉' 'echo $UID' '0' ''

# Test 99: ECHO   🎉
[[ -z "$FILTER_CATEGORY" || "ECHO   🎉" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'ECHO   🎉' 'echo $HOME9' '0' 'Marche pour tous les caractères alphanumériques de l'\''ASCII'

# Test 100: ECHO   🎉
[[ -z "$FILTER_CATEGORY" || "ECHO   🎉" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'ECHO   🎉' 'echo $9HOME' '0' ''

# Test 101: ECHO   🎉
[[ -z "$FILTER_CATEGORY" || "ECHO   🎉" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'ECHO   🎉' 'echo $HOME%' '0' 'Marche pour les autres caractères (ponctuation, caractères non-ASCII, etc.)'

# Test 102: ECHO   🎉
[[ -z "$FILTER_CATEGORY" || "ECHO   🎉" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'ECHO   🎉' 'echo $UID$HOME' '0' ''

# Test 103: ECHO   🎉
[[ -z "$FILTER_CATEGORY" || "ECHO   🎉" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'ECHO   🎉' 'echo Le path de mon HOME est $HOME' '0' ''

# Test 104: ECHO   🎉
[[ -z "$FILTER_CATEGORY" || "ECHO   🎉" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'ECHO   🎉' 'echo $USER$var\$USER$USER\$USERtest$USER' '0' 'A ne pas gerer si '\''\'\'' non gere :
Doit sortir : vietdu91vietdu91vietdu91vie'

# Test 105: ECHO   🎉
[[ -z "$FILTER_CATEGORY" || "ECHO   🎉" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'ECHO   🎉' 'echo $hola*' '0' 'Cas d'\''un variable inexistant'

# Test 106: ECHO   🎉
[[ -z "$FILTER_CATEGORY" || "ECHO   🎉" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'ECHO   🎉' 'echo -nnnn $hola' '0' ''

# Test 107: ECHO   🎉
[[ -z "$FILTER_CATEGORY" || "ECHO   🎉" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'ECHO   🎉' 'echo > <' '2' ''

# Test 108: ECHO   🎉
[[ -z "$FILTER_CATEGORY" || "ECHO   🎉" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'ECHO   🎉' 'echo | |' '2' ''

# Test 109: ECHO   🎉
[[ -z "$FILTER_CATEGORY" || "ECHO   🎉" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'ECHO   🎉' 'EechoE' '127' ''

# Test 110: ECHO   🎉
[[ -z "$FILTER_CATEGORY" || "ECHO   🎉" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'ECHO   🎉' '.echo.' '127' ''

# Test 111: ECHO   🎉
[[ -z "$FILTER_CATEGORY" || "ECHO   🎉" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'ECHO   🎉' '>echo>' '2' ''

# Test 112: ECHO   🎉
[[ -z "$FILTER_CATEGORY" || "ECHO   🎉" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'ECHO   🎉' '<echo<' '2' ''

# Test 113: ECHO   🎉
[[ -z "$FILTER_CATEGORY" || "ECHO   🎉" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'ECHO   🎉' '>>echo>>' '2' ''

# Test 114: ECHO   🎉
[[ -z "$FILTER_CATEGORY" || "ECHO   🎉" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'ECHO   🎉' '|echo|' '2' ''

# Test 115: ECHO   🎉
[[ -z "$FILTER_CATEGORY" || "ECHO   🎉" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'ECHO   🎉' '|echo -n hola' '2' ''

# Test 116: ECHO   🎉
[[ -z "$FILTER_CATEGORY" || "ECHO   🎉" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'ECHO   🎉' 'echo *' '0' '[BONUS]'

# Test 117: ECHO   🎉
[[ -z "$FILTER_CATEGORY" || "ECHO   🎉" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'ECHO   🎉' 'echo '\''*'\''' '0' 'Marche aussi pour les double quotes'

# Test 118: ECHO   🎉
[[ -z "$FILTER_CATEGORY" || "ECHO   🎉" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'ECHO   🎉' 'echo D*' '0' '[BONUS]'

# Test 119: ECHO   🎉
[[ -z "$FILTER_CATEGORY" || "ECHO   🎉" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'ECHO   🎉' 'echo *Z' '0' '[BONUS]'

# Test 120: ECHO   🎉
[[ -z "$FILTER_CATEGORY" || "ECHO   🎉" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'ECHO   🎉' 'echo *t hola' '0' '[BONUS]'

# Test 121: ECHO   🎉
[[ -z "$FILTER_CATEGORY" || "ECHO   🎉" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'ECHO   🎉' 'echo *t' '0' '[BONUS]'

# Test 122: ECHO   🎉
[[ -z "$FILTER_CATEGORY" || "ECHO   🎉" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'ECHO   🎉' 'echo $*' '0' '[BONUS]'

# Test 123: ECHO   🎉
[[ -z "$FILTER_CATEGORY" || "ECHO   🎉" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'ECHO   🎉' 'echo hola*hola *' '0' '[BONUS]'

# Test 124: ECHO   🎉
[[ -z "$FILTER_CATEGORY" || "ECHO   🎉" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'ECHO   🎉' 'echo $hola*' '0' '[BONUS]'

# Test 125: ECHO   🎉
[[ -z "$FILTER_CATEGORY" || "ECHO   🎉" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'ECHO   🎉' 'echo $HOME*' '0' '[BONUS]'

# Test 126: ECHO   🎉
[[ -z "$FILTER_CATEGORY" || "ECHO   🎉" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'ECHO   🎉' 'echo $\"\"' '0' ''

# Test 127: ECHO   🎉
[[ -z "$FILTER_CATEGORY" || "ECHO   🎉" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'ECHO   🎉' 'echo \"$\"\"\"' '0' ''

# Test 128: ECHO   🎉
[[ -z "$FILTER_CATEGORY" || "ECHO   🎉" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'ECHO   🎉' 'echo '\''$'\'''\'''\''' '0' ''

# Test 129: ECHO   🎉
[[ -z "$FILTER_CATEGORY" || "ECHO   🎉" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'ECHO   🎉' 'echo $\"HOME\"' '0' ''

# Test 130: ECHO   🎉
[[ -z "$FILTER_CATEGORY" || "ECHO   🎉" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'ECHO   🎉' 'echo $'\'''\''HOME' '0' ''

# Test 131: ECHO   🎉
[[ -z "$FILTER_CATEGORY" || "ECHO   🎉" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'ECHO   🎉' 'echo $\"\"HOME' '0' ''

# Test 132: ECHO   🎉
[[ -z "$FILTER_CATEGORY" || "ECHO   🎉" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'ECHO   🎉' 'echo \"$HO\"ME' '0' ''

# Test 133: ECHO   🎉
[[ -z "$FILTER_CATEGORY" || "ECHO   🎉" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'ECHO   🎉' 'echo '\''$HO'\''ME' '0' ''

# Test 134: ECHO   🎉
[[ -z "$FILTER_CATEGORY" || "ECHO   🎉" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'ECHO   🎉' 'echo \"$HO\"\"ME\"' '0' ''

# Test 135: ECHO   🎉
[[ -z "$FILTER_CATEGORY" || "ECHO   🎉" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'ECHO   🎉' 'echo '\''$HO'\'''\''ME'\''' '0' ''

# Test 136: ECHO   🎉
[[ -z "$FILTER_CATEGORY" || "ECHO   🎉" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'ECHO   🎉' 'echo \"'\''$HO'\'''\''ME'\''\"' '0' '⚠️ Il y a bien 3 singles quotes avant le ME. Je ne sais pas pourquoi Excel tronq'

# Test 137: ECHO   🎉
[[ -z "$FILTER_CATEGORY" || "ECHO   🎉" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'ECHO   🎉' 'echo \"\"$HOME' '0' ''

# Test 138: ECHO   🎉
[[ -z "$FILTER_CATEGORY" || "ECHO   🎉" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'ECHO   🎉' 'echo \"\" $HOME' '0' ''

# Test 139: ECHO   🎉
[[ -z "$FILTER_CATEGORY" || "ECHO   🎉" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'ECHO   🎉' 'echo '\'''\''$HOME' '0' ''

# Test 140: ECHO   🎉
[[ -z "$FILTER_CATEGORY" || "ECHO   🎉" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'ECHO   🎉' 'echo '\'''\'' $HOME' '0' ''

# Test 141: ECHO   🎉
[[ -z "$FILTER_CATEGORY" || "ECHO   🎉" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'ECHO   🎉' 'echo $\"HO\"\"ME\"' '0' ''

# Test 142: ECHO   🎉
[[ -z "$FILTER_CATEGORY" || "ECHO   🎉" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'ECHO   🎉' 'echo $'\''HO'\'''\''ME'\''' '0' ''

# Test 143: ECHO   🎉
[[ -z "$FILTER_CATEGORY" || "ECHO   🎉" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'ECHO   🎉' 'echo $'\''HOME'\''' '0' ''

# Test 144: ECHO   🎉
[[ -z "$FILTER_CATEGORY" || "ECHO   🎉" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'ECHO   🎉' 'echo \"$\"HOME' '0' ''

# Test 145: ECHO   🎉
[[ -z "$FILTER_CATEGORY" || "ECHO   🎉" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'ECHO   🎉' 'echo $=HOME' '0' ''

# Test 146: ECHO   🎉
[[ -z "$FILTER_CATEGORY" || "ECHO   🎉" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'ECHO   🎉' 'echo $\"HOLA\"' '0' ''

# Test 147: ECHO   🎉
[[ -z "$FILTER_CATEGORY" || "ECHO   🎉" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'ECHO   🎉' 'echo $'\''HOLA'\''' '0' ''

# Test 148: ECHO   🎉
[[ -z "$FILTER_CATEGORY" || "ECHO   🎉" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'ECHO   🎉' 'echo $DONTEXIST Hola' '0' 'Le cas ou la variable n'\''existe pas et n'\''est pas importee'

# Test 149: ECHO   🎉
[[ -z "$FILTER_CATEGORY" || "ECHO   🎉" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'ECHO   🎉' 'echo \"hola\"' '0' ''

# Test 150: ECHO   🎉
[[ -z "$FILTER_CATEGORY" || "ECHO   🎉" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'ECHO   🎉' 'echo '\''hola'\''' '0' ''

# Test 151: ECHO   🎉
[[ -z "$FILTER_CATEGORY" || "ECHO   🎉" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'ECHO   🎉' 'echo '\'''\''hola'\'''\''' '0' ''

# Test 152: ECHO   🎉
[[ -z "$FILTER_CATEGORY" || "ECHO   🎉" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'ECHO   🎉' 'echo '\'''\''h'\''o'\''la'\'''\''' '0' ''

# Test 153: ECHO   🎉
[[ -z "$FILTER_CATEGORY" || "ECHO   🎉" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'ECHO   🎉' 'echo \"'\'''\''h'\''o'\''la'\'''\''\"' '0' ''

# Test 154: ECHO   🎉
[[ -z "$FILTER_CATEGORY" || "ECHO   🎉" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'ECHO   🎉' 'echo \"'\''\"h'\''o'\''la\"'\''\"' '0' ''

# Test 155: ECHO   🎉
[[ -z "$FILTER_CATEGORY" || "ECHO   🎉" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'ECHO   🎉' 'echo\"'\''hola'\''\"' '0' ''

# Test 156: ECHO   🎉
[[ -z "$FILTER_CATEGORY" || "ECHO   🎉" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'ECHO   🎉' 'echo \"'\''hola'\''\"' '0' ''

# Test 157: ECHO   🎉
[[ -z "$FILTER_CATEGORY" || "ECHO   🎉" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'ECHO   🎉' 'echo '\''\"hola\"'\''' '0' ''

# Test 158: ECHO   🎉
[[ -z "$FILTER_CATEGORY" || "ECHO   🎉" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'ECHO   🎉' 'echo '\'''\'''\''ho\"'\'''\'''\'''\''l\"a'\'''\'''\''' '0' ''

# Test 159: ECHO   🎉
[[ -z "$FILTER_CATEGORY" || "ECHO   🎉" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'ECHO   🎉' 'echo hola\"\"\"\"\"\"\"\"\"\"\"\"' '0' ''

# Test 160: ECHO   🎉
[[ -z "$FILTER_CATEGORY" || "ECHO   🎉" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'ECHO   🎉' 'echo hola\"'\'''\'''\'''\'''\'''\'''\'''\'''\'''\''\"' '0' ''

# Test 161: ECHO   🎉
[[ -z "$FILTER_CATEGORY" || "ECHO   🎉" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'ECHO   🎉' 'echo hola'\'''\'''\'''\'''\'''\'''\'''\'''\'''\'''\'''\''' '0' ''

# Test 162: ECHO   🎉
[[ -z "$FILTER_CATEGORY" || "ECHO   🎉" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'ECHO   🎉' 'echo hola'\''\"\"\"\"\"\"\"\"\"\"'\''' '0' ''

# Test 163: ECHO   🎉
[[ -z "$FILTER_CATEGORY" || "ECHO   🎉" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'ECHO   🎉' 'e\"cho hola\"' '127' ''

# Test 164: ECHO   🎉
[[ -z "$FILTER_CATEGORY" || "ECHO   🎉" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'ECHO   🎉' 'e'\''cho hola'\''' '127' ''

# Test 165: ECHO   🎉
[[ -z "$FILTER_CATEGORY" || "ECHO   🎉" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'ECHO   🎉' 'echo \"hola     \" | cat -e' '0' ''

# Test 166: ECHO   🎉
[[ -z "$FILTER_CATEGORY" || "ECHO   🎉" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'ECHO   🎉' 'echo \"\"hola' '0' ''

# Test 167: ECHO   🎉
[[ -z "$FILTER_CATEGORY" || "ECHO   🎉" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'ECHO   🎉' 'echo \"\" hola' '0' ''

# Test 168: ECHO   🎉
[[ -z "$FILTER_CATEGORY" || "ECHO   🎉" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'ECHO   🎉' 'echo \"\"             hola' '0' ''

# Test 169: ECHO   🎉
[[ -z "$FILTER_CATEGORY" || "ECHO   🎉" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'ECHO   🎉' 'echo \"\"hola' '0' ''

# Test 170: ECHO   🎉
[[ -z "$FILTER_CATEGORY" || "ECHO   🎉" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'ECHO   🎉' 'echo \"\" hola' '0' ''

# Test 171: ECHO   🎉
[[ -z "$FILTER_CATEGORY" || "ECHO   🎉" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'ECHO   🎉' 'echo hola\"\"bonjour' '0' ''

# Test 172: ECHO   🎉
[[ -z "$FILTER_CATEGORY" || "ECHO   🎉" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'ECHO   🎉' '\"e\"'\''c'\''ho '\''b'\''\"o\"nj\"o\"'\''u'\''r' '0' ''

# Test 173: ECHO   🎉
[[ -z "$FILTER_CATEGORY" || "ECHO   🎉" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'ECHO   🎉' '\"\"e\"'\''c'\''ho '\''b'\''\"o\"nj\"o\"'\''u'\''r\"' '127' ''

# Test 174: ECHO   🎉
[[ -z "$FILTER_CATEGORY" || "ECHO   🎉" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'ECHO   🎉' 'echo \"$DONTEXIST\"Makefile' '0' ''

# Test 175: ECHO   🎉
[[ -z "$FILTER_CATEGORY" || "ECHO   🎉" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'ECHO   🎉' 'echo \"$DONTEXIST\"\"Makefile\"' '0' ''

# Test 176: ECHO   🎉
[[ -z "$FILTER_CATEGORY" || "ECHO   🎉" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'ECHO   🎉' 'echo \"$DONTEXIST\" \"Makefile\"' '0' 'Attention a l'\''espace avant'

# Test 177: 💰
[[ -z "$FILTER_CATEGORY" || "💰" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '💰' '$?' '127' 'Renvoie le code de retour du dernier pipeline exécuté à l'\''avant-plan'

# Test 178: 💰
[[ -z "$FILTER_CATEGORY" || "💰" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '💰' '$?$?' '127' ''

# Test 179: 💰
[[ -z "$FILTER_CATEGORY" || "💰" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '💰' '?$HOME' '127' ''

# Test 180: 💰
[[ -z "$FILTER_CATEGORY" || "💰" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '💰' '$' '127' ''

# Test 181: 💰
[[ -z "$FILTER_CATEGORY" || "💰" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '💰' '$HOME' '126' ''

# Test 182: 💰
[[ -z "$FILTER_CATEGORY" || "💰" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '💰' '$HOMEdskjhfkdshfsd' '0' ''

# Test 183: 💰
[[ -z "$FILTER_CATEGORY" || "💰" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '💰' '\"$HOMEdskjhfkdshfsd\"' '127' ''

# Test 184: 💰
[[ -z "$FILTER_CATEGORY" || "💰" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '💰' ''\''$HOMEdskjhfkdshfsd'\''' '127' ''

# Test 185: 💰
[[ -z "$FILTER_CATEGORY" || "💰" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '💰' '$DONTEXIST' '0' 'Cas d'\''un variable inexistant'

# Test 186: 💰
[[ -z "$FILTER_CATEGORY" || "💰" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '💰' '$LESS$VAR' '127' ''

# Test 187: SIGNAUX 🛰
[[ -z "$FILTER_CATEGORY" || "SIGNAUX 🛰" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'SIGNAUX 🛰' 'Ctlr-C' '130' ''

# Test 188: SIGNAUX 🛰
[[ -z "$FILTER_CATEGORY" || "SIGNAUX 🛰" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'SIGNAUX 🛰' 'holaCtlr-C' '130' ''

# Test 189: SIGNAUX 🛰
[[ -z "$FILTER_CATEGORY" || "SIGNAUX 🛰" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'SIGNAUX 🛰' 'cat (faire Ctlr-C apres avoir fait plusieurs fois [ENTREE])' '130' ''

# Test 190: SIGNAUX 🛰
[[ -z "$FILTER_CATEGORY" || "SIGNAUX 🛰" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'SIGNAUX 🛰' 'cat | rev(faire Ctlr-C apres avoir fait plusieurs fois [ENTREE])' '0' ''

# Test 191: SIGNAUX 🛰
[[ -z "$FILTER_CATEGORY" || "SIGNAUX 🛰" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'SIGNAUX 🛰' 'Ctlr-D' '0' 'Sort du programme'

# Test 192: SIGNAUX 🛰
[[ -z "$FILTER_CATEGORY" || "SIGNAUX 🛰" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'SIGNAUX 🛰' 'hola Ctlr-D' '0' 'Ne fait rien'

# Test 193: SIGNAUX 🛰
[[ -z "$FILTER_CATEGORY" || "SIGNAUX 🛰" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'SIGNAUX 🛰' 'Ctlr-\' '0' 'Ne fait rien'

# Test 194: SIGNAUX 🛰
[[ -z "$FILTER_CATEGORY" || "SIGNAUX 🛰" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'SIGNAUX 🛰' 'hola Ctlr-\' '0' ''

# Test 195: SIGNAUX 🛰
[[ -z "$FILTER_CATEGORY" || "SIGNAUX 🛰" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'SIGNAUX 🛰' 'cat (faire Ctlr-\ apres avoir fait plusieurs fois [ENTREE])' '131' ''

# Test 196: SIGNAUX 🛰
[[ -z "$FILTER_CATEGORY" || "SIGNAUX 🛰" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'SIGNAUX 🛰' 'Ctlr-Z' '0' 'Ne fait rien'

# Test 197: SIGNAUX 🛰
[[ -z "$FILTER_CATEGORY" || "SIGNAUX 🛰" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'SIGNAUX 🛰' 'sleep 3 | sleep 3 | sleep 3 (faire Ctlr-C une seconde apres)' '130' ''

# Test 198: SIGNAUX 🛰
[[ -z "$FILTER_CATEGORY" || "SIGNAUX 🛰" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'SIGNAUX 🛰' 'sleep 3 | sleep 3 | sleep 3 (faire Ctlr-D une seconde apres)' '0' 'Ne fait rien'

# Test 199: SIGNAUX 🛰
[[ -z "$FILTER_CATEGORY" || "SIGNAUX 🛰" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'SIGNAUX 🛰' 'sleep 3 | sleep 3 | sleep 3 (faire Ctlr-\ une seconde apres)' '131' ''

# Test 200: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'env' '0' ''

# Test 201: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'env hola' '127' ''

# Test 202: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'env hola que tal' '127' ''

# Test 203: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'env env' '0' 'Affiche une seule fois env'

# Test 204: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'env env env env env' '0' 'Affiche une seule fois env'

# Test 205: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'env ls' '0' ''

# Test 206: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'env ./Makefile' '126' ''

# Test 207: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'export HOLA=bonjour
$> env' '0' ''

# Test 208: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'export       HOLA=bonjour
$> env' '0' ''

# Test 209: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'export' '0' 'Les variables sont triees par ordre alphabetique
On n'\''oublie pas les doubles '

# Test 210: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'export Hola
$> export' '0' 'Hola n'\''existe pas dans env mais il existe dans export'

# Test 211: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'export Hola9hey
$> export' '0' ''

# Test 212: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'export $DONTEXIST' '0' 'Le cas ou la variable n'\''existe pas et n'\''est pas importee'

# Test 213: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'export | grep \"HOME\"' '0' ''

# Test 214: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'export \"\"' '1' ''

# Test 215: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'export =' '1' ''

# Test 216: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'export %' '1' ''

# Test 217: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'export $?' '1' ''

# Test 218: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'export ?=2' '1' ''

# Test 219: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'export 9HOLA=' '1' ''

# Test 220: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'export HOLA9=bonjour
$> env' '0' ''

# Test 221: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'export _HOLA=bonjour
$> env' '0' ''

# Test 222: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'export ___HOLA=bonjour
$> env' '0' ''

# Test 223: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'export _HO_LA_=bonjour
$> env' '0' ''

# Test 224: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'export HOL@=bonjour' '1' 'Cas où le nom de variable ne contient pas de lettres, ni de chiffres, ni d'\''un'

# Test 225: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'export HOL\~A=bonjour' '1' ''

# Test 226: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'export -HOLA=bonjour' '2' ''

# Test 227: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'export --HOLA=bonjour' '2' ''

# Test 228: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'export HOLA-=bonjour' '1' ''

# Test 229: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'export HO-LA=bonjour' '1' ''

# Test 230: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'export HOL.A=bonjour' '1' ''

# Test 231: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'export HOL\\\$A=bonjour' '1' ''

# Test 232: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'export HO\\\\LA=bonjour' '1' ''

# Test 233: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'export HOL}A=bonjour' '1' ''

# Test 234: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'export HOL{A=bonjour' '1' ''

# Test 235: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'export HO*LA=bonjour' '1' ''

# Test 236: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'export HO#LA=bonjour' '1' ''

# Test 237: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'export HO@LA=bonjour' '1' ''

# Test 238: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'export HO!LA=bonjour' '0' ''

# Test 239: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'export HO$?LA=bonjour
$> env' '0' ''

# Test 240: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'export +HOLA=bonjour' '1' ''

# Test 241: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'export HOL+A=bonjour' '1' ''

# Test 242: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'export HOLA+=bonjour
$> env' '0' ''

# Test 243: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'export HOLA=bonjour
$> export HOLA+=bonjour
$> env' '0' '\"+=\" s'\''ajoute au contenu de la variable'

# Test 244: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'exportHOLA=bonjour
$> env' '0' ''

# Test 245: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'export HOLA =bonjour' '1' ''

# Test 246: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'export HOLA = bonjour' '1' ''

# Test 247: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'export HOLA=bon jour
$> env' '0' ''

# Test 248: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'export HOLA= bonjour
$> env' '0' ''

# Test 249: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'export HOLA=bonsoir
$> export HOLA=bonretour
$> export HOLA=bonjour
$> env' '0' ''

# Test 250: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'export HOLA=$HOME
$> env' '0' ''

# Test 251: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'export HOLA=bonjour$HOME
$> env' '0' ''

# Test 252: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'export HOLA=$HOMEbonjour
$> env' '0' ''

# Test 253: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'export HOLA=bon$jour
$> env' '0' 'Le cas où la variable \"$jour\" n'\''existe pas'

# Test 254: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'export HOLA=bon\jour
$> env' '0' ''

# Test 255: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'export HOLA=bon\\jour
$> env' '0' ''

# Test 256: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'export HOLA=bon(jour' '2' 'Marche pour les caractères : ()'

# Test 257: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'export HOLA=bon()jour' '2' ''

# Test 258: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'export HOLA=bon&jour' '127' 'Marche pour les caractères : &|'

# Test 259: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'export HOLA=bon@jour
$> env' '0' ''

# Test 260: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'export HOLA=bon;jour
$> env' '127' ''

# Test 261: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'export HOLA=bon!jour' '1' ''

# Test 262: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'export HOLA=bon\"jour\"
$> env' '0' ''

# Test 263: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'export HOLA$USER=bonjour
$> env' '0' ''

# Test 264: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'export HOLA=bonjour=casse-toi
$> echo $HOLA' '0' ''

# Test 265: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'export \"HOLA=bonjour\"=casse-toi
$> echo $HOLA' '0' ''

# Test 266: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'export HOLA=bonjour
$> export BYE=casse-toi
$> echo $HOLA et $BYE' '0' ''

# Test 267: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'export HOLA=bonjour BYE=casse-toi
$> echo $HOLA et $BYE' '0' ''

# Test 268: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'export $HOLA=bonjour
$> env' '0' ''

# Test 269: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'export HOLA=\"bonjour      \"  
$> echo $HOLA | cat -e' '0' ''

# Test 270: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'export HOLA=\"   -n bonjour   \"  
$> echo $HOLA' '0' ''

# Test 271: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'export HOLA=\"bonjour   \"/
$> echo $HOLA' '0' ''

# Test 272: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'export HOLA='\''\"'\''
$> echo \" $HOLA \" | cat -e' '0' ''

# Test 273: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'export HOLA=at
$> c$HOLA Makefile' '0' ''

# Test 274: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'export \"\" HOLA=bonjour
$> env' '1' ''

# Test 275: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'export HOLA=\"cat Makefile | grep NAME\"  
$> echo $HOLA' '0' ''

# Test 276: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'export HOLA=hey 
$> echo $HOLA$HOLA$HOLA=hey$HOLA' '0' ''

# Test 277: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'export HOLA=\"  bonjour  hey  \"  
$> echo $HOLA | cat -e' '0' ''

# Test 278: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'export HOLA=\"  bonjour  hey  \"  
$> echo \"\"\"$HOLA\"\"\" | cat -e' '0' ''

# Test 279: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'export HOLA=\"  bonjour  hey  \"  
$> echo wesh\"$HOLA\" | cat -e' '0' ''

# Test 280: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'export HOLA=\"  bonjour  hey  \"  
$> echo wesh\"\"$HOLA.' '0' '/!\ Bien supprimer les espaces en trop au debut et a la fin du string d'\''expor'

# Test 281: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'export HOLA=\"  bonjour  hey  \"  
$> echo wesh$\"\"HOLA.' '0' ''

# Test 282: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'export HOLA=\"  bonjour  hey  \"  
$> echo wesh$\"HOLA HOLA\".' '0' ''

# Test 283: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'export HOLA=bonjour
$> export HOLA=\" hola et $HOLA\"
$> echo $HOLA' '0' ''

# Test 284: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'export HOLA=bonjour
$> export HOLA='\'' hola et $HOLA'\''
$> echo $HOLA' '0' ''

# Test 285: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'export HOLA=bonjour
$> export HOLA=\" hola et $HOLA\"$HOLA
$> echo $HOLA' '0' ''

# Test 286: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'export HOLA=\"ls        -l    - a\"
$> echo $HOLA' '0' ''

# Test 287: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'export HOLA=\"s -la\" 
$> l$HOLA' '0' ''

# Test 288: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'export HOLA=\"s -la\" 
$> l\"$HOLA\"' '127' ''

# Test 289: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'export HOLA=\"s -la\" 
$> l'\''$HOLA'\''' '127' ''

# Test 290: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'export HOLA=\"l\" 
$> $HOLAs' '0' ''

# Test 291: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'export HOLA=\"l\" 
$> \"$HOLA\"s' '0' ''

# Test 292: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'export HOL=A=bonjour
$> env' '0' ''

# Test 293: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'export HOLA=\"l\" 
$> '\''$HOLA'\''s' '127' ''

# Test 294: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'export HOL=A=\"\"
$> env' '0' ''

# Test 295: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'export TE+S=T
$> env' '1' ''

# Test 296: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'export \"\"=\"\"' '1' ''

# Test 297: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'export '\'''\''='\'''\''' '1' ''

# Test 298: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'export \"=\"=\"=\"' '1' ''

# Test 299: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'export '\''='\''='\''='\''' '1' ''

# Test 300: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'export HOLA=p
$> export BYE=w
$> $HOLA\"BYE\"d' '127' ''

# Test 301: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'export HOLA=p
$> export BYE=w
$> \"$HOLA\"'\''$BYE'\''d' '127' ''

# Test 302: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'export HOLA=p
$> export BYE=w
$> \"$HOLA\"\"$BYE\"d' '0' ''

# Test 303: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'export HOLA=p
$> export BYE=w
$> $\"HOLA\"$\"BYE\"d' '127' ''

# Test 304: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'export HOLA=p
$> export BYE=w
$> $'\''HOLA'\''$'\''BYE'\''d' '127' ''

# Test 305: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'export HOLA=-n
$> \"echo $HOLA\" hey' '127' ''

# Test 306: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'export A=1 B=2 C=3 D=4 E=5 F=6 G=7 H=8
$> echo \"$A'\''$B\"'\''$C\"$D'\''$E'\''\"$F'\''\"'\''$G'\''$H\"' '0' ''

# Test 307: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'export HOLA=bonjour
$> env
$> unset HOLA
$> env' '0' ''

# Test 308: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'export HOLA=bonjour
$> env
$> unset HOLA
$> unset HOLA
$> env' '0' ''

# Test 309: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'unset PATH
$> echo $PATH' '0' ''

# Test 310: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'unset PATH
$> ls' '127' ''

# Test 311: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'unset \"\"' '1' ''

# Test 312: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'unset INEXISTANT' '0' 'Cas où la variable n'\''existe pas'

# Test 313: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'unset PWD
$> env | grep PWD
$> pwd' '0' ''

# Test 314: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'pwd
$> unset PWD
$> env | grep PWD
$> cd $PWD
$> pwd' '0' ''

# Test 315: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'unset OLDPWD
$> env | grep OLDPWD' '0' ''

# Test 316: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'unset 9HOLA' '1' ''

# Test 317: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'unset HOLA9' '0' ''

# Test 318: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'unset HOL?A' '1' ''

# Test 319: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'unset HOLA HOL?A' '1' 'Il unset bien HOLA'

# Test 320: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'unset HOL?A HOLA' '1' 'Il unset bien HOLA'

# Test 321: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'unset HOL?A HOL.A' '1' ''

# Test 322: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'unset HOLA=' '1' ''

# Test 323: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'unset HOL\\\\A' '1' ''

# Test 324: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'unset HOL;A' '127' ''

# Test 325: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'unset HOL.A' '1' ''

# Test 326: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'unset HOL+A' '1' ''

# Test 327: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'unset HOL=A' '1' ''

# Test 328: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'unset HOL{A' '1' ''

# Test 329: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'unset HOL}A' '1' ''

# Test 330: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'unset HOL-A' '1' ''

# Test 331: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'unset -HOLA' '2' ''

# Test 332: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'unset _HOLA' '0' ''

# Test 333: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'unset HOL_A' '0' ''

# Test 334: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'unset HOLA_' '0' ''

# Test 335: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'unset HOL*A' '1' ''

# Test 336: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'unset HOL#A' '1' ''

# Test 337: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'unset $HOLA' '0' 'Il va unset le contenu de $HOLA, c'\''est-a-dire la variable bonjour'

# Test 338: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'unset $PWD' '1' ''

# Test 339: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'unset HOL@' '1' ''

# Test 340: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'unset HOL!A' '1' ''

# Test 341: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'unset HOL^A' '1' ''

# Test 342: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'unset HOL$?A' '0' 'Unset prend en compte le contenu de $?, c'\''est-a-dire qu'\''il lit HOL0A ou HO'

# Test 343: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'unset HOL\~A' '1' ''

# Test 344: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'unset \"\" HOLA
$> env | grep HOLA' '1' 'HOLA sera quand meme unset !!'

# Test 345: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'unset PATH
$> echo $PATH' '0' ''

# Test 346: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'unset PATH
$> cat Makefile' '0' ''

# Test 347: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'unset =' '0' ''

# Test 348: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'unset ======' '0' ''

# Test 349: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'unset ++++++' '0' ''

# Test 350: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'unset _______' '0' ''

# Test 351: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'unset export' '0' ''

# Test 352: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'unset echo' '0' ''

# Test 353: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'unset pwd' '0' ''

# Test 354: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'unset cd' '0' ''

# Test 355: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'unset unset' '0' ''

# Test 356: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'unset sudo' '0' ''

# Test 357: 🛫 ENV & EXPORT & UNSET 🛬
[[ -z "$FILTER_CATEGORY" || "🛫 ENV & EXPORT & UNSET 🛬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '🛫 ENV & EXPORT & UNSET 🛬' 'export hola | unset hola | echo $?' '0' ''

# Test 358: FICHIERS BINAIRES 0️⃣ 1️⃣
[[ -z "$FILTER_CATEGORY" || "FICHIERS BINAIRES 0️⃣ 1️⃣" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'FICHIERS BINAIRES 0️⃣ 1️⃣' '/bin/echo' '0' ''

# Test 359: FICHIERS BINAIRES 0️⃣ 1️⃣
[[ -z "$FILTER_CATEGORY" || "FICHIERS BINAIRES 0️⃣ 1️⃣" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'FICHIERS BINAIRES 0️⃣ 1️⃣' '/bin/echo Hola Que Tal' '0' ''

# Test 360: FICHIERS BINAIRES 0️⃣ 1️⃣
[[ -z "$FILTER_CATEGORY" || "FICHIERS BINAIRES 0️⃣ 1️⃣" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'FICHIERS BINAIRES 0️⃣ 1️⃣' '/bin/env' '0' ''

# Test 361: FICHIERS BINAIRES 0️⃣ 1️⃣
[[ -z "$FILTER_CATEGORY" || "FICHIERS BINAIRES 0️⃣ 1️⃣" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'FICHIERS BINAIRES 0️⃣ 1️⃣' '/bin/cd Desktop' '127' ''

# Test 362: HISTORIQUE 🏦
[[ -z "$FILTER_CATEGORY" || "HISTORIQUE 🏦" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'HISTORIQUE 🏦' 'history' '0' 'Affiche les 500 dernières commandes'

# Test 363: HISTORIQUE 🏦
[[ -z "$FILTER_CATEGORY" || "HISTORIQUE 🏦" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'HISTORIQUE 🏦' '[touche du haut]' '0' 'Defile l'\''historique'

# Test 364: CD 💿 PWD
[[ -z "$FILTER_CATEGORY" || "CD 💿 PWD" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'CD 💿 PWD' 'pwd' '0' 'Retourne $PWD'

# Test 365: CD 💿 PWD
[[ -z "$FILTER_CATEGORY" || "CD 💿 PWD" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'CD 💿 PWD' 'pwd hola' '0' ''

# Test 366: CD 💿 PWD
[[ -z "$FILTER_CATEGORY" || "CD 💿 PWD" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'CD 💿 PWD' 'pwd ./hola' '0' ''

# Test 367: CD 💿 PWD
[[ -z "$FILTER_CATEGORY" || "CD 💿 PWD" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'CD 💿 PWD' 'pwd hola que tal' '0' ''

# Test 368: CD 💿 PWD
[[ -z "$FILTER_CATEGORY" || "CD 💿 PWD" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'CD 💿 PWD' 'pwd -p' '2' ''

# Test 369: CD 💿 PWD
[[ -z "$FILTER_CATEGORY" || "CD 💿 PWD" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'CD 💿 PWD' 'pwd --p' '2' ''

# Test 370: CD 💿 PWD
[[ -z "$FILTER_CATEGORY" || "CD 💿 PWD" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'CD 💿 PWD' 'pwd ---p' '2' ''

# Test 371: CD 💿 PWD
[[ -z "$FILTER_CATEGORY" || "CD 💿 PWD" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'CD 💿 PWD' 'pwd -- p' '0' ''

# Test 372: CD 💿 PWD
[[ -z "$FILTER_CATEGORY" || "CD 💿 PWD" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'CD 💿 PWD' 'pwd pwd pwd' '0' 'N'\''affiche qu'\''une fois'

# Test 373: CD 💿 PWD
[[ -z "$FILTER_CATEGORY" || "CD 💿 PWD" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'CD 💿 PWD' 'pwd ls' '0' ''

# Test 374: CD 💿 PWD
[[ -z "$FILTER_CATEGORY" || "CD 💿 PWD" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'CD 💿 PWD' 'pwd ls env' '0' ''

# Test 375: CD 💿 PWD
[[ -z "$FILTER_CATEGORY" || "CD 💿 PWD" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'CD 💿 PWD' 'cd' '0' 'On doit se retrouver dans le dossier défini par $HOME
/home/vietdu91'

# Test 376: CD 💿 PWD
[[ -z "$FILTER_CATEGORY" || "CD 💿 PWD" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'CD 💿 PWD' 'cd .' '0' 'L'\''user reste dans le même dossier
/home/vietdu91/42_works/minishell'

# Test 377: CD 💿 PWD
[[ -z "$FILTER_CATEGORY" || "CD 💿 PWD" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'CD 💿 PWD' 'cd ./' '0' '/home/vietdu91/42_works/minishell'

# Test 378: CD 💿 PWD
[[ -z "$FILTER_CATEGORY" || "CD 💿 PWD" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'CD 💿 PWD' 'cd ./././.' '0' '/home/vietdu91/42_works/minishell'

# Test 379: CD 💿 PWD
[[ -z "$FILTER_CATEGORY" || "CD 💿 PWD" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'CD 💿 PWD' 'cd ././././' '0' '/home/vietdu91/42_works/minishell'

# Test 380: CD 💿 PWD
[[ -z "$FILTER_CATEGORY" || "CD 💿 PWD" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'CD 💿 PWD' 'cd ..' '0' 'On se retrouve au dossier précédent
/home/vietdu91/42_works'

# Test 381: CD 💿 PWD
[[ -z "$FILTER_CATEGORY" || "CD 💿 PWD" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'CD 💿 PWD' 'cd ../' '0' '/home/vietdu91/42_works'

# Test 382: CD 💿 PWD
[[ -z "$FILTER_CATEGORY" || "CD 💿 PWD" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'CD 💿 PWD' 'cd ../..' '0' '/home/vietdu91'

# Test 383: CD 💿 PWD
[[ -z "$FILTER_CATEGORY" || "CD 💿 PWD" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'CD 💿 PWD' 'cd ../.' '0' '/home/vietdu91/42_works'

# Test 384: CD 💿 PWD
[[ -z "$FILTER_CATEGORY" || "CD 💿 PWD" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'CD 💿 PWD' 'cd .././././.' '0' '/home/vietdu91/42_works'

# Test 385: CD 💿 PWD
[[ -z "$FILTER_CATEGORY" || "CD 💿 PWD" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'CD 💿 PWD' 'cd srcs' '0' '/home/vietdu91/42_works/minishell/srcs'

# Test 386: CD 💿 PWD
[[ -z "$FILTER_CATEGORY" || "CD 💿 PWD" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'CD 💿 PWD' 'cd srcs objs' '1' '/home/vietdu91/42_works/minishell'

# Test 387: CD 💿 PWD
[[ -z "$FILTER_CATEGORY" || "CD 💿 PWD" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'CD 💿 PWD' 'cd '\''srcs'\''' '0' '/home/vietdu91/42_works/minishell/srcs'

# Test 388: CD 💿 PWD
[[ -z "$FILTER_CATEGORY" || "CD 💿 PWD" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'CD 💿 PWD' 'cd \"srcs\"' '0' '/home/vietdu91/42_works/minishell/srcs'

# Test 389: CD 💿 PWD
[[ -z "$FILTER_CATEGORY" || "CD 💿 PWD" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'CD 💿 PWD' 'cd '\''/etc'\''' '0' 'Marche aussi avec les double quotes
/'

# Test 390: CD 💿 PWD
[[ -z "$FILTER_CATEGORY" || "CD 💿 PWD" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'CD 💿 PWD' 'cd /e'\''tc'\''' '0' '/etc'

# Test 391: CD 💿 PWD
[[ -z "$FILTER_CATEGORY" || "CD 💿 PWD" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'CD 💿 PWD' 'cd /e\"tc\"' '0' '/etc'

# Test 392: CD 💿 PWD
[[ -z "$FILTER_CATEGORY" || "CD 💿 PWD" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'CD 💿 PWD' 'cd sr' '1' ''

# Test 393: CD 💿 PWD
[[ -z "$FILTER_CATEGORY" || "CD 💿 PWD" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'CD 💿 PWD' 'cd Makefile' '1' ''

# Test 394: CD 💿 PWD
[[ -z "$FILTER_CATEGORY" || "CD 💿 PWD" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'CD 💿 PWD' 'cd ../minishell' '0' '/home/vietdu91/42_works/minishell'

# Test 395: CD 💿 PWD
[[ -z "$FILTER_CATEGORY" || "CD 💿 PWD" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'CD 💿 PWD' 'cd ../../../../../../..' '0' '/'

# Test 396: CD 💿 PWD
[[ -z "$FILTER_CATEGORY" || "CD 💿 PWD" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'CD 💿 PWD' 'cd .././../.././../bin/ls' '1' '/home/vietdu91/42_works/minishell'

# Test 397: CD 💿 PWD
[[ -z "$FILTER_CATEGORY" || "CD 💿 PWD" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'CD 💿 PWD' 'cd /' '0' '/'

# Test 398: CD 💿 PWD
[[ -z "$FILTER_CATEGORY" || "CD 💿 PWD" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'CD 💿 PWD' 'cd '\''/'\''' '0' 'Marche aussi avec les double quotes
/'

# Test 399: CD 💿 PWD
[[ -z "$FILTER_CATEGORY" || "CD 💿 PWD" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'CD 💿 PWD' 'cd //
$> pwd' '0' '/'

# Test 400: CD 💿 PWD
[[ -z "$FILTER_CATEGORY" || "CD 💿 PWD" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'CD 💿 PWD' 'cd '\''//'\''
$> pwd' '0' 'Marche aussi avec les double quotes
/'

# Test 401: CD 💿 PWD
[[ -z "$FILTER_CATEGORY" || "CD 💿 PWD" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'CD 💿 PWD' 'cd ///
$> pwd' '0' '/'

# Test 402: CD 💿 PWD
[[ -z "$FILTER_CATEGORY" || "CD 💿 PWD" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'CD 💿 PWD' 'cd ////////
$> pwd' '0' '/'

# Test 403: CD 💿 PWD
[[ -z "$FILTER_CATEGORY" || "CD 💿 PWD" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'CD 💿 PWD' 'cd '\''////////'\''
$> pwd' '0' 'Marche aussi avec les double quotes
/'

# Test 404: CD 💿 PWD
[[ -z "$FILTER_CATEGORY" || "CD 💿 PWD" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'CD 💿 PWD' 'cd /minishell' '1' ''

# Test 405: CD 💿 PWD
[[ -z "$FILTER_CATEGORY" || "CD 💿 PWD" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'CD 💿 PWD' 'cd /
$> cd ..' '0' '/'

# Test 406: CD 💿 PWD
[[ -z "$FILTER_CATEGORY" || "CD 💿 PWD" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'CD 💿 PWD' 'cd _' '1' ''

# Test 407: CD 💿 PWD
[[ -z "$FILTER_CATEGORY" || "CD 💿 PWD" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'CD 💿 PWD' 'cd -' '0' 'Retourne à $OLD_PWD
$OLD_PWD et $PWD sont inversés
/home/vietdu91/42_works/minis'

# Test 408: CD 💿 PWD
[[ -z "$FILTER_CATEGORY" || "CD 💿 PWD" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'CD 💿 PWD' 'cd --' '0' 'Retourne à $HOME
$OLD_PWD et $PWD sont inversés
/home/vietdu91'

# Test 409: CD 💿 PWD
[[ -z "$FILTER_CATEGORY" || "CD 💿 PWD" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'CD 💿 PWD' 'cd ---' '2' ''

# Test 410: CD 💿 PWD
[[ -z "$FILTER_CATEGORY" || "CD 💿 PWD" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'CD 💿 PWD' 'cd $HOME' '0' '/home/vietdu91'

# Test 411: CD 💿 PWD
[[ -z "$FILTER_CATEGORY" || "CD 💿 PWD" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'CD 💿 PWD' 'cd $HOME $HOME' '1' ''

# Test 412: CD 💿 PWD
[[ -z "$FILTER_CATEGORY" || "CD 💿 PWD" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'CD 💿 PWD' 'cd $HOME/42_works' '0' '/home/vietdu91/42_works'

# Test 413: CD 💿 PWD
[[ -z "$FILTER_CATEGORY" || "CD 💿 PWD" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'CD 💿 PWD' 'cd \"$PWD/srcs\"' '0' '/home/vietdu91/42_works/minishell/srcs'

# Test 414: CD 💿 PWD
[[ -z "$FILTER_CATEGORY" || "CD 💿 PWD" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'CD 💿 PWD' 'cd '\''$PWD/srcs'\''' '1' ''

# Test 415: CD 💿 PWD
[[ -z "$FILTER_CATEGORY" || "CD 💿 PWD" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'CD 💿 PWD' 'unset HOME
$> cd $HOME' '1' ''

# Test 416: CD 💿 PWD
[[ -z "$FILTER_CATEGORY" || "CD 💿 PWD" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'CD 💿 PWD' 'unset HOME
$> export HOME=
$> cd' '0' '/home/vietdu91/42_works/minishell'

# Test 417: CD 💿 PWD
[[ -z "$FILTER_CATEGORY" || "CD 💿 PWD" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'CD 💿 PWD' 'unset HOME
$> export HOME
$> cd' '1' ''

# Test 418: CD 💿 PWD
[[ -z "$FILTER_CATEGORY" || "CD 💿 PWD" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'CD 💿 PWD' 'cd minishell Docs crashtest.c' '1' ''

# Test 419: CD 💿 PWD
[[ -z "$FILTER_CATEGORY" || "CD 💿 PWD" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'CD 💿 PWD' '   cd / | echo $?
$> pwd' '0' '/home/vietdu91/42_works/minishell'

# Test 420: CD 💿 PWD
[[ -z "$FILTER_CATEGORY" || "CD 💿 PWD" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'CD 💿 PWD' 'cd ~' '0' '/home/vietdu91'

# Test 421: CD 💿 PWD
[[ -z "$FILTER_CATEGORY" || "CD 💿 PWD" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'CD 💿 PWD' 'cd ~/' '0' '/home/vietdu91'

# Test 422: CD 💿 PWD
[[ -z "$FILTER_CATEGORY" || "CD 💿 PWD" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'CD 💿 PWD' 'cd ~/ | echo $?
$> pwd' '0' '/home/vietdu91/42_works/minishell'

# Test 423: CD 💿 PWD
[[ -z "$FILTER_CATEGORY" || "CD 💿 PWD" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'CD 💿 PWD' 'cd *' '0' '[BONUS] S'\''il n'\''y a qu'\''un seul dossier et rien d'\''autre'

# Test 424: CD 💿 PWD
[[ -z "$FILTER_CATEGORY" || "CD 💿 PWD" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'CD 💿 PWD' 'cd *' '1' '[BONUS] S'\''il n'\''y a qu'\''un seul fichier et rien d'\''autre'

# Test 425: CD 💿 PWD
[[ -z "$FILTER_CATEGORY" || "CD 💿 PWD" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'CD 💿 PWD' 'cd *' '1' '[BONUS] S'\''il y au moins deux éléments'

# Test 426: CD 💿 PWD
[[ -z "$FILTER_CATEGORY" || "CD 💿 PWD" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'CD 💿 PWD' 'mkdir a
$> mkdir a/b
$> cd a/b
$> rm -r ../../a
$> cd ..' '1' ''

# Test 427: CD 💿 PWD
[[ -z "$FILTER_CATEGORY" || "CD 💿 PWD" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'CD 💿 PWD' 'mkdir a
$> mkdir a/b
$> cd a/b
$> rm -r ../../a
$> pwd' '1' ''

# Test 428: CD 💿 PWD
[[ -z "$FILTER_CATEGORY" || "CD 💿 PWD" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'CD 💿 PWD' 'mkdir a
$> mkdir a/b
$> cd a/b
$> rm -r ../../a
$> echo $PWD
$> echo $OLDPWD' '0' ''

# Test 429: CD 💿 PWD
[[ -z "$FILTER_CATEGORY" || "CD 💿 PWD" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'CD 💿 PWD' 'mkdir a
$> mkdir a/b
$> cd a/b
$> rm -r ../../a
$> cd
$> echo $PWD
$> echo $OLDPWD' '0' ''

# Test 430: CD 💿 PWD
[[ -z "$FILTER_CATEGORY" || "CD 💿 PWD" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'CD 💿 PWD' 'mkdir a
$> cd a
$> rm -r ../a
$> echo $PWD
$> echo $OLDPWD' '0' ''

# Test 431: CD 💿 PWD
[[ -z "$FILTER_CATEGORY" || "CD 💿 PWD" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'CD 💿 PWD' 'export CDPATH=/
$> cd $HOME/..' '0' 'A gerer ?
/home'

# Test 432: CD 💿 PWD
[[ -z "$FILTER_CATEGORY" || "CD 💿 PWD" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'CD 💿 PWD' 'export CDPATH=/
$> cd home/vietdu91' '0' 'A gerer ?
/home/vietdu91'

# Test 433: CD 💿 PWD
[[ -z "$FILTER_CATEGORY" || "CD 💿 PWD" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'CD 💿 PWD' 'export CDPATH=./
$> cd .' '0' 'A gerer ?
/home/vietdu91/42_works/minishell'

# Test 434: CD 💿 PWD
[[ -z "$FILTER_CATEGORY" || "CD 💿 PWD" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'CD 💿 PWD' 'export CDPATH=./
$> cd ..' '0' 'A gerer ?
/home/vietdu91/42_works'

# Test 435: BÂTARDS 🖕
[[ -z "$FILTER_CATEGORY" || "BÂTARDS 🖕" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'BÂTARDS 🖕' 'chmod 000 minishell
$> ./minishell' '126' ''

# Test 436: BÂTARDS 🖕
[[ -z "$FILTER_CATEGORY" || "BÂTARDS 🖕" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'BÂTARDS 🖕' 'ls hola' '2' ''

# Test 437: BÂTARDS 🖕
[[ -z "$FILTER_CATEGORY" || "BÂTARDS 🖕" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'BÂTARDS 🖕' './Makefile' '126' ''

# Test 438: BÂTARDS 🖕
[[ -z "$FILTER_CATEGORY" || "BÂTARDS 🖕" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'BÂTARDS 🖕' './minishell' '0' 'Relance le Minishell
Il faut donc 2 fois exit pour exit'

# Test 439: BÂTARDS 🖕
[[ -z "$FILTER_CATEGORY" || "BÂTARDS 🖕" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'BÂTARDS 🖕' 'env | grep SHLVL
$> ./minishell
$> env | grep SHLVL
$> exit
$> env | grep SHLVL' '0' ''

# Test 440: BÂTARDS 🖕
[[ -z "$FILTER_CATEGORY" || "BÂTARDS 🖕" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'BÂTARDS 🖕' 'touch hola
$> ./hola' '126' ''

# Test 441: BÂTARDS 🖕
[[ -z "$FILTER_CATEGORY" || "BÂTARDS 🖕" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'BÂTARDS 🖕' 'env|\"wc\" -l' '0' ''

# Test 442: BÂTARDS 🖕
[[ -z "$FILTER_CATEGORY" || "BÂTARDS 🖕" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'BÂTARDS 🖕' 'env|\"wc \"-l' '127' ''

# Test 443: BÂTARDS 🖕
[[ -z "$FILTER_CATEGORY" || "BÂTARDS 🖕" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'BÂTARDS 🖕' 'expr 1 + 1' '0' ''

# Test 444: BÂTARDS 🖕
[[ -z "$FILTER_CATEGORY" || "BÂTARDS 🖕" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'BÂTARDS 🖕' 'expr $? + $?' '0' 'Fait la somme de la valeur de $?'

# Test 445: BÂTARDS 🖕
[[ -z "$FILTER_CATEGORY" || "BÂTARDS 🖕" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'BÂTARDS 🖕' 'env -i ./minishell
$> env' '0' ''

# Test 446: BÂTARDS 🖕
[[ -z "$FILTER_CATEGORY" || "BÂTARDS 🖕" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'BÂTARDS 🖕' 'env -i ./minishell
$> export' '0' ''

# Test 447: BÂTARDS 🖕
[[ -z "$FILTER_CATEGORY" || "BÂTARDS 🖕" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'BÂTARDS 🖕' 'env -i ./minishell
$> cd' '1' ''

# Test 448: BÂTARDS 🖕
[[ -z "$FILTER_CATEGORY" || "BÂTARDS 🖕" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'BÂTARDS 🖕' 'env -i ./minishell
$> cd ~' '0' '/home/vietdu91'

# Test 449: EXIT  ⛔
[[ -z "$FILTER_CATEGORY" || "EXIT  ⛔" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'EXIT  ⛔' 'exit' '0' ''

# Test 450: EXIT  ⛔
[[ -z "$FILTER_CATEGORY" || "EXIT  ⛔" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'EXIT  ⛔' 'exit exit' '2' ''

# Test 451: EXIT  ⛔
[[ -z "$FILTER_CATEGORY" || "EXIT  ⛔" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'EXIT  ⛔' 'exit hola' '2' ''

# Test 452: EXIT  ⛔
[[ -z "$FILTER_CATEGORY" || "EXIT  ⛔" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'EXIT  ⛔' 'exit hola que tal' '2' ''

# Test 453: EXIT  ⛔
[[ -z "$FILTER_CATEGORY" || "EXIT  ⛔" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'EXIT  ⛔' 'exit 42' '42' ''

# Test 454: EXIT  ⛔
[[ -z "$FILTER_CATEGORY" || "EXIT  ⛔" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'EXIT  ⛔' 'exit 000042' '42' ''

# Test 455: EXIT  ⛔
[[ -z "$FILTER_CATEGORY" || "EXIT  ⛔" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'EXIT  ⛔' 'exit 666' '154' ''

# Test 456: EXIT  ⛔
[[ -z "$FILTER_CATEGORY" || "EXIT  ⛔" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'EXIT  ⛔' 'exit 666 666' '1' ''

# Test 457: EXIT  ⛔
[[ -z "$FILTER_CATEGORY" || "EXIT  ⛔" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'EXIT  ⛔' 'exit -666 666' '1' ''

# Test 458: EXIT  ⛔
[[ -z "$FILTER_CATEGORY" || "EXIT  ⛔" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'EXIT  ⛔' 'exit hola 666' '2' ''

# Test 459: EXIT  ⛔
[[ -z "$FILTER_CATEGORY" || "EXIT  ⛔" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'EXIT  ⛔' 'exit 666 666 666 666' '1' ''

# Test 460: EXIT  ⛔
[[ -z "$FILTER_CATEGORY" || "EXIT  ⛔" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'EXIT  ⛔' 'exit 666 hola 666' '1' ''

# Test 461: EXIT  ⛔
[[ -z "$FILTER_CATEGORY" || "EXIT  ⛔" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'EXIT  ⛔' 'exit hola 666 666' '2' ''

# Test 462: EXIT  ⛔
[[ -z "$FILTER_CATEGORY" || "EXIT  ⛔" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'EXIT  ⛔' 'exit 259' '3' ''

# Test 463: EXIT  ⛔
[[ -z "$FILTER_CATEGORY" || "EXIT  ⛔" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'EXIT  ⛔' 'exit -4' '252' ''

# Test 464: EXIT  ⛔
[[ -z "$FILTER_CATEGORY" || "EXIT  ⛔" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'EXIT  ⛔' 'exit -42' '214' ''

# Test 465: EXIT  ⛔
[[ -z "$FILTER_CATEGORY" || "EXIT  ⛔" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'EXIT  ⛔' 'exit -0000042' '214' ''

# Test 466: EXIT  ⛔
[[ -z "$FILTER_CATEGORY" || "EXIT  ⛔" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'EXIT  ⛔' 'exit -259' '253' ''

# Test 467: EXIT  ⛔
[[ -z "$FILTER_CATEGORY" || "EXIT  ⛔" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'EXIT  ⛔' 'exit -666' '102' ''

# Test 468: EXIT  ⛔
[[ -z "$FILTER_CATEGORY" || "EXIT  ⛔" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'EXIT  ⛔' 'exit +666' '154' ''

# Test 469: EXIT  ⛔
[[ -z "$FILTER_CATEGORY" || "EXIT  ⛔" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'EXIT  ⛔' 'exit 0' '0' ''

# Test 470: EXIT  ⛔
[[ -z "$FILTER_CATEGORY" || "EXIT  ⛔" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'EXIT  ⛔' 'exit +0' '0' ''

# Test 471: EXIT  ⛔
[[ -z "$FILTER_CATEGORY" || "EXIT  ⛔" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'EXIT  ⛔' 'exit -0' '0' ''

# Test 472: EXIT  ⛔
[[ -z "$FILTER_CATEGORY" || "EXIT  ⛔" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'EXIT  ⛔' 'exit +42' '42' ''

# Test 473: EXIT  ⛔
[[ -z "$FILTER_CATEGORY" || "EXIT  ⛔" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'EXIT  ⛔' 'exit -69 -96' '1' ''

# Test 474: EXIT  ⛔
[[ -z "$FILTER_CATEGORY" || "EXIT  ⛔" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'EXIT  ⛔' 'exit --666' '2' ''

# Test 475: EXIT  ⛔
[[ -z "$FILTER_CATEGORY" || "EXIT  ⛔" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'EXIT  ⛔' 'exit ++++666' '2' ''

# Test 476: EXIT  ⛔
[[ -z "$FILTER_CATEGORY" || "EXIT  ⛔" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'EXIT  ⛔' 'exit ++++++0' '2' ''

# Test 477: EXIT  ⛔
[[ -z "$FILTER_CATEGORY" || "EXIT  ⛔" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'EXIT  ⛔' 'exit ------0' '2' ''

# Test 478: EXIT  ⛔
[[ -z "$FILTER_CATEGORY" || "EXIT  ⛔" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'EXIT  ⛔' 'exit \"666\"' '154' ''

# Test 479: EXIT  ⛔
[[ -z "$FILTER_CATEGORY" || "EXIT  ⛔" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'EXIT  ⛔' 'exit '\''666'\''' '154' ''

# Test 480: EXIT  ⛔
[[ -z "$FILTER_CATEGORY" || "EXIT  ⛔" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'EXIT  ⛔' 'exit '\''-666'\''' '102' 'Marche aussi pour les double quotes'

# Test 481: EXIT  ⛔
[[ -z "$FILTER_CATEGORY" || "EXIT  ⛔" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'EXIT  ⛔' 'exit '\''+666'\''' '154' 'Marche aussi pour les double quotes'

# Test 482: EXIT  ⛔
[[ -z "$FILTER_CATEGORY" || "EXIT  ⛔" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'EXIT  ⛔' 'exit '\''----666'\''' '2' 'Marche aussi pour les double quotes'

# Test 483: EXIT  ⛔
[[ -z "$FILTER_CATEGORY" || "EXIT  ⛔" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'EXIT  ⛔' 'exit '\''++++666'\''' '2' 'Marche aussi pour les double quotes'

# Test 484: EXIT  ⛔
[[ -z "$FILTER_CATEGORY" || "EXIT  ⛔" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'EXIT  ⛔' 'exit '\''6'\''66' '154' 'Marche aussi pour les double quotes'

# Test 485: EXIT  ⛔
[[ -z "$FILTER_CATEGORY" || "EXIT  ⛔" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'EXIT  ⛔' 'exit '\''2'\''66'\''32'\''' '8' 'Marche aussi pour les double quotes'

# Test 486: EXIT  ⛔
[[ -z "$FILTER_CATEGORY" || "EXIT  ⛔" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'EXIT  ⛔' 'exit \"'\''666'\''\"' '2' ''

# Test 487: EXIT  ⛔
[[ -z "$FILTER_CATEGORY" || "EXIT  ⛔" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'EXIT  ⛔' 'exit '\''\"666\"'\''' '2' ''

# Test 488: EXIT  ⛔
[[ -z "$FILTER_CATEGORY" || "EXIT  ⛔" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'EXIT  ⛔' 'exit '\''666'\''\"666\"666' '170' ''

# Test 489: EXIT  ⛔
[[ -z "$FILTER_CATEGORY" || "EXIT  ⛔" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'EXIT  ⛔' 'exit +'\''666'\''\"666\"666' '170' ''

# Test 490: EXIT  ⛔
[[ -z "$FILTER_CATEGORY" || "EXIT  ⛔" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'EXIT  ⛔' 'exit -'\''666'\''\"666\"666' '86' ''

# Test 491: EXIT  ⛔
[[ -z "$FILTER_CATEGORY" || "EXIT  ⛔" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'EXIT  ⛔' 'exit 9223372036854775807' '255' ''

# Test 492: EXIT  ⛔
[[ -z "$FILTER_CATEGORY" || "EXIT  ⛔" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'EXIT  ⛔' 'exit 9223372036854775808' '2' ''

# Test 493: EXIT  ⛔
[[ -z "$FILTER_CATEGORY" || "EXIT  ⛔" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'EXIT  ⛔' 'exit -9223372036854775808' '0' ''

# Test 494: EXIT  ⛔
[[ -z "$FILTER_CATEGORY" || "EXIT  ⛔" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'EXIT  ⛔' 'exit -9223372036854775809' '2' ''

# Test 495: PIPES 🚬
[[ -z "$FILTER_CATEGORY" || "PIPES 🚬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'PIPES 🚬' 'cat | cat | cat | ls' '0' 'Apparaît la ligne ls
Et 3 retours à la ligne avec la touche Entrée'

# Test 496: PIPES 🚬
[[ -z "$FILTER_CATEGORY" || "PIPES 🚬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'PIPES 🚬' 'ls | exit' '0' 'Ne fait rien

Chaque commande d'\''un pipeline est exécutée dans son propre sous'

# Test 497: PIPES 🚬
[[ -z "$FILTER_CATEGORY" || "PIPES 🚬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'PIPES 🚬' 'ls | exit 42' '42' 'Ne fait rien'

# Test 498: PIPES 🚬
[[ -z "$FILTER_CATEGORY" || "PIPES 🚬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'PIPES 🚬' 'exit | ls' '0' ''

# Test 499: PIPES 🚬
[[ -z "$FILTER_CATEGORY" || "PIPES 🚬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'PIPES 🚬' 'echo hola > bonjour
$> exit | cat -e bonjour' '0' ''

# Test 500: PIPES 🚬
[[ -z "$FILTER_CATEGORY" || "PIPES 🚬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'PIPES 🚬' 'echo hola > bonjour
$> cat -e bonjour | exit' '0' ''

# Test 501: PIPES 🚬
[[ -z "$FILTER_CATEGORY" || "PIPES 🚬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'PIPES 🚬' 'echo | echo' '0' ''

# Test 502: PIPES 🚬
[[ -z "$FILTER_CATEGORY" || "PIPES 🚬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'PIPES 🚬' 'echo hola | echo que tal' '0' ''

# Test 503: PIPES 🚬
[[ -z "$FILTER_CATEGORY" || "PIPES 🚬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'PIPES 🚬' 'pwd | echo hola' '0' ''

# Test 504: PIPES 🚬
[[ -z "$FILTER_CATEGORY" || "PIPES 🚬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'PIPES 🚬' 'env | echo hola' '0' ''

# Test 505: PIPES 🚬
[[ -z "$FILTER_CATEGORY" || "PIPES 🚬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'PIPES 🚬' 'echo oui | cat -e' '0' ''

# Test 506: PIPES 🚬
[[ -z "$FILTER_CATEGORY" || "PIPES 🚬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'PIPES 🚬' 'echo oui | echo non | echo hola | grep oui' '0' ''

# Test 507: PIPES 🚬
[[ -z "$FILTER_CATEGORY" || "PIPES 🚬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'PIPES 🚬' 'echo oui | echo non | echo hola | grep non' '0' ''

# Test 508: PIPES 🚬
[[ -z "$FILTER_CATEGORY" || "PIPES 🚬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'PIPES 🚬' 'echo oui | echo non | echo hola | grep hola' '0' ''

# Test 509: PIPES 🚬
[[ -z "$FILTER_CATEGORY" || "PIPES 🚬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'PIPES 🚬' 'echo hola | cat -e | cat -e | cat -e' '0' ''

# Test 510: PIPES 🚬
[[ -z "$FILTER_CATEGORY" || "PIPES 🚬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'PIPES 🚬' 'cd .. | echo \"hola\"' '0' '/home/vietdu91/42_works/minishell'

# Test 511: PIPES 🚬
[[ -z "$FILTER_CATEGORY" || "PIPES 🚬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'PIPES 🚬' 'cd / | echo \"hola\"' '0' '/home/vietdu91/42_works/minishell'

# Test 512: PIPES 🚬
[[ -z "$FILTER_CATEGORY" || "PIPES 🚬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'PIPES 🚬' 'cd .. | pwd' '0' '/home/vietdu91/42_works/minishell'

# Test 513: PIPES 🚬
[[ -z "$FILTER_CATEGORY" || "PIPES 🚬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'PIPES 🚬' 'ifconfig | grep \":\"' '0' ''

# Test 514: PIPES 🚬
[[ -z "$FILTER_CATEGORY" || "PIPES 🚬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'PIPES 🚬' 'ifconfig | grep hola' '1' ''

# Test 515: PIPES 🚬
[[ -z "$FILTER_CATEGORY" || "PIPES 🚬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'PIPES 🚬' 'whoami | grep $USER' '0' ''

# Test 516: PIPES 🚬
[[ -z "$FILTER_CATEGORY" || "PIPES 🚬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'PIPES 🚬' 'whoami | grep $USER > /tmp/bonjour
$> cat /tmp/bonjour' '0' ''

# Test 517: PIPES 🚬
[[ -z "$FILTER_CATEGORY" || "PIPES 🚬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'PIPES 🚬' 'whoami | cat -e | cat -e > /tmp/bonjour
$> cat /tmp/bonjour' '0' ''

# Test 518: PIPES 🚬
[[ -z "$FILTER_CATEGORY" || "PIPES 🚬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'PIPES 🚬' 'whereis ls | cat -e | cat -e > /tmp/bonjour
$> cat /tmp/bonjour' '0' ''

# Test 519: PIPES 🚬
[[ -z "$FILTER_CATEGORY" || "PIPES 🚬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'PIPES 🚬' 'ls | hola' '127' ''

# Test 520: PIPES 🚬
[[ -z "$FILTER_CATEGORY" || "PIPES 🚬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'PIPES 🚬' 'ls | ls hola' '2' ''

# Test 521: PIPES 🚬
[[ -z "$FILTER_CATEGORY" || "PIPES 🚬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'PIPES 🚬' 'ls | ls | hola' '127' ''

# Test 522: PIPES 🚬
[[ -z "$FILTER_CATEGORY" || "PIPES 🚬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'PIPES 🚬' 'ls | hola | ls' '0' ''

# Test 523: PIPES 🚬
[[ -z "$FILTER_CATEGORY" || "PIPES 🚬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'PIPES 🚬' 'ls | ls | hola | rev' '0' ''

# Test 524: PIPES 🚬
[[ -z "$FILTER_CATEGORY" || "PIPES 🚬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'PIPES 🚬' 'ls | ls | echo hola | rev' '0' ''

# Test 525: PIPES 🚬
[[ -z "$FILTER_CATEGORY" || "PIPES 🚬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'PIPES 🚬' 'ls -la | grep \".\"' '0' 'Sort la commande entiere de ls -la'

# Test 526: PIPES 🚬
[[ -z "$FILTER_CATEGORY" || "PIPES 🚬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'PIPES 🚬' 'ls -la | grep \"'\''.'\''\"' '0' ''

# Test 527: PIPES 🚬
[[ -z "$FILTER_CATEGORY" || "PIPES 🚬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'PIPES 🚬' 'echo test.c | cat -e| cat -e| cat -e| cat -e| cat -e| cat -e| cat -e| cat -e|cat -e|cat -e|cat -e' '0' ''

# Test 528: PIPES 🚬
[[ -z "$FILTER_CATEGORY" || "PIPES 🚬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'PIPES 🚬' 'ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls
|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls' '0' ''

# Test 529: PIPES 🚬
[[ -z "$FILTER_CATEGORY" || "PIPES 🚬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'PIPES 🚬' 'echo hola | cat | cat | cat | cat | cat | grep hola' '0' ''

# Test 530: PIPES 🚬
[[ -z "$FILTER_CATEGORY" || "PIPES 🚬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'PIPES 🚬' 'echo hola | cat' '0' ''

# Test 531: PIPES 🚬
[[ -z "$FILTER_CATEGORY" || "PIPES 🚬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'PIPES 🚬' 'echo hola| cat' '0' ''

# Test 532: PIPES 🚬
[[ -z "$FILTER_CATEGORY" || "PIPES 🚬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'PIPES 🚬' 'echo hola |cat' '0' ''

# Test 533: PIPES 🚬
[[ -z "$FILTER_CATEGORY" || "PIPES 🚬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'PIPES 🚬' 'echo hola|cat' '0' ''

# Test 534: PIPES 🚬
[[ -z "$FILTER_CATEGORY" || "PIPES 🚬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'PIPES 🚬' 'echo hola || cat' '0' '[BONUS]'

# Test 535: PIPES 🚬
[[ -z "$FILTER_CATEGORY" || "PIPES 🚬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'PIPES 🚬' 'echo hola ||| cat' '2' ''

# Test 536: PIPES 🚬
[[ -z "$FILTER_CATEGORY" || "PIPES 🚬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'PIPES 🚬' 'ech|o hola | cat' '127' ''

# Test 537: PIPES 🚬
[[ -z "$FILTER_CATEGORY" || "PIPES 🚬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'PIPES 🚬' 'cat Makefile | cat -e | cat -e' '0' ''

# Test 538: PIPES 🚬
[[ -z "$FILTER_CATEGORY" || "PIPES 🚬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'PIPES 🚬' 'cat Makefile | grep srcs | cat -e' '0' ''

# Test 539: PIPES 🚬
[[ -z "$FILTER_CATEGORY" || "PIPES 🚬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'PIPES 🚬' 'cat Makefile | grep srcs | grep srcs | cat -e' '0' ''

# Test 540: PIPES 🚬
[[ -z "$FILTER_CATEGORY" || "PIPES 🚬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'PIPES 🚬' 'cat Makefile | grep pr | head -n 5 | cd file_not_exist' '1' ''

# Test 541: PIPES 🚬
[[ -z "$FILTER_CATEGORY" || "PIPES 🚬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'PIPES 🚬' 'cat Makefile | grep pr | head -n 5 | hello' '127' ''

# Test 542: PIPES 🚬
[[ -z "$FILTER_CATEGORY" || "PIPES 🚬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'PIPES 🚬' 'export HOLA=bonjour | cat -e | cat -e' '0' ''

# Test 543: PIPES 🚬
[[ -z "$FILTER_CATEGORY" || "PIPES 🚬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'PIPES 🚬' 'unset HOLA | cat -e' '0' ''

# Test 544: PIPES 🚬
[[ -z "$FILTER_CATEGORY" || "PIPES 🚬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'PIPES 🚬' 'export HOLA | echo hola
$> env | grep PROUT' '0' ''

# Test 545: PIPES 🚬
[[ -z "$FILTER_CATEGORY" || "PIPES 🚬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'PIPES 🚬' 'export | echo hola' '0' ''

# Test 546: PIPES 🚬
[[ -z "$FILTER_CATEGORY" || "PIPES 🚬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'PIPES 🚬' 'sleep 3 | sleep 3' '0' 'Le prompt apparait au bout de 3 secondes'

# Test 547: PIPES 🚬
[[ -z "$FILTER_CATEGORY" || "PIPES 🚬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'PIPES 🚬' 'time sleep 3 | sleep 3' '0' 'Le prompt apparait au bout de 3 secondes'

# Test 548: PIPES 🚬
[[ -z "$FILTER_CATEGORY" || "PIPES 🚬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'PIPES 🚬' 'sleep 3 | exit' '0' 'Le prompt apparait au bout de 3 secondes'

# Test 549: PIPES 🚬
[[ -z "$FILTER_CATEGORY" || "PIPES 🚬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'PIPES 🚬' 'exit | sleep 3' '0' 'Le prompt apparait au bout de 3 secondes'

# Test 550: PIPES 🚬
[[ -z "$FILTER_CATEGORY" || "PIPES 🚬" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'PIPES 🚬' 'echo hola > a
$> >>b echo que tal
$> cat a | <b cat | cat > c | cat' '0' ''

# Test 551: &&  🍒  ||
[[ -z "$FILTER_CATEGORY" || "&&  🍒  ||" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '&&  🍒  ||' 'pwd && ls' '0' '[BONUS]'

# Test 552: &&  🍒  ||
[[ -z "$FILTER_CATEGORY" || "&&  🍒  ||" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '&&  🍒  ||' 'pwd || ls' '0' '[BONUS]'

# Test 553: &&  🍒  ||
[[ -z "$FILTER_CATEGORY" || "&&  🍒  ||" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '&&  🍒  ||' 'echo hola || echo bonjour' '0' '[BONUS]'

# Test 554: &&  🍒  ||
[[ -z "$FILTER_CATEGORY" || "&&  🍒  ||" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '&&  🍒  ||' 'echo hola && echo bonjour' '0' '[BONUS]'

# Test 555: &&  🍒  ||
[[ -z "$FILTER_CATEGORY" || "&&  🍒  ||" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '&&  🍒  ||' 'echo bonjour || echo hola' '0' '[BONUS]'

# Test 556: &&  🍒  ||
[[ -z "$FILTER_CATEGORY" || "&&  🍒  ||" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '&&  🍒  ||' 'echo bonjour && echo hola' '0' '[BONUS]'

# Test 557: &&  🍒  ||
[[ -z "$FILTER_CATEGORY" || "&&  🍒  ||" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '&&  🍒  ||' 'echo -n bonjour && echo -n hola' '0' '[BONUS]'

# Test 558: &&  🍒  ||
[[ -z "$FILTER_CATEGORY" || "&&  🍒  ||" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '&&  🍒  ||' 'pwd && ls && echo hola' '0' '[BONUS]'

# Test 559: &&  🍒  ||
[[ -z "$FILTER_CATEGORY" || "&&  🍒  ||" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '&&  🍒  ||' 'pwd || ls && echo hola' '0' '[BONUS]'

# Test 560: &&  🍒  ||
[[ -z "$FILTER_CATEGORY" || "&&  🍒  ||" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '&&  🍒  ||' 'pwd && ls || echo hola' '0' '[BONUS]'

# Test 561: &&  🍒  ||
[[ -z "$FILTER_CATEGORY" || "&&  🍒  ||" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '&&  🍒  ||' 'pwd || ls || echo hola' '0' '[BONUS]'

# Test 562: &&  🍒  ||
[[ -z "$FILTER_CATEGORY" || "&&  🍒  ||" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '&&  🍒  ||' 'ls || export \"\"' '0' '[BONUS]'

# Test 563: &&  🍒  ||
[[ -z "$FILTER_CATEGORY" || "&&  🍒  ||" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '&&  🍒  ||' 'export \"\" || ls' '0' '[BONUS]'

# Test 564: &&  🍒  ||
[[ -z "$FILTER_CATEGORY" || "&&  🍒  ||" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '&&  🍒  ||' 'ls && export \"\"' '1' '[BONUS]'

# Test 565: &&  🍒  ||
[[ -z "$FILTER_CATEGORY" || "&&  🍒  ||" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '&&  🍒  ||' 'export \"\" && ls' '1' '[BONUS]'

# Test 566: &&  🍒  ||
[[ -z "$FILTER_CATEGORY" || "&&  🍒  ||" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '&&  🍒  ||' 'ls || ;' '2' '[BONUS] Marche pour les metacharacters |&;()'

# Test 567: &&  🍒  ||
[[ -z "$FILTER_CATEGORY" || "&&  🍒  ||" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '&&  🍒  ||' '; || ls' '2' '[BONUS] Marche pour les metacharacters |&;()'

# Test 568: &&  🍒  ||
[[ -z "$FILTER_CATEGORY" || "&&  🍒  ||" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '&&  🍒  ||' 'ls && ;' '2' '[BONUS] Marche pour les metacharacters |&;()'

# Test 569: &&  🍒  ||
[[ -z "$FILTER_CATEGORY" || "&&  🍒  ||" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '&&  🍒  ||' '; && ls' '2' '[BONUS] Marche pour les metacharacters |&;()'

# Test 570: &&  🍒  ||
[[ -z "$FILTER_CATEGORY" || "&&  🍒  ||" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '&&  🍒  ||' 'ls || <' '2' '[BONUS] Marche pour les metacharacters <>'

# Test 571: &&  🍒  ||
[[ -z "$FILTER_CATEGORY" || "&&  🍒  ||" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '&&  🍒  ||' 'ls && <' '2' '[BONUS] Marche pour les metacharacters <>'

# Test 572: &&  🍒  ||
[[ -z "$FILTER_CATEGORY" || "&&  🍒  ||" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '&&  🍒  ||' 'cat | echo || ls' '0' '[BONUS]'

# Test 573: &&  🍒  ||
[[ -z "$FILTER_CATEGORY" || "&&  🍒  ||" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '&&  🍒  ||' 'cat | echo && ls' '0' '[BONUS]'

# Test 574: &&  🍒  ||
[[ -z "$FILTER_CATEGORY" || "&&  🍒  ||" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '&&  🍒  ||' 'ls || cat | echo' '0' '[BONUS]'

# Test 575: &&  🍒  ||
[[ -z "$FILTER_CATEGORY" || "&&  🍒  ||" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '&&  🍒  ||' 'ls && cat | echo' '0' '[BONUS]'

# Test 576: &&  🍒  ||
[[ -z "$FILTER_CATEGORY" || "&&  🍒  ||" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '&&  🍒  ||' 'export \"\" && unset \"\"' '1' '[BONUS]'

# Test 577: ( PARENTHESES )
[[ -z "$FILTER_CATEGORY" || "( PARENTHESES )" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '( PARENTHESES )' '(ls)' '0' '[BONUS]'

# Test 578: ( PARENTHESES )
[[ -z "$FILTER_CATEGORY" || "( PARENTHESES )" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '( PARENTHESES )' '( ( ls ) )' '0' '[BONUS]'

# Test 579: ( PARENTHESES )
[[ -z "$FILTER_CATEGORY" || "( PARENTHESES )" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '( PARENTHESES )' '( ( ) ls )' '2' '[BONUS]'

# Test 580: ( PARENTHESES )
[[ -z "$FILTER_CATEGORY" || "( PARENTHESES )" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '( PARENTHESES )' 'ls && (ls)' '0' '[BONUS]'

# Test 581: ( PARENTHESES )
[[ -z "$FILTER_CATEGORY" || "( PARENTHESES )" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '( PARENTHESES )' '(ls && pwd)' '0' '[BONUS]'

# Test 582: ( PARENTHESES )
[[ -z "$FILTER_CATEGORY" || "( PARENTHESES )" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '( PARENTHESES )' '( ( ls&&pwd ) )' '0' '[BONUS]'

# Test 583: ( PARENTHESES )
[[ -z "$FILTER_CATEGORY" || "( PARENTHESES )" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '( PARENTHESES )' '( ( ls ) &&pwd )' '0' '[BONUS]'

# Test 584: ( PARENTHESES )
[[ -z "$FILTER_CATEGORY" || "( PARENTHESES )" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '( PARENTHESES )' '(ls && ( ( pwd ) ) )' '0' '[BONUS]'

# Test 585: ( PARENTHESES )
[[ -z "$FILTER_CATEGORY" || "( PARENTHESES )" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '( PARENTHESES )' '(ls && pwd) > hola
$> cat hola' '0' '[BONUS]'

# Test 586: ( PARENTHESES )
[[ -z "$FILTER_CATEGORY" || "( PARENTHESES )" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '( PARENTHESES )' '> hola ls && pwd' '0' '[BONUS]'

# Test 587: ( PARENTHESES )
[[ -z "$FILTER_CATEGORY" || "( PARENTHESES )" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '( PARENTHESES )' '> hola (ls && pwd)' '2' '[BONUS]'

# Test 588: ( PARENTHESES )
[[ -z "$FILTER_CATEGORY" || "( PARENTHESES )" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '( PARENTHESES )' '(> pwd)
$> ls' '0' '[BONUS]'

# Test 589: ( PARENTHESES )
[[ -z "$FILTER_CATEGORY" || "( PARENTHESES )" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '( PARENTHESES )' '(< pwd)
$> ls' '0' '[BONUS] Si pwd existe'

# Test 590: ( PARENTHESES )
[[ -z "$FILTER_CATEGORY" || "( PARENTHESES )" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '( PARENTHESES )' '(< pwd)' '1' '[BONUS] Si pwd n'\''existe pas'

# Test 591: ( PARENTHESES )
[[ -z "$FILTER_CATEGORY" || "( PARENTHESES )" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '( PARENTHESES )' '( ( ( ( ( pwd) ) ) ) )' '0' '[BONUS]'

# Test 592: ( PARENTHESES )
[[ -z "$FILTER_CATEGORY" || "( PARENTHESES )" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '( PARENTHESES )' '() pwd' '2' '[BONUS]'

# Test 593: ( PARENTHESES )
[[ -z "$FILTER_CATEGORY" || "( PARENTHESES )" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '( PARENTHESES )' '> pwd (ls)' '2' '[BONUS]'

# Test 594: ( PARENTHESES )
[[ -z "$FILTER_CATEGORY" || "( PARENTHESES )" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '( PARENTHESES )' '(ls||pwd)&&(ls||pwd)' '0' '[BONUS]'

# Test 595: ( PARENTHESES )
[[ -z "$FILTER_CATEGORY" || "( PARENTHESES )" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '( PARENTHESES )' '(lss||pwd)&&(lss||pwd)' '0' '[BONUS]'

# Test 596: ( PARENTHESES )
[[ -z "$FILTER_CATEGORY" || "( PARENTHESES )" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '( PARENTHESES )' '(lss&&pwd)&&(lss&&pwd)' '127' '[BONUS]'

# Test 597: ( PARENTHESES )
[[ -z "$FILTER_CATEGORY" || "( PARENTHESES )" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '( PARENTHESES )' '(ls && pwd | wc) > hola
$> cat hola' '0' '[BONUS]'

# Test 598: ( PARENTHESES )
[[ -z "$FILTER_CATEGORY" || "( PARENTHESES )" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '( PARENTHESES )' '(ls && pwd | wc) > hola
$> (ls && pwd | wc) > hola
$> cat hola' '0' '[BONUS]'

# Test 599: ( PARENTHESES )
[[ -z "$FILTER_CATEGORY" || "( PARENTHESES )" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '( PARENTHESES )' '(ls && pwd | wc) >> hola
$> echo hey&&(ls && pwd | wc) > hola
$> cat hola' '0' '[BONUS]'

# Test 600: ( PARENTHESES )
[[ -z "$FILTER_CATEGORY" || "( PARENTHESES )" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '( PARENTHESES )' '(pwd | wc) < hola' '0' '[BONUS]'

# Test 601: ( PARENTHESES )
[[ -z "$FILTER_CATEGORY" || "( PARENTHESES )" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '( PARENTHESES )' '(ls && pwd | wc) < hola' '0' '[BONUS]'

# Test 602: ( PARENTHESES )
[[ -z "$FILTER_CATEGORY" || "( PARENTHESES )" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '( PARENTHESES )' '(ls -z || pwd | wc) < hola' '0' '[BONUS]'

# Test 603: ( PARENTHESES )
[[ -z "$FILTER_CATEGORY" || "( PARENTHESES )" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '( PARENTHESES )' 'echo hey > hola
$> (pwd | wc) < hola' '0' '[BONUS]'

# Test 604: ( PARENTHESES )
[[ -z "$FILTER_CATEGORY" || "( PARENTHESES )" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '( PARENTHESES )' 'echo hey > hola
$> (ls && pwd | wc) < hola' '0' '[BONUS]'

# Test 605: ( PARENTHESES )
[[ -z "$FILTER_CATEGORY" || "( PARENTHESES )" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '( PARENTHESES )' 'echo hey > hola
$> (ls -z || pwd | wc) < hola' '0' '[BONUS]'

# Test 606: ( PARENTHESES )
[[ -z "$FILTER_CATEGORY" || "( PARENTHESES )" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '( PARENTHESES )' '(ls -z || pwd && ls)' '0' '[BONUS]'

# Test 607: ( PARENTHESES )
[[ -z "$FILTER_CATEGORY" || "( PARENTHESES )" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '( PARENTHESES )' 'ls || (cat Makefile|grep srcs) && (pwd|wc)' '0' '[BONUS]'

# Test 608: ( PARENTHESES )
[[ -z "$FILTER_CATEGORY" || "( PARENTHESES )" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '( PARENTHESES )' 'ls -z && (ls) && (pwd)' '130' '[BONUS]'

# Test 609: ( PARENTHESES )
[[ -z "$FILTER_CATEGORY" || "( PARENTHESES )" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '( PARENTHESES )' '(ls > Docs/hey && pwd) > hola
$> cat hola
$> cat Docs/hey' '0' '[BONUS]'

# Test 610: ( PARENTHESES )
[[ -z "$FILTER_CATEGORY" || "( PARENTHESES )" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '( PARENTHESES )' 'ls > Docs/hey && pwd > hola
$> cat hola
$> cat Docs/hey' '0' '[BONUS]'

# Test 611: ( PARENTHESES )
[[ -z "$FILTER_CATEGORY" || "( PARENTHESES )" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '( PARENTHESES )' 'cd ../.. && pwd && pwd' '0' '[BONUS]'

# Test 612: ( PARENTHESES )
[[ -z "$FILTER_CATEGORY" || "( PARENTHESES )" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '( PARENTHESES )' '(cd ../.. && pwd) && pwd' '0' '[BONUS]'

# Test 613: ( PARENTHESES )
[[ -z "$FILTER_CATEGORY" || "( PARENTHESES )" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '( PARENTHESES )' 'ls -z || cd ../../..&&pwd
$> pwd' '0' '[BONUS]'

# Test 614: ( PARENTHESES )
[[ -z "$FILTER_CATEGORY" || "( PARENTHESES )" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '( PARENTHESES )' 'ls -z || (cd ../../..&&pwd)
$> pwd' '0' '[BONUS]'

# Test 615: << << << << << << << << << << << << << <
[[ -z "$FILTER_CATEGORY" || "<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>' 'echo hola > bonjour
$> cat bonjour' '0' ''

# Test 616: << << << << << << << << << << << << << <
[[ -z "$FILTER_CATEGORY" || "<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>' 'echo que tal >> bonjour
$> cat bonjour' '0' ''

# Test 617: << << << << << << << << << << << << << <
[[ -z "$FILTER_CATEGORY" || "<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>' 'echo hola > bonjour
$> echo que tal >> bonjour
$> cat < bonjour' '0' ''

# Test 618: << << << << << << << << << << << << << <
[[ -z "$FILTER_CATEGORY" || "<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>' 'echo hola > bonjour
$> rm bonjour
$> echo que tal >> bonjour
$> cat < bonjour' '0' ''

# Test 619: << << << << << << << << << << << << << <
[[ -z "$FILTER_CATEGORY" || "<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>' 'echo hola que tal > bonjour
$> cat bonjour' '0' ''

# Test 620: << << << << << << << << << << << << << <
[[ -z "$FILTER_CATEGORY" || "<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>' 'echo hola que tal > /tmp/bonjour
$> cat -e /tmp/bonjour' '0' ''

# Test 621: << << << << << << << << << << << << << <
[[ -z "$FILTER_CATEGORY" || "<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>' 'export HOLA=hey
$> echo bonjour > $HOLA
$> echo $HOLA' '0' 'Ne fait rien'

# Test 622: << << << << << << << << << << << << << <
[[ -z "$FILTER_CATEGORY" || "<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>' 'whereis grep > Docs/bonjour
$> cat Docs/bonjour' '0' ''

# Test 623: << << << << << << << << << << << << << <
[[ -z "$FILTER_CATEGORY" || "<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>' 'ls -la > Docs/bonjour
$> cat Docs/bonjour' '0' ''

# Test 624: << << << << << << << << << << << << << <
[[ -z "$FILTER_CATEGORY" || "<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>' 'pwd>bonjour
$> cat bonjour' '0' ''

# Test 625: << << << << << << << << << << << << << <
[[ -z "$FILTER_CATEGORY" || "<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>' 'pwd >                     bonjour
$> cat bonjour' '0' ''

# Test 626: << << << << << << << << << << << << << <
[[ -z "$FILTER_CATEGORY" || "<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>' 'echo hola > > bonjour' '2' ''

# Test 627: << << << << << << << << << << << << << <
[[ -z "$FILTER_CATEGORY" || "<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>' 'echo hola < < bonjour' '2' ''

# Test 628: << << << << << << << << << << << << << <
[[ -z "$FILTER_CATEGORY" || "<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>' 'echo hola >>> bonjour' '2' ''

# Test 629: << << << << << << << << << << << << << <
[[ -z "$FILTER_CATEGORY" || "<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>' '> bonjour echo hola
$> cat bonjour' '0' ''

# Test 630: << << << << << << << << << << << << << <
[[ -z "$FILTER_CATEGORY" || "<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>' '> bonjour | echo hola
$> cat bonjour' '0' ''

# Test 631: << << << << << << << << << << << << << <
[[ -z "$FILTER_CATEGORY" || "<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>' 'prout hola > bonjour
$> ls' '127' 'Erreur mais file \"bonjour\" cree tout de meme'

# Test 632: << << << << << << << << << << << << << <
[[ -z "$FILTER_CATEGORY" || "<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>' 'echo hola > hello >> hello >> hello
$> ls
$> cat hello' '0' ''

# Test 633: << << << << << << << << << << << << << <
[[ -z "$FILTER_CATEGORY" || "<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>' 'echo hola > hello >> hello >> hello
$> echo hola >> hello
$> cat < hello' '0' ''

# Test 634: << << << << << << << << << << << << << <
[[ -z "$FILTER_CATEGORY" || "<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>' 'echo hola > hello >> hello >> hello
$> echo hola >> hello
$> echo hola > hello >> hello >> hello
$> cat < hello' '0' ''

# Test 635: << << << << << << << << << << << << << <
[[ -z "$FILTER_CATEGORY" || "<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>' 'echo hola >> hello >> hello > hello
$> echo hola >> hello
$> cat < hello' '0' ''

# Test 636: << << << << << << << << << << << << << <
[[ -z "$FILTER_CATEGORY" || "<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>' 'echo hola >> hello >> hello > hello
$> echo hola >> hello
$> echo hola >> hello >> hello > hello
$> cat < hello' '0' ''

# Test 637: << << << << << << << << << << << << << <
[[ -z "$FILTER_CATEGORY" || "<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>' 'echo hola > hello
$> echo hola >> hello >> hello >> hello
$> echo hola >> hello
$> cat < hello' '0' ''

# Test 638: << << << << << << << << << << << << << <
[[ -z "$FILTER_CATEGORY" || "<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>' 'echo hola > hello
$> echo hey > bonjour
$> echo <bonjour <hello' '0' ''

# Test 639: << << << << << << << << << << << << << <
[[ -z "$FILTER_CATEGORY" || "<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>' 'echo hola > hello
$> echo hey > bonjour
$> echo <hello <bonjour' '0' ''

# Test 640: << << << << << << << << << << << << << <
[[ -z "$FILTER_CATEGORY" || "<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>' 'echo hola > bonjour
$> echo hey > hello
$> rm bonjour hello
$> echo hola > bonjour > hello > bonjour
$> cat bonjour
$> cat hello' '0' ''

# Test 641: << << << << << << << << << << << << << <
[[ -z "$FILTER_CATEGORY" || "<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>' 'echo hola > bonjour
$> echo hey > hello
$> echo hola > bonjour > hello > bonjour
$> cat bonjour
$> cat hello' '0' ''

# Test 642: << << << << << << << << << << << << << <
[[ -z "$FILTER_CATEGORY" || "<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>' 'echo hola > bonjour
$> echo hey > hello
$> rm bonjour hello
$> echo hola > bonjour >> hello > bonjour
$> cat bonjour
$> cat hello' '0' ''

# Test 643: << << << << << << << << << << << << << <
[[ -z "$FILTER_CATEGORY" || "<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>' 'echo hola > bonjour
$> echo hey > hello
$> echo hola > bonjour > hello > bonjour
$> cat bonjour
$> cat hello' '0' ''

# Test 644: << << << << << << << << << << << << << <
[[ -z "$FILTER_CATEGORY" || "<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>' 'echo hola > bonjour
$> echo hey > hello
$> rm bonjour hello
$> echo hola > bonjour > hello >> bonjour
$> cat bonjour
$> cat hello' '0' ''

# Test 645: << << << << << << << << << << << << << <
[[ -z "$FILTER_CATEGORY" || "<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>' 'echo hola > bonjour
$> echo hey > hello
$> echo hola > bonjour > hello >> bonjour
$> cat bonjour
$> cat hello' '0' ''

# Test 646: << << << << << << << << << << << << << <
[[ -z "$FILTER_CATEGORY" || "<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>' 'echo hola > bonjour
$> echo hey > hello
$> rm bonjour hello
$> echo hola >> bonjour > hello > bonjour
$> cat bonjour
$> cat hello' '0' ''

# Test 647: << << << << << << << << << << << << << <
[[ -z "$FILTER_CATEGORY" || "<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>' 'echo hola > bonjour
$> echo hey > hello
$> echo hola >> bonjour > hello > bonjour
$> cat bonjour
$> cat hello' '0' ''

# Test 648: << << << << << << << << << << << << << <
[[ -z "$FILTER_CATEGORY" || "<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>' 'echo hola > bonjour
$> echo hey > hello
$> rm bonjour hello
$> echo hola >> bonjour >> hello >> bonjour
$> cat bonjour
$> cat hello' '0' ''

# Test 649: << << << << << << << << << << << << << <
[[ -z "$FILTER_CATEGORY" || "<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>' 'echo hola > bonjour
$> echo hey > hello
$> echo hola >> bonjour >> hello >> bonjour
$> cat bonjour
$> cat hello' '0' ''

# Test 650: << << << << << << << << << << << << << <
[[ -z "$FILTER_CATEGORY" || "<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>' '> bonjour echo hola bonjour
$> cat bonjour' '0' ''

# Test 651: << << << << << << << << << << << << << <
[[ -z "$FILTER_CATEGORY" || "<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>' '>bonjour echo > hola>bonjour>hola>>bonjour>hola hey >bonjour hola >hola
$> cat bonjour
$> cat hola' '0' ''

# Test 652: << << << << << << << << << << << << << <
[[ -z "$FILTER_CATEGORY" || "<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>' 'echo bonjour > hola1
$> echo hello > hola2
$> echo 2 >hola1 >> hola2
$> ls
$> cat hola1
$> cat hola2' '0' ''

# Test 653: << << << << << << << << << << << << << <
[[ -z "$FILTER_CATEGORY" || "<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>' 'echo bonjour > hola1
$> echo hello > hola2
$> echo 2 >>hola1 > hola2
$> ls
$> cat hola1
$> cat hola2' '0' ''

# Test 654: << << << << << << << << << << << << << <
[[ -z "$FILTER_CATEGORY" || "<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>' '> pwd
$> ls' '0' ''

# Test 655: << << << << << << << << << << << << << <
[[ -z "$FILTER_CATEGORY" || "<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>' '< pwd' '1' ''

# Test 656: << << << << << << << << << << << << << <
[[ -z "$FILTER_CATEGORY" || "<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>' '< Makefile .' '1' 'Voir pourquoi'

# Test 657: << << << << << << << << << << << << << <
[[ -z "$FILTER_CATEGORY" || "<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>' 'cat <pwd' '1' ''

# Test 658: << << << << << << << << << << << << << <
[[ -z "$FILTER_CATEGORY" || "<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>' 'cat <srcs/pwd' '1' ''

# Test 659: << << << << << << << << << << << << << <
[[ -z "$FILTER_CATEGORY" || "<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>' 'cat <../pwd' '1' ''

# Test 660: << << << << << << << << << << << << << <
[[ -z "$FILTER_CATEGORY" || "<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>' 'cat >>' '2' 'Marche aussi pour les autres operateurs de redirection'

# Test 661: << << << << << << << << << << << << << <
[[ -z "$FILTER_CATEGORY" || "<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>' 'cat >>>' '2' ''

# Test 662: << << << << << << << << << << << << << <
[[ -z "$FILTER_CATEGORY" || "<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>' 'cat >> <<' '2' ''

# Test 663: << << << << << << << << << << << << << <
[[ -z "$FILTER_CATEGORY" || "<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>' 'cat >> > >> << >>' '2' ''

# Test 664: << << << << << << << << << << << << << <
[[ -z "$FILTER_CATEGORY" || "<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>' 'cat < ls' '1' ''

# Test 665: << << << << << << << << << << << << << <
[[ -z "$FILTER_CATEGORY" || "<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>' 'cat < ls > ls' '1' ''

# Test 666: << << << << << << << << << << << << << <
[[ -z "$FILTER_CATEGORY" || "<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>' 'cat > ls1 < ls2
$> ls' '1' ''

# Test 667: << << << << << << << << << << << << << <
[[ -z "$FILTER_CATEGORY" || "<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>' '>>hola
$> cat hola' '0' ''

# Test 668: << << << << << << << << << << << << << <
[[ -z "$FILTER_CATEGORY" || "<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>' 'echo hola > bonjour
$> cat < bonjour' '0' ''

# Test 669: << << << << << << << << << << << << << <
[[ -z "$FILTER_CATEGORY" || "<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>' 'echo hola >bonjour
$> cat <bonjour' '0' ''

# Test 670: << << << << << << << << << << << << << <
[[ -z "$FILTER_CATEGORY" || "<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>' 'echo hola>bonjour
$> cat<bonjour' '0' ''

# Test 671: << << << << << << << << << << << << << <
[[ -z "$FILTER_CATEGORY" || "<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>' 'echo hola> bonjour
$> cat< bonjour' '0' ''

# Test 672: << << << << << << << << << << << << << <
[[ -z "$FILTER_CATEGORY" || "<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>' 'echo hola               >bonjour
$> cat<                     bonjour' '0' ''

# Test 673: << << << << << << << << << << << << << <
[[ -z "$FILTER_CATEGORY" || "<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>' 'echo hola          >     bonjour
$> cat            <         bonjour' '0' ''

# Test 674: << << << << << << << << << << << << << <
[[ -z "$FILTER_CATEGORY" || "<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>' 'echo hola > srcs/bonjour
$> cat < srcs/bonjour' '0' ''

# Test 675: << << << << << << << << << << << << << <
[[ -z "$FILTER_CATEGORY" || "<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>' 'echo hola >srcs/bonjour
$> cat <srcs/bonjour' '0' ''

# Test 676: << << << << << << << << << << << << << <
[[ -z "$FILTER_CATEGORY" || "<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>' 'echo hola > bonjour
$> echo que tal >> bonjour
$> cat < bonjour' '0' ''

# Test 677: << << << << << << << << << << << << << <
[[ -z "$FILTER_CATEGORY" || "<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>' 'echo hola > bonjour
$> rm bonjour
$> echo que tal >> bonjour
$> cat < bonjour' '0' ''

# Test 678: << << << << << << << << << << << << << <
[[ -z "$FILTER_CATEGORY" || "<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>' 'e'\''c'\''\"h\"o hola > bonjour
$> cat '\''bo'\''\"n\"jour' '0' ''

# Test 679: << << << << << << << << << << << << << <
[[ -z "$FILTER_CATEGORY" || "<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>' 'echo hola > bonjour\ 1
$> ls
$> cat bonjour\ 1' '0' ''

# Test 680: << << << << << << << << << << << << << <
[[ -z "$FILTER_CATEGORY" || "<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>' 'echo hola > bonjour hey
$> ls
$> cat bonjour
$> cat hey' '0' ''

# Test 681: << << << << << << << << << << << << << <
[[ -z "$FILTER_CATEGORY" || "<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>' 'echo hola > srcs/bonjour
$> echo hey > srcs/hello
$> >srcs/bonjour >srcs/hello <prout
$> cat srcs/bonjour srcs/hello' '0' ''

# Test 682: << << << << << << << << << << << << << <
[[ -z "$FILTER_CATEGORY" || "<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>' 'echo hola > srcs/bonjour
$> echo hey > srcs/hello
$> rm srcs/bonjour srcs/hello
$> >srcs/bonjour >srcs/hello <prout
$> ls srcs
$> cat srcs/bonjour srcs/hello' '0' ''

# Test 683: << << << << << << << << << << << << << <
[[ -z "$FILTER_CATEGORY" || "<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>' 'echo hola > srcs/bonjour
$> echo hey > srcs/hello
$> >srcs/bonjour <prout >srcs/hello 
$> cat srcs/bonjour 
$> cat srcs/hello' '0' ''

# Test 684: << << << << << << << << << << << << << <
[[ -z "$FILTER_CATEGORY" || "<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>' 'echo hola > srcs/bonjour
$> echo hey > srcs/hello
$> rm srcs/bonjour srcs/hello
$> >srcs/bonjour <prout >srcs/hello 
$> ls srcs
$> cat srcs/bonjour' '0' ''

# Test 685: << << << << << << << << << << << << << <
[[ -z "$FILTER_CATEGORY" || "<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>' 'echo hola > ../bonjour
$> echo hey > ../hello
$> >../bonjour >../hello <prout
$> cat ../bonjour ../hello' '0' ''

# Test 686: << << << << << << << << << << << << << <
[[ -z "$FILTER_CATEGORY" || "<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>' 'echo hola > ../bonjour
$> echo hey > ../hello
$> rm ../bonjour ../hello
$> >../bonjour >../hello <prout
$> ls ..
$> cat ../bonjour ../hello' '0' ''

# Test 687: << << << << << << << << << << << << << <
[[ -z "$FILTER_CATEGORY" || "<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>' 'echo hola > ../bonjour
$> echo hey > ../hello
$> >../bonjour <prout >../hello 
$> cat ../bonjour 
$> cat ../hello' '0' ''

# Test 688: << << << << << << << << << << << << << <
[[ -z "$FILTER_CATEGORY" || "<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>' 'echo hola > ../bonjour
$> echo hey > ../hello
$> rm ../bonjour ../hello
$> >../bonjour <prout >../hello 
$> ls ..
$> cat ../bonjour' '0' ''

# Test 689: << << << << << << << << << << << << << <
[[ -z "$FILTER_CATEGORY" || "<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>' 'echo hola > srcs/bonjour
$> echo hey > srcs/hello
$> >srcs/bonjour >>srcs/hello <prout
$> cat srcs/bonjour 
$> cat srcs/hello' '0' ''

# Test 690: << << << << << << << << << << << << << <
[[ -z "$FILTER_CATEGORY" || "<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>' 'echo hola > srcs/bonjour
$> echo hey > srcs/hello
$> >>srcs/bonjour >srcs/hello <prout
$> cat srcs/bonjour 
$> cat srcs/hello' '0' ''

# Test 691: << << << << << << << << << << << << << <
[[ -z "$FILTER_CATEGORY" || "<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>' 'echo hola > srcs/bonjour
$> echo hey > srcs/hello
$> >>srcs/bonjour >>srcs/hello <prout
$> cat srcs/bonjour 
$> cat srcs/hello' '0' ''

# Test 692: << << << << << << << << << << << << << <
[[ -z "$FILTER_CATEGORY" || "<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>' 'echo hola > srcs/bonjour
$> echo hey > srcs/hello
$> >srcs/bonjour <prout >>srcs/hello
$> cat srcs/bonjour 
$> cat srcs/hello' '0' ''

# Test 693: << << << << << << << << << << << << << <
[[ -z "$FILTER_CATEGORY" || "<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>' 'echo hola > srcs/bonjour
$> echo hey > srcs/hello
$> >>srcs/bonjour <prout >srcs/hello
$> cat srcs/bonjour 
$> cat srcs/hello' '0' ''

# Test 694: << << << << << << << << << << << << << <
[[ -z "$FILTER_CATEGORY" || "<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>' 'echo hola > srcs/bonjour
$> echo hey > srcs/hello
$> >>srcs/bonjour <prout >>srcs/hello
$> cat srcs/bonjour 
$> cat srcs/hello' '0' ''

# Test 695: << << << << << << << << << << << << << <
[[ -z "$FILTER_CATEGORY" || "<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>' 'echo hola > srcs/bonjour
$> echo hey > srcs/hello
$> <prout >>srcs/bonjour >>srcs/hello
$> cat srcs/bonjour 
$> cat srcs/hello' '0' ''

# Test 696: << << << << << << << << << << << << << <
[[ -z "$FILTER_CATEGORY" || "<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>' 'echo hola > bonjour
$> echo hey > hello
$> <bonjour >hello
$> cat bonjour 
$> cat hello' '0' ''

# Test 697: << << << << << << << << << << << << << <
[[ -z "$FILTER_CATEGORY" || "<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>' 'echo hola > bonjour
$> echo hey > hello
$> >bonjour >hello < prout
$> cat bonjour 
$> cat hello' '0' ''

# Test 698: << << << << << << << << << << << << << <
[[ -z "$FILTER_CATEGORY" || "<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>' 'echo hola > bonjour
$> echo hey > hello
$> rm bonjour hello
$> >bonjour >hello < prout
$> cat bonjour 
$> cat hello' '0' ''

# Test 699: << << << << << << << << << << << << << <
[[ -z "$FILTER_CATEGORY" || "<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>' 'echo hola > bonjour
$> echo hey > hello
$> >bonjour <prout hello
$> cat bonjour 
$> cat hello' '0' ''

# Test 700: << << << << << << << << << << << << << <
[[ -z "$FILTER_CATEGORY" || "<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>' 'echo hola > bonjour
$> echo hey > hello
$> rm bonjour hello
$> >bonjour <prout hello
$> cat bonjour' '0' 'Le fichier hello n'\''existe pas'

# Test 701: << << << << << << << << << << << << << <
[[ -z "$FILTER_CATEGORY" || "<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>' 'echo hola > bonjour
$> <bonjour cat | wc > bonjour
$> cat bonjour' '0' ''

# Test 702: << << << << << << << << << << << << << <
[[ -z "$FILTER_CATEGORY" || "<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>' 'rm -f bonjour
$> rm bonjour > bonjour
$> ls -l bonjour' '0' ''

# Test 703: << << << << << << << << << << << << << <
[[ -z "$FILTER_CATEGORY" || "<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>' 'export HOLA=\"bonjour hello\"
$> >$HOLA
$> ls' '0' ''

# Test 704: << << << << << << << << << << << << << <
[[ -z "$FILTER_CATEGORY" || "<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>' 'export HOLA=\"bonjour hello\"
$> >\"$HOLA\"
$> ls' '0' ''

# Test 705: << << << << << << << << << << << << << <
[[ -z "$FILTER_CATEGORY" || "<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>' 'export HOLA=\"bonjour hello\"
$> >$\"HOLA\"
$> ls' '0' ''

# Test 706: << << << << << << << << << << << << << <
[[ -z "$FILTER_CATEGORY" || "<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>' 'export HOLA=\"bonjour hello\"
$> >$HOLA>hey
$> ls' '0' ''

# Test 707: << << << << << << << << << << << << << <
[[ -z "$FILTER_CATEGORY" || "<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>' 'export HOLA=\"bonjour hello\"
$> >hey>$HOLA
$> ls' '0' ''

# Test 708: << << << << << << << << << << << << << <
[[ -z "$FILTER_CATEGORY" || "<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>' 'export HOLA=\"bonjour hello\"
$> >hey>$HOLA>hey>hey
$> ls' '0' ''

# Test 709: << << << << << << << << << << << << << <
[[ -z "$FILTER_CATEGORY" || "<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>' 'export A=hey
$> export A B=Hola D E C=\"Que Tal\"
$> echo $PROUT$B$C > /tmp/a > /tmp/b > /tmp/c
$> cat /tmp/a
$> cat /tmp/b
$> cat /tmp/c' '0' ''

# Test 710: << << << << << << << << << << << << << <
[[ -z "$FILTER_CATEGORY" || "<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>' '!!!!! Contenu du fichier a : \"Amour Tu es Horrible\"
                                           !!!!! Contenu du fichier b : \"0123456789\"
                                           !!!!! Contenu du fichier c : \"Prout\"' '0' ''

# Test 711: << << << << << << << << << << << << << <
[[ -z "$FILTER_CATEGORY" || "<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>' '<a cat <b <c' '0' ''

# Test 712: << << << << << << << << << << << << << <
[[ -z "$FILTER_CATEGORY" || "<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>' '<a cat <b <c
$> cat a
$> cat b
$> cat c' '0' ''

# Test 713: << << << << << << << << << << << << << <
[[ -z "$FILTER_CATEGORY" || "<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>' '>a ls >b >>c >d
$> cat a
$> cat b
$> cat c
$> cat d' '0' ''

# Test 714: << << << << << << << << << << << << << <
[[ -z "$FILTER_CATEGORY" || "<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>' '>a ls >b >>c >d
$> cat a
$> cat b
$> cat c
$> cat d' '0' ''

# Test 715: << << << << << << << << << << << << << <
[[ -z "$FILTER_CATEGORY" || "<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>' 'echo hola > a > b > c
$> cat a
$> cat b
$> cat c' '0' ''

# Test 716: << << << << << << << << << << << << << <
[[ -z "$FILTER_CATEGORY" || "<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>' 'mkdir dir
$> ls -la > dir/bonjour
$> cat dir/bonjour' '0' ''

# Test 717: << << << << << << << << << << << << << <
[[ -z "$FILTER_CATEGORY" || "<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>' '<a
$> cat a' '0' ''

# Test 718: << << << << << << << << << << << << << <
[[ -z "$FILTER_CATEGORY" || "<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>' '>d cat <a >>e
$> cat a
$> cat d
$> cat e' '0' ''

# Test 719: << << << << << << << << << << << << << <
[[ -z "$FILTER_CATEGORY" || "<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd '<< << << << << << << << << << << << << << << <<  < REDIRECTIONS >  >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >>' '< a > b cat > hey >> d
$> cat d
$> ls' '0' ''

# Test 720: HEREDOC ⏮️
[[ -z "$FILTER_CATEGORY" || "HEREDOC ⏮️" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'HEREDOC ⏮️' 'cat << hola' '0' ''

# Test 721: HEREDOC ⏮️
[[ -z "$FILTER_CATEGORY" || "HEREDOC ⏮️" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'HEREDOC ⏮️' 'cat << '\''hola'\''' '0' ''

# Test 722: HEREDOC ⏮️
[[ -z "$FILTER_CATEGORY" || "HEREDOC ⏮️" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'HEREDOC ⏮️' 'cat << \"hola\"' '0' ''

# Test 723: HEREDOC ⏮️
[[ -z "$FILTER_CATEGORY" || "HEREDOC ⏮️" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'HEREDOC ⏮️' 'cat << ho\"la\"' '0' ''

# Test 724: HEREDOC ⏮️
[[ -z "$FILTER_CATEGORY" || "HEREDOC ⏮️" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'HEREDOC ⏮️' 'cat << $HOME' '0' ''

# Test 725: HEREDOC ⏮️
[[ -z "$FILTER_CATEGORY" || "HEREDOC ⏮️" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'HEREDOC ⏮️' 'cat << hola > bonjour
$> cat bonjour' '0' ''

# Test 726: HEREDOC ⏮️
[[ -z "$FILTER_CATEGORY" || "HEREDOC ⏮️" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'HEREDOC ⏮️' 'cat << hola | rev' '0' ''

# Test 727: HEREDOC ⏮️
[[ -z "$FILTER_CATEGORY" || "HEREDOC ⏮️" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'HEREDOC ⏮️' '<< hola' '0' ''

# Test 728: HEREDOC ⏮️
[[ -z "$FILTER_CATEGORY" || "HEREDOC ⏮️" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'HEREDOC ⏮️' '<<hola' '0' ''

# Test 729: HEREDOC ⏮️
[[ -z "$FILTER_CATEGORY" || "HEREDOC ⏮️" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'HEREDOC ⏮️' 'cat <<' '2' ''

# Test 730: HEREDOC ⏮️
[[ -z "$FILTER_CATEGORY" || "HEREDOC ⏮️" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'HEREDOC ⏮️' 'cat << prout << lol << koala' '0' ''

# Test 731: HEREDOC ⏮️
[[ -z "$FILTER_CATEGORY" || "HEREDOC ⏮️" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'HEREDOC ⏮️' 'prout << lol << cat << koala' '127' ''

# Test 732: HEREDOC ⏮️
[[ -z "$FILTER_CATEGORY" || "HEREDOC ⏮️" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'HEREDOC ⏮️' '<< $hola' '0' ''

# Test 733: HEREDOC ⏮️
[[ -z "$FILTER_CATEGORY" || "HEREDOC ⏮️" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'HEREDOC ⏮️' '<< $\"hola\"$\"b\"' '0' ''

# Test 734: HEREDOC ⏮️
[[ -z "$FILTER_CATEGORY" || "HEREDOC ⏮️" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'HEREDOC ⏮️' '<< $\"$hola\"$$\"b\"' '0' ''

# Test 735: HEREDOC ⏮️
[[ -z "$FILTER_CATEGORY" || "HEREDOC ⏮️" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'HEREDOC ⏮️' '<< ho$la$\"$a\"$$\"b\"' '0' ''

# Test 736: HEREDOC ⏮️
[[ -z "$FILTER_CATEGORY" || "HEREDOC ⏮️" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'HEREDOC ⏮️' 'echo hola <<< bonjour' '0' ''

# Test 737: HEREDOC ⏮️
[[ -z "$FILTER_CATEGORY" || "HEREDOC ⏮️" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'HEREDOC ⏮️' 'echo hola <<<< bonjour' '2' ''

# Test 738: HEREDOC ⏮️
[[ -z "$FILTER_CATEGORY" || "HEREDOC ⏮️" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'HEREDOC ⏮️' 'echo hola <<<<< bonjour' '2' ''

# Test 739: WILDCARD ⭐
[[ -z "$FILTER_CATEGORY" || "WILDCARD ⭐" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'WILDCARD ⭐' 'ls *' '0' '[BONUS]'

# Test 740: WILDCARD ⭐
[[ -z "$FILTER_CATEGORY" || "WILDCARD ⭐" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'WILDCARD ⭐' 'ls *.*' '0' '[BONUS]'

# Test 741: WILDCARD ⭐
[[ -z "$FILTER_CATEGORY" || "WILDCARD ⭐" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'WILDCARD ⭐' 'ls *.hola' '2' '[BONUS]'

# Test 742: WILDCARD ⭐
[[ -z "$FILTER_CATEGORY" || "WILDCARD ⭐" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'WILDCARD ⭐' 'cat M*le' '0' '[BONUS]'

# Test 743: WILDCARD ⭐
[[ -z "$FILTER_CATEGORY" || "WILDCARD ⭐" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'WILDCARD ⭐' 'cat M*ee' '1' '[BONUS]'

# Test 744: WILDCARD ⭐
[[ -z "$FILTER_CATEGORY" || "WILDCARD ⭐" =~ "$FILTER_CATEGORY" ]] && \
    test_cmd 'WILDCARD ⭐' 'cat Make*file' '0' '[BONUS]'

# ============================================================================
# Results
# ============================================================================

show_stats
[ $FAILED -eq 0 ] && exit 0 || exit 1
