#!/usr/bin/env bash
# ==============================================================================
# system-info.sh - Linux System Diagnostic Information Collector
#
# Collects and displays real-time system metrics:
#   - Hostname, Current User, Date/Time, Operating System, Kernel Version,
#     System Uptime, CPU Information, Memory Statistics, Current Working Directory.
#
# Logs the execution with a timestamp to the logs/ directory.
# Exit Code: 0 on success.
# ==============================================================================

set -euo pipefail

# Determine script and log locations robustly
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="${SCRIPT_DIR}/logs"
LOG_FILE="${LOG_DIR}/system-info.log"

# Ensure logs directory exists
mkdir -p "${LOG_DIR}"

# Logging function: appends timestamp and message
log_operation() {
    local timestamp
    timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
    echo "[${timestamp}] [SYSTEM-INFO] $1" >> "${LOG_FILE}"
}

log_operation "Started system-info diagnostics collection."

# Runtime System Metrics Extraction
HOSTNAME_VAL="$(hostname 2>/dev/null || uname -n)"
USER_VAL="$(whoami 2>/dev/null || id -un 2>/dev/null || echo "${USER:-unknown}")"
DATETIME_VAL="$(date '+%Y-%m-%d %H:%M:%S %Z')"
OS_VAL="$(uname -s) $(grep -E '^PRETTY_NAME=' /etc/os-release 2>/dev/null | cut -d'=' -f2 | tr -d '\"' || true)"
KERNEL_VAL="$(uname -r)"
UPTIME_VAL="$(uptime -p 2>/dev/null || uptime | sed 's/.*up \([^,]*\), .*/\1/')"
CWD_VAL="$(pwd)"

# CPU Information extraction (portable between /proc/cpuinfo and lscpu)
if [ -f /proc/cpuinfo ]; then
    CPU_MODEL="$(grep -m1 'model name' /proc/cpuinfo | cut -d':' -f2 | sed 's/^[ \t]*//')"
    CPU_CORES="$(grep -c '^processor' /proc/cpuinfo || echo '1')"
    if [ -z "${CPU_MODEL}" ]; then
        CPU_MODEL="$(uname -m)"
    fi
    CPU_INFO="${CPU_MODEL} (${CPU_CORES} core(s))"
elif command -v lscpu >/dev/null 2>&1; then
    CPU_INFO="$(lscpu | grep -m1 'Model name' | cut -d':' -f2 | sed 's/^[ \t]*//')"
else
    CPU_INFO="$(uname -m)"
fi

# Memory Information extraction
if command -v free >/dev/null 2>&1; then
    MEM_TOTAL="$(free -h 2>/dev/null | awk '/^Mem:/ {print $2}')"
    MEM_USED="$(free -h 2>/dev/null | awk '/^Mem:/ {print $3}')"
    MEM_FREE="$(free -h 2>/dev/null | awk '/^Mem:/ {print $4}')"
    MEM_AVAIL="$(free -h 2>/dev/null | awk '/^Mem:/ {print $7}')"
    MEM_INFO="Total: ${MEM_TOTAL}, Used: ${MEM_USED}, Free: ${MEM_FREE}, Available: ${MEM_AVAIL:-$MEM_FREE}"
elif [ -f /proc/meminfo ]; then
    MEM_TOTAL_KB="$(grep -i 'MemTotal:' /proc/meminfo | awk '{print $2}')"
    MEM_AVAIL_KB="$(grep -i 'MemAvailable:' /proc/meminfo | awk '{print $2}')"
    MEM_INFO="Total: $((MEM_TOTAL_KB / 1024)) MB, Available: $((MEM_AVAIL_KB / 1024)) MB"
else
    MEM_INFO="Memory info unavailable"
fi

# Formatted Output
echo "============================================================"
echo "                SYSTEM DIAGNOSTIC INFORMATION               "
echo "============================================================"
printf "%-25s: %s\n" "Hostname" "${HOSTNAME_VAL}"
printf "%-25s: %s\n" "Current User" "${USER_VAL}"
printf "%-25s: %s\n" "Date/Time" "${DATETIME_VAL}"
printf "%-25s: %s\n" "Operating System" "${OS_VAL}"
printf "%-25s: %s\n" "Kernel Version" "${KERNEL_VAL}"
printf "%-25s: %s\n" "System Uptime" "${UPTIME_VAL}"
printf "%-25s: %s\n" "CPU Information" "${CPU_INFO}"
printf "%-25s: %s\n" "Memory Information" "${MEM_INFO}"
printf "%-25s: %s\n" "Current Directory" "${CWD_VAL}"
echo "============================================================"

log_operation "Successfully collected and displayed system-info (Host: ${HOSTNAME_VAL}, User: ${USER_VAL})."
exit 0
