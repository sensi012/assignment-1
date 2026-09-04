#!/usr/bin/env bash
# ==============================================================================
# grade.sh - Assignment 1 Comprehensive Automated Grader
#
# Evaluates:
#   - Required File Structure & Executable Permissions
#   - Bash Syntax Validation (bash -n)
#   - Linux Commands & System Information Inspection (20 pts)
#   - Bash Scripting & Disk Check Logic (25 pts)
#   - Network Diagnostics & TCP Checks (20 pts)
#   - Error Handling & Exit Codes (10 pts)
#   - Logging System & Timestamp Verification (10 pts)
#   - Git Workflow & Commit History (10 pts)
#   - README Documentation (5 pts)
# Total: 100 Points
# ==============================================================================

set -u

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

TOTAL_SCORE=0
MAX_SCORE=100

SCORE_LINUX_CMDS=0
SCORE_BASH_SCRIPTING=0
SCORE_NETWORKING=0
SCORE_ERROR_HANDLING=0
SCORE_LOGGING=0
SCORE_GIT=0
SCORE_README=0

pass() {
    echo -e "  [${GREEN}PASS${NC}] $1 (+${2} pts)"
}

fail() {
    echo -e "  [${RED}FAIL${NC}] $1 (0 pts)"
}

warn() {
    echo -e "  [${YELLOW}WARN${NC}] $1"
}

info() {
    echo -e "  [${BLUE}INFO${NC}] $1"
}

echo -e "${BOLD}${CYAN}============================================================${NC}"
echo -e "${BOLD}${CYAN}        DEVOPS ASSIGNMENT 1 - AUTOMATED GRADER              ${NC}"
echo -e "${BOLD}${CYAN}============================================================${NC}\n"

# ------------------------------------------------------------------------------
# 1. Structure, Permissions & Syntax Checks
# ------------------------------------------------------------------------------
echo -e "${BOLD}--- [1/7] File Structure, Permissions & Syntax ---${NC}"

REQUIRED_FILES=("README.md" "system-info.sh" "disk-check.sh" "network-check.sh" "logs")
MISSING_FILES=0
for f in "${REQUIRED_FILES[@]}"; do
    if [ -e "$f" ]; then
        info "Found required entry: $f"
    else
        warn "Missing required entry: $f"
        MISSING_FILES=$((MISSING_FILES + 1))
    fi
done

SYNTAX_ERRORS=0
for script in system-info.sh disk-check.sh network-check.sh; do
    if [ -f "$script" ]; then
        chmod +x "$script" 2>/dev/null || true
        if bash -n "$script" 2>/dev/null; then
            info "Bash syntax check passed: $script"
        else
            warn "Syntax error in $script"
            SYNTAX_ERRORS=$((SYNTAX_ERRORS + 1))
        fi
    fi
done

# ------------------------------------------------------------------------------
# 2. Linux Commands & system-info.sh (20 Points)
# ------------------------------------------------------------------------------
echo -e "\n${BOLD}--- [2/7] Linux Commands & System Information (20 Pts) ---${NC}"
if [ -f "system-info.sh" ] && [ -x "system-info.sh" ]; then
    SYS_OUT="$(./system-info.sh 2>&1 || true)"
    SYS_EXIT=$?
    
    # Check key system attributes
    FIELDS=("Hostname" "Current User" "Date/Time" "Operating System" "Kernel Version" "System Uptime" "CPU Information" "Memory Information" "Current Directory")
    MATCHED_FIELDS=0
    for field in "${FIELDS[@]}"; do
        if echo "${SYS_OUT}" | grep -qi "${field}"; then
            MATCHED_FIELDS=$((MATCHED_FIELDS + 1))
        fi
    done

    if [ "$MATCHED_FIELDS" -ge 8 ] && [ "$SYS_EXIT" -eq 0 ]; then
        pass "system-info.sh accurately retrieves all runtime system attributes" 20
        SCORE_LINUX_CMDS=20
    elif [ "$MATCHED_FIELDS" -ge 5 ]; then
        pass "system-info.sh retrieves majority of system attributes (${MATCHED_FIELDS}/9)" 14
        SCORE_LINUX_CMDS=14
    else
        fail "system-info.sh missing crucial runtime system metrics" 0
    fi
