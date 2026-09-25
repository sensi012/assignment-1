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
