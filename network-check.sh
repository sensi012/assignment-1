#!/usr/bin/env bash
# ==============================================================================
# network-check.sh - Network Diagnostic and Connectivity Tool
#
# Usage:
#   ./network-check.sh <hostname-or-ip> [port]
#
# Arguments:
#   <hostname-or-ip> : Target domain name or IP address to inspect.
#   [port]           : Optional TCP port number (1-65535).
#
# Exit Codes:
#   0 : All requested network checks passed.
#   1 : Operational failure (e.g., host unreachable, resolution failure, closed port).
#   2 : Invalid input or argument error.
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="${SCRIPT_DIR}/logs"
LOG_FILE="${LOG_DIR}/network-check.log"

mkdir -p "${LOG_DIR}"

log_operation() {
    local timestamp
    timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
    echo "[${timestamp}] [NETWORK-CHECK] $1" >> "${LOG_FILE}"
}

usage() {
    echo "Usage: $0 <hostname-or-ip> [port]"
    echo "  <hostname-or-ip> : Target host or IP address (Required)"
    echo "  [port]           : TCP port to verify (Optional, 1-65535)"
}

# 1. Input Validation
if [ $# -lt 1 ] || [ $# -gt 2 ]; then
    echo "Error: Invalid number of arguments." >&2
    usage >&2
    log_operation "ERROR: Invalid argument count ($#). Expected 1 or 2."
    exit 2
fi

TARGET_HOST="$1"
TARGET_PORT="${2:-}"

# Check for empty or invalid host
if [ -z "${TARGET_HOST}" ] || [[ "${TARGET_HOST}" =~ ^[[:space:]]+$ ]] || [[ "${TARGET_HOST}" =~ ^- ]]; then
    echo "Error: Invalid target host provided." >&2
    usage >&2
    log_operation "ERROR: Invalid host argument '${TARGET_HOST}'."
    exit 2
fi

# Validate port if provided
if [ -n "${TARGET_PORT}" ]; then
    if ! [[ "${TARGET_PORT}" =~ ^[0-9]+$ ]]; then
        echo "Error: Port '${TARGET_PORT}' must be an integer." >&2
        usage >&2
        log_operation "ERROR: Non-numeric port '${TARGET_PORT}' provided."
        exit 2
    fi
    if [ "${TARGET_PORT}" -lt 1 ] || [ "${TARGET_PORT}" -gt 65535 ]; then
        echo "Error: Port '${TARGET_PORT}' out of range. Valid range: 1-65535." >&2
        usage >&2
        log_operation "ERROR: Port '${TARGET_PORT}' out of valid range (1-65535)."
        exit 2
    fi
fi

log_operation "Starting network diagnostic for target: '${TARGET_HOST}' (port: ${TARGET_PORT:-none})."

echo "============================================================"
echo "                 NETWORK DIAGNOSTIC REPORT                  "
echo "============================================================"
printf "%-25s: %s\n" "Target Host" "${TARGET_HOST}"
if [ -n "${TARGET_PORT}" ]; then
    printf "%-25s: %s\n" "Target Port" "${TARGET_PORT}"
fi
echo "------------------------------------------------------------"

OVERALL_SUCCESS=true

# 2. Host Resolution
echo "[1] Host Resolution:"
RESOLVED_IPS=""
if command -v getent >/dev/null 2>&1; then
    RESOLVED_IPS="$(getent hosts "${TARGET_HOST}" 2>/dev/null | awk '{print $1}' | sort -u | tr '\n' ' ' || true)"
fi

if [ -z "${RESOLVED_IPS}" ] && command -v host >/dev/null 2>&1; then
    RESOLVED_IPS="$(host -W 2 "${TARGET_HOST}" 2>/dev/null | awk '/has address/ {print $4}' | tr '\n' ' ' || true)"
fi

if [ -z "${RESOLVED_IPS}" ] && command -v nslookup >/dev/null 2>&1; then
    RESOLVED_IPS="$(nslookup "${TARGET_HOST}" 2>/dev/null | awk '/^Address: / {print $2}' | tail -n +2 | tr '\n' ' ' || true)"
fi

if [ -n "${RESOLVED_IPS}" ]; then
    echo "  Resolved Address(es) : ${RESOLVED_IPS}"
    log_operation "Host '${TARGET_HOST}' resolved to: ${RESOLVED_IPS}"
else
    # Check if target is already an IPv4 address
    if [[ "${TARGET_HOST}" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
        echo "  Target is raw IPv4   : ${TARGET_HOST}"
        RESOLVED_IPS="${TARGET_HOST}"
        log_operation "Target is raw IPv4 address: ${TARGET_HOST}"
    else
        echo "  Resolution Failure   : Unable to resolve host '${TARGET_HOST}'"
        log_operation "FAILED to resolve host '${TARGET_HOST}'."
        OVERALL_SUCCESS=false
    fi
fi

echo ""
# 3. Basic Connectivity Check (ICMP Ping / Fallback)
echo "[2] Basic Connectivity Check:"
PING_SUCCESS=false
if command -v ping >/dev/null 2>&1; then
    if ping -c 2 -W 2 "${TARGET_HOST}" >/dev/null 2>&1; then
        echo "  Ping Status          : SUCCESS (Host responded to ICMP echo)"
        log_operation "Ping check to '${TARGET_HOST}' succeeded."
        PING_SUCCESS=true
    else
        echo "  Ping Status          : FAILED (No ICMP reply or ICMP filtered)"
        log_operation "Ping check to '${TARGET_HOST}' failed."
    fi
else
    echo "  Ping Status          : SKIPPED (ping utility not installed)"
    log_operation "Ping skipped (not installed)."
fi

# 4. Network Interface Information
echo ""
echo "[3] Local Network Interfaces:"
if command -v ip >/dev/null 2>&1; then
    ip -brief addr show 2>/dev/null || ip addr show 2>/dev/null
elif command -v ifconfig >/dev/null 2>&1; then
    ifconfig -s 2>/dev/null || ifconfig 2>/dev/null
else
    echo "  Interface tools (ip/ifconfig) unavailable."
fi
log_operation "Inspected local network interfaces."

# 5. TCP Port Connectivity (if requested)
TCP_SUCCESS=true
if [ -n "${TARGET_PORT}" ]; then
    echo ""
    echo "[4] TCP Port Connectivity Check:"
    PORT_OPEN=false
    
    if command -v nc >/dev/null 2>&1; then
        if nc -z -w 3 "${TARGET_HOST}" "${TARGET_PORT}" 2>/dev/null; then
            PORT_OPEN=true
        fi
    else
        # Fallback to bash built-in /dev/tcp
        if timeout 3 bash -c "cat < /dev/null > /dev/tcp/${TARGET_HOST}/${TARGET_PORT}" 2>/dev/null; then
            PORT_OPEN=true
        fi
    fi

    if [ "${PORT_OPEN}" = true ]; then
        echo "  Port ${TARGET_PORT}/TCP         : OPEN / REACHABLE"
        log_operation "Port ${TARGET_PORT}/TCP on '${TARGET_HOST}' is OPEN."
    else
        echo "  Port ${TARGET_PORT}/TCP         : CLOSED / UNREACHABLE"
        log_operation "Port ${TARGET_PORT}/TCP on '${TARGET_HOST}' is CLOSED or filtered."
        TCP_SUCCESS=false
    fi
fi

echo "============================================================"

# Operational exit determination:
# If host failed resolution, or if a port was checked and is closed, or if ping failed and no port was specified
if [ "${OVERALL_SUCCESS}" = false ] || [ "${TCP_SUCCESS}" = false ]; then
    echo "DIAGNOSTIC STATUS: Operational issues detected."
    log_operation "Diagnostic completed with operational failures. Exit 1."
    exit 1
fi

# If ping failed but resolution succeeded and no port was requested, check if ping was the only test
if [ -z "${TARGET_PORT}" ] && [ "${PING_SUCCESS}" = false ]; then
    echo "DIAGNOSTIC STATUS: Host did not respond to ICMP ping."
    log_operation "Diagnostic finished: Host did not reply to ping. Exit 1."
    exit 1
fi

echo "DIAGNOSTIC STATUS: All checks passed successfully."
log_operation "Diagnostic completed successfully. Exit 0."
exit 0