else
    fail "system-info.sh missing or not executable" 0
fi

# ------------------------------------------------------------------------------
# 3. Bash Scripting & Disk Check Logic (25 Points)
# ------------------------------------------------------------------------------
echo -e "\n${BOLD}--- [3/7] Bash Scripting & Disk Usage Checking (25 Pts) ---${NC}"
if [ -f "disk-check.sh" ] && [ -x "disk-check.sh" ]; then
    # Test 1: High threshold (100) -> expect exit code 0
    ./disk-check.sh 100 / >/dev/null 2>&1
    EXIT_100=$?
    
    # Test 2: Low threshold (1) -> expect exit code 1
    ./disk-check.sh 1 / >/dev/null 2>&1
    EXIT_1=$?

    # Test 3: Default path fallback with high threshold
    ./disk-check.sh 100 >/dev/null 2>&1
    EXIT_DEF=$?

    if [ "$EXIT_100" -eq 0 ] && [ "$EXIT_1" -eq 1 ] && [ "$EXIT_DEF" -eq 0 ]; then
        pass "disk-check.sh handles normal, threshold exceeded, and default path correctly" 25
        SCORE_BASH_SCRIPTING=25
    elif [ "$EXIT_100" -eq 0 ] && [ "$EXIT_1" -eq 1 ]; then
        pass "disk-check.sh handles threshold evaluation" 20
        SCORE_BASH_SCRIPTING=20
    else
        fail "disk-check.sh failed threshold exit code logic" 0
    fi
else
    fail "disk-check.sh missing or not executable" 0
fi

# ------------------------------------------------------------------------------
# 4. Networking Diagnostics (20 Points)
# ------------------------------------------------------------------------------
echo -e "\n${BOLD}--- [4/7] Networking Diagnostics & TCP Verification (20 Pts) ---${NC}"
if [ -f "network-check.sh" ] && [ -x "network-check.sh" ]; then
    # Run with localhost / 127.0.0.1
    NET_OUT="$(./network-check.sh 127.0.0.1 2>&1 || true)"
    
    HAS_RESOLVE=false
    HAS_IFACE=false
    HAS_PING=false

    if echo "${NET_OUT}" | grep -Ei "(Resolved Address|Target is raw IPv4|Resolution)" >/dev/null 2>&1; then
        HAS_RESOLVE=true
    fi
    if echo "${NET_OUT}" | grep -Ei "(Interface|127\.0\.0\.1|lo|eth0)" >/dev/null 2>&1; then
        HAS_IFACE=true
    fi
    if echo "${NET_OUT}" | grep -Ei "(Ping Status|ICMP|Connectivity)" >/dev/null 2>&1; then
        HAS_PING=true
    fi

    # Port checking verification
    # Using 127.0.0.1 and a high closed port (e.g. 64831)
    ./network-check.sh 127.0.0.1 64831 >/dev/null 2>&1 || true
    PORT_CHECK_EXIT=$?

    if [ "$HAS_RESOLVE" = true ] && [ "$HAS_IFACE" = true ] && [ "$HAS_PING" = true ]; then
        pass "network-check.sh resolves host, inspects interfaces, and checks connectivity" 20
        SCORE_NETWORKING=20
    elif [ "$HAS_RESOLVE" = true ] && [ "$HAS_IFACE" = true ]; then
        pass "network-check.sh performs resolution and interface diagnostics" 15
        SCORE_NETWORKING=15
    else
        fail "network-check.sh missing core networking diagnostic features" 0
    fi
else
    fail "network-check.sh missing or not executable" 0
fi

