#!/usr/bin/env bash
# ==============================================================================
# disk-check.sh - Disk Usage Diagnostic and Threshold Alert
#
# Usage:
#   ./disk-check.sh <threshold> [path]
#
# Arguments:
#   <threshold> : Required. Integer from 1 to 100.
#   [path]      : Optional. Filesystem path to evaluate. Defaults to "/".
#
# Exit Codes:
#   0 : Disk usage is strictly below the threshold.
#   1 : Disk usage reached or exceeded the threshold.
#   2 : Invalid input or argument error.
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="${SCRIPT_DIR}/logs"
LOG_FILE="${LOG_DIR}/disk-check.log"

mkdir -p "${LOG_DIR}"

log_operation() {
    local timestamp
    timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
    echo "[${timestamp}] [DISK-CHECK] $1" >> "${LOG_FILE}"
}

usage() {
    echo "Usage: $0 <threshold> [path]"
    echo "  <threshold> : Integer from 1 to 100 (percentage limit)"
    echo "  [path]      : Filesystem path to check (default: /)"
}

# Validate argument count
if [ $# -lt 1 ] || [ $# -gt 2 ]; then
    echo "Error: Invalid number of arguments." >&2
    usage >&2
    log_operation "ERROR: Invalid argument count ($# provided). Expected 1 or 2."
    exit 2
fi

THRESHOLD="$1"
TARGET_PATH="${2:-/}"

# Validate threshold is an integer
if ! [[ "${THRESHOLD}" =~ ^[0-9]+$ ]]; then
    echo "Error: Threshold '${THRESHOLD}' is not a valid positive integer." >&2
    usage >&2
    log_operation "ERROR: Non-integer threshold '${THRESHOLD}' provided."
    exit 2
fi

# Validate threshold range 1 to 100
if [ "${THRESHOLD}" -lt 1 ] || [ "${THRESHOLD}" -gt 100 ]; then
    echo "Error: Threshold must be between 1 and 100. Provided: ${THRESHOLD}" >&2
    usage >&2
    log_operation "ERROR: Threshold ${THRESHOLD} out of range [1-100]."
    exit 2
fi

# Validate target path existence
if [ ! -e "${TARGET_PATH}" ]; then
    echo "Error: Target path '${TARGET_PATH}' does not exist." >&2
    usage >&2
    log_operation "ERROR: Target path '${TARGET_PATH}' does not exist."
    exit 2
fi

# Query disk usage using POSIX-standard df -P
DF_OUTPUT="$(df -P "${TARGET_PATH}" 2>/dev/null || true)"
if [ -z "${DF_OUTPUT}" ]; then
    echo "Error: Unable to inspect filesystem for path '${TARGET_PATH}'." >&2
    log_operation "ERROR: df failed on path '${TARGET_PATH}'."
    exit 2
fi

# Parse percentage and mount point
USAGE_PERCENT_STR="$(echo "${DF_OUTPUT}" | awk 'NR==2 {print $5}')"
USAGE_PERCENT="${USAGE_PERCENT_STR%%%}"
MOUNT_POINT="$(echo "${DF_OUTPUT}" | awk 'NR==2 {print $6}')"
FILESYSTEM="$(echo "${DF_OUTPUT}" | awk 'NR==2 {print $1}')"

echo "============================================================"
echo "                  DISK USAGE CHECK REPORT                   "
echo "============================================================"
printf "%-25s: %s\n" "Checked Path" "${TARGET_PATH}"
printf "%-25s: %s\n" "Filesystem" "${FILESYSTEM}"
printf "%-25s: %s\n" "Mount Point" "${MOUNT_POINT}"
printf "%-25s: %s%%\n" "Current Disk Usage" "${USAGE_PERCENT}"
printf "%-25s: %s%%\n" "Configured Threshold" "${THRESHOLD}"
echo "------------------------------------------------------------"

if [ "${USAGE_PERCENT}" -ge "${THRESHOLD}" ]; then
    echo "STATUS: WARNING - Disk usage (${USAGE_PERCENT}%) reached or exceeded threshold (${THRESHOLD}%)."
    echo "============================================================"
    log_operation "WARNING: Path '${TARGET_PATH}' usage ${USAGE_PERCENT}% >= threshold ${THRESHOLD}%. Exit 1."
    exit 1
else
    echo "STATUS: OK - Disk usage (${USAGE_PERCENT}%) is below threshold (${THRESHOLD}%)."
    echo "============================================================"
    log_operation "OK: Path '${TARGET_PATH}' usage ${USAGE_PERCENT}% < threshold ${THRESHOLD}%. Exit 0."
    exit 0
fi
