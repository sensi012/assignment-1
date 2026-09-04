# Assignment 1: Linux Diagnostic Toolkit (Bash & Networking)

A modular, production-ready Linux diagnostic toolkit written in Bash. This toolkit inspects runtime system vitals, evaluates filesystem capacity against user-defined alert thresholds, performs host resolution and network reachability checks, and logs all events with structured timestamps.

---

## Repository Structure

```text
assignment-1/
├── README.md             # Project documentation, usage guide, and assumptions
├── system-info.sh        # System metrics collector (CPU, memory, uptime, OS, etc.)
├── disk-check.sh         # Disk usage validator with threshold alert logic
├── network-check.sh      # DNS resolution, interface inspection & TCP port checker
├── grade.sh              # Local automated grading script
└── logs/
    ├── .gitkeep          # Git retention marker
    ├── system-info.log   # Runtime logs for system-info.sh
    ├── disk-check.log    # Runtime logs for disk-check.sh
    └── network-check.log # Runtime logs for network-check.sh
```

---

## 1. Installation & Setup

### Prerequisites
- Operating System: Any POSIX-compliant Linux distribution (Ubuntu, Debian, Alpine, RHEL/Rocky, WSL2, etc.).
- Shell: `bash` version 4.0 or higher.
- Standard Utilities: `coreutils`, `iproute2` (or `net-tools`), `ping` (`iputils-ping`), `bind-tools` or `dnsutils` (for DNS lookups), `netcat` (optional, script includes native `/dev/tcp` fallback).

### Making Scripts Executable
Run the following command from the repository root:
```bash
chmod +x *.sh logs/ 2>/dev/null || true
```

---

## 2. Tool Usage & Command Reference

### A. System Information Collector (`system-info.sh`)
Collects and formats live runtime system parameters.

```bash
./system-info.sh
```

**Collected Runtime Metrics:**
- **Hostname**: Real-time machine name (`hostname` / `uname -n`)
- **Current User**: Effective executing user (`whoami` / `id -un`)
- **Date/Time**: Formatted local time and timezone (`date`)
- **Operating System**: OS name and distribution release (`/etc/os-release`)
- **Kernel Version**: Active Linux kernel release (`uname -r`)
- **System Uptime**: Formatted system uptime (`uptime -p`)
- **CPU Information**: Model name and core count (`/proc/cpuinfo` / `lscpu`)
- **Memory Information**: Total, used, free, and available RAM (`free -h` / `/proc/meminfo`)
- **Current Directory**: Absolute working directory (`pwd`)

---

### B. Disk Usage Checker (`disk-check.sh`)
Checks filesystem utilization against an alert threshold.

```bash
./disk-check.sh <threshold> [path]
```

- `<threshold>`: Required. An integer between `1` and `100` representing percentage capacity limit.
- `[path]`: Optional. The target filesystem path or mount point to inspect. Defaults to `/`.

**Examples:**
```bash
# Check root filesystem with 80% threshold
./disk-check.sh 80

# Check custom mount point /var with 50% threshold
./disk-check.sh 50 /var

# Expect exit code 1 if threshold is exceeded
./disk-check.sh 5 /
echo "Exit code: $?" # Returns 1
```

**Exit Codes:**
- `0`: Disk usage is strictly below the threshold.
- `1`: Disk usage reached or exceeded the specified threshold.
- `2`: Invalid argument or parameter (e.g. non-integer threshold, threshold out of range `1-100`, nonexistent path).

---

### C. Network Diagnostics Tool (`network-check.sh`)
Performs host validation, DNS resolution, ICMP ping checks, interface enumeration, and TCP socket testing.

```bash
./network-check.sh <hostname-or-ip> [port]
```

- `<hostname-or-ip>`: Required. Target domain or IPv4/IPv6 address.
- `[port]`: Optional. Target TCP port number (`1-65535`).

**Examples:**
```bash
# Basic network check on domain
./network-check.sh google.com

# Check specific port connectivity (e.g. HTTPS port 443)
./network-check.sh github.com 443

# Check loopback interface
./network-check.sh 127.0.0.1 22
```

**Exit Codes:**
- `0`: All requested diagnostic checks succeeded (DNS resolved, ping replied, port open).
- `1`: Operational failure (host unreachable, ping timeout, or port closed).
- `2`: Invalid input or argument error (missing host, non-numeric port, port out of range `1-65535`).

---

## 3. Logging Strategy

All diagnostic tools automatically append timestamped operational records to dedicated log files located in the `logs/` directory:
- `logs/system-info.log`
- `logs/disk-check.log`
- `logs/network-check.log`

**Log Entry Format:**
```text
[YYYY-MM-DD HH:MM:SS] [SCRIPT-NAME] Description of the operation and status
```

---

## 4. Automated Testing & Grading

Run the automated grading suite to test all components against the 100-point rubric:
```bash
chmod +x grade.sh *.sh
./grade.sh
```

### Rubric Breakdown:
| Category | Points | Description |
| :--- | :--- | :--- |
| **Linux commands** | 20 | Runtime system vitals extraction (CPU, RAM, kernel, uptime) |
| **Bash scripting** | 25 | Threshold comparison, `df -P` parsing, exit code handling |
| **Networking** | 20 | Host resolution, ping connectivity, TCP port probes |
| **Error handling** | 10 | Defensive bounds validation, exit code 2 on invalid inputs |
| **Logging** | 10 | Timestamped audit entries written under `logs/` |
| **Git workflow** | 10 | >= 5 meaningful commits, non-main feature branch, merged |
| **README** | 5 | Setup, usage, testing, and assumptions clearly detailed |
| **Total** | **100** | Full compliance with assignment brief |

---

## 5. Assumptions

1. **Linux Environment**: The scripts are designed to execute in standard POSIX-compatible Linux environments (such as Ubuntu 22.04+, Debian 12, Alpine 3.19+, or WSL2).
2. **Network Reachability**: Ping (ICMP) checks assume outbound ICMP packets are not blocked by local firewalls. If ICMP is blocked, the script clearly flags it and continues with TCP port testing if a port was supplied.
3. **No Cloud Dependencies**: All tools run purely with local Linux utilities and require no external cloud accounts or APIs.

---

## 6. Git Workflow & Version Control History

This repository followed strict Git hygiene:
- Initialized with main branch `main`.
- Created feature branch `feature/diagnostics` to implement diagnostic tools.
- Committed multiple incremental, well-documented commits with conventional commit messages.
- Merged `feature/diagnostics` into `main`.