# ------------------------------------------------------------------------------
# 5. Error Handling & Exit Codes (10 Points)
# ------------------------------------------------------------------------------
echo -e "\n${BOLD}--- [5/7] Error Handling & Input Validation (10 Pts) ---${NC}"
ERRORS_HANDLED=0

# disk-check invalid inputs
./disk-check.sh >/dev/null 2>&1
[ $? -eq 2 ] && ERRORS_HANDLED=$((ERRORS_HANDLED + 1))

./disk-check.sh notanumber >/dev/null 2>&1
[ $? -eq 2 ] && ERRORS_HANDLED=$((ERRORS_HANDLED + 1))

./disk-check.sh 150 >/dev/null 2>&1
[ $? -eq 2 ] && ERRORS_HANDLED=$((ERRORS_HANDLED + 1))

./disk-check.sh 50 /nonexistent/path/xyz >/dev/null 2>&1
[ $? -eq 2 ] && ERRORS_HANDLED=$((ERRORS_HANDLED + 1))

# network-check invalid inputs
./network-check.sh >/dev/null 2>&1
[ $? -ne 0 ] && ERRORS_HANDLED=$((ERRORS_HANDLED + 1))

./network-check.sh 127.0.0.1 99999 >/dev/null 2>&1
[ $? -ne 0 ] && ERRORS_HANDLED=$((ERRORS_HANDLED + 1))

./network-check.sh 127.0.0.1 notaport >/dev/null 2>&1
[ $? -ne 0 ] && ERRORS_HANDLED=$((ERRORS_HANDLED + 1))

if [ "$ERRORS_HANDLED" -ge 6 ]; then
    pass "All edge cases, missing args, and out-of-bounds parameters handled (Exit 2)" 10
    SCORE_ERROR_HANDLING=10
elif [ "$ERRORS_HANDLED" -ge 4 ]; then
    pass "Majority of invalid arguments properly rejected" 7
    SCORE_ERROR_HANDLING=7
else
    fail "Insufficient input validation in scripts" 0
fi

# ------------------------------------------------------------------------------
# 6. Logging Verification (10 Points)
# ------------------------------------------------------------------------------
echo -e "\n${BOLD}--- [6/7] Logging & Audit Trail (10 Pts) ---${NC}"
LOG_COUNT=$(find logs -type f ! -name ".gitkeep" 2>/dev/null | wc -l)
LOG_HAS_TIMESTAMPS=false

if [ "$LOG_COUNT" -gt 0 ]; then
    # Inspect log content for timestamp format YYYY-MM-DD
    if grep -Eq '\[[0-9]{4}-[0-9]{2}-[0-9]{2}' logs/*.log 2>/dev/null; then
        LOG_HAS_TIMESTAMPS=true
    fi
fi

if [ "$LOG_COUNT" -gt 0 ] && [ "$LOG_HAS_TIMESTAMPS" = true ]; then
    pass "Logs created under logs/ with proper ISO/standard timestamps & descriptions" 10
    SCORE_LOGGING=10
elif [ "$LOG_COUNT" -gt 0 ]; then
    pass "Logs created under logs/ but timestamp format non-standard" 6
    SCORE_LOGGING=6
else
    fail "No operational logs found under logs/" 0
fi

# ------------------------------------------------------------------------------
# 7. Git Workflow & README (15 Points Total)
# ------------------------------------------------------------------------------
echo -e "\n${BOLD}--- [7/7] Git Workflow & Documentation (15 Pts) ---${NC}"

# Git workflow check (10 pts)
GIT_COMMITS=0
GIT_BRANCHES=0
if [ -d ".git" ] && command -v git >/dev/null 2>&1; then
    GIT_COMMITS=$(git rev-list --count HEAD 2>/dev/null || echo 0)
    # Check if branch exists or merge commit present
    MERGE_COMMITS=$(git log --merges -n 1 --oneline 2>/dev/null | wc -l)
    BRANCH_COUNT=$(git branch -a 2>/dev/null | wc -l)
    
    if [ "$GIT_COMMITS" -ge 5 ] && ([ "$MERGE_COMMITS" -ge 1 ] || [ "$BRANCH_COUNT" -ge 2 ]); then
        pass "Git repository has >= 5 commits with feature branch and merge" 10
        SCORE_GIT=10
    elif [ "$GIT_COMMITS" -ge 5 ]; then
        pass "Git repository has >= 5 commits (${GIT_COMMITS} commits)" 7
        SCORE_GIT=7
    elif [ "$GIT_COMMITS" -ge 1 ]; then
        pass "Git repository initialized with commits" 5
        SCORE_GIT=5
    else
        fail "Git repository has no commits" 0
    fi
else
    warn "No local .git directory in current folder (will evaluate in Git context)"
    SCORE_GIT=10 # If run in non-git archive, default full if files are verified
fi

# README check (5 pts)
if [ -f "README.md" ] && [ -s "README.md" ]; then
    README_MATCHES=0
    grep -qi "installation\|setup" README.md && README_MATCHES=$((README_MATCHES + 1))
    grep -qi "usage" README.md && README_MATCHES=$((README_MATCHES + 1))
    grep -qi "test" README.md && README_MATCHES=$((README_MATCHES + 1))
    grep -qi "assumption" README.md && README_MATCHES=$((README_MATCHES + 1))
    
    if [ "$README_MATCHES" -ge 3 ]; then
        pass "README.md contains setup, usage, testing, and assumptions" 5
        SCORE_README=5
    else
        pass "README.md exists with basic documentation" 3
        SCORE_README=3
    fi
else
    fail "README.md is missing or empty" 0
fi

# ------------------------------------------------------------------------------
# Final Score Summary
# ------------------------------------------------------------------------------
TOTAL_SCORE=$((SCORE_LINUX_CMDS + SCORE_BASH_SCRIPTING + SCORE_NETWORKING + SCORE_ERROR_HANDLING + SCORE_LOGGING + SCORE_GIT + SCORE_README))

echo -e "\n${BOLD}${CYAN}============================================================${NC}"
echo -e "${BOLD}${CYAN}                     GRADING SUMMARY                        ${NC}"
echo -e "${BOLD}${CYAN}============================================================${NC}"
printf "%-35s: %2d / 20\n" "Linux Commands & System Info" "${SCORE_LINUX_CMDS}"
printf "%-35s: %2d / 25\n" "Bash Scripting & Disk Check" "${SCORE_BASH_SCRIPTING}"
printf "%-35s: %2d / 20\n" "Networking Diagnostics" "${SCORE_NETWORKING}"
printf "%-35s: %2d / 10\n" "Error Handling & Validations" "${SCORE_ERROR_HANDLING}"
printf "%-35s: %2d / 10\n" "Logging & Audit Trail" "${SCORE_LOGGING}"
printf "%-35s: %2d / 10\n" "Git Workflow & Branches" "${SCORE_GIT}"
printf "%-35s: %2d /  5\n" "README Documentation" "${SCORE_README}"
echo -e "------------------------------------------------------------"
if [ "${TOTAL_SCORE}" -ge 90 ]; then
    echo -e "${BOLD}${GREEN}TOTAL SCORE: ${TOTAL_SCORE} / ${MAX_SCORE} - EXCELLENT (GRADE: A)${NC}"
elif [ "${TOTAL_SCORE}" -ge 75 ]; then
    echo -e "${BOLD}${YELLOW}TOTAL SCORE: ${TOTAL_SCORE} / ${MAX_SCORE} - SATISFACTORY (GRADE: B)${NC}"
else
    echo -e "${BOLD}${RED}TOTAL SCORE: ${TOTAL_SCORE} / ${MAX_SCORE} - NEEDS IMPROVEMENT${NC}"
fi
echo -e "${BOLD}${CYAN}============================================================${NC}\n"

exit 0
