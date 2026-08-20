# Infra Health Monitor

A small, auditable infrastructure health-check service built with **Bash + systemd**.

The project monitors basic availability and connection latency for critical infrastructure dependencies without requiring a large monitoring stack on the host.

Current checks cover:

- SQL Server TCP connectivity
- SMB / DFS TCP connectivity
- configurable warning and critical latency thresholds
- configuration validation before checks run

## Why this project exists

Sometimes a full observability platform is unnecessary for a very specific operational question:

> Can this server reach the infrastructure services it depends on, and how long does that connection take?

Infra Health Monitor provides that answer using standard Linux tooling, explicit exit codes and journal-friendly output.

## Runtime model

```text
┌──────────────────────┐
│   systemd service    │
└──────────┬───────────┘
           ▼
┌──────────────────────┐
│      monitor.sh      │
│ config validation    │
│ TCP checks + latency │
└───────┬────────┬─────┘
        │        │
        ▼        ▼
   SQL Server   SMB/DFS
        │
        ▼
 stdout / stderr
        │
        ▼
    journalctl
```

## Design goals

- minimal dependencies
- easy to audit
- simple failure semantics
- secrets kept outside source control
- native systemd operation
- useful logs for troubleshooting
- easy extension with additional checks

## Status semantics

The script reports explicit health states based on configurable latency thresholds.

| Condition | Result |
|---|---|
| Connection succeeds below warning threshold | `OK` |
| Connection succeeds above warning threshold | `WARNING` |
| Connection exceeds critical threshold | `CRITICAL` |
| Connection fails / times out | `CRITICAL` |
| Required configuration is missing | fatal configuration error |

Critical conditions exit with code `2`, making the script straightforward to integrate with service supervision or external automation.

## Repository structure

```text
infra-health-monitor/
├── monitor.sh
├── infra-health-monitor.service
├── examples/
│   ├── secrets.env.example
│   └── sample-output.log
├── SECURITY.md
├── .gitignore
└── readme.md
```

## Configuration

Runtime configuration is loaded from an external secrets/configuration file rather than embedded in the script.

Example:

```bash
MONITOR_ENV=lab
LOG_PREFIX=infra-monitor

DB_HOST=db.example.internal
DB_PORT=1433
DB_TIMEOUT=3
DB_WARN_MS=200
DB_CRIT_MS=1000

DFS_MODE=tcp
DFS_HOST=files.example.internal
DFS_PORT=445
DFS_TIMEOUT=3
DFS_WARN_MS=200
DFS_CRIT_MS=1000
```

Use `examples/secrets.env.example` as the template. Never commit the real runtime file.

## Installation

### 1. Create directories

```bash
sudo install -d -m 0755 /opt/infra-monitor
sudo install -d -m 0750 /etc/infra-monitor
```

### 2. Install the script

```bash
sudo install -m 0755 monitor.sh /opt/infra-monitor/monitor.sh
```

### 3. Create the service account

```bash
sudo useradd --system --shell /usr/sbin/nologin svc_monitor
```

### 4. Create runtime configuration

Copy the example and edit it for the environment:

```bash
sudo cp examples/secrets.env.example /etc/infra-monitor/infra-monitor.secrets
sudo chmod 600 /etc/infra-monitor/infra-monitor.secrets
sudo chown root:root /etc/infra-monitor/infra-monitor.secrets
```

### 5. Install the systemd unit

```bash
sudo cp infra-health-monitor.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now infra-health-monitor.service
```

## Operations

Check service state:

```bash
systemctl status infra-health-monitor.service
```

Follow logs:

```bash
journalctl -u infra-health-monitor.service -f
```

Run the check directly for troubleshooting:

```bash
sudo -u svc_monitor /opt/infra-monitor/monitor.sh
```

## Example output

```text
[infra-monitor] 2026-08-20 10:00:00 - Environment validation OK
[infra-monitor] 2026-08-20 10:00:00 - [DB] Starting TCP connectivity check to db.example.internal:1433
[infra-monitor] 2026-08-20 10:00:00 - [DB] latency=12ms status=OK
[infra-monitor] 2026-08-20 10:00:00 - [DFS] Checking TCP connectivity to files.example.internal:445
[infra-monitor] 2026-08-20 10:00:00 - [DFS] latency=8ms status=OK
[infra-monitor] 2026-08-20 10:00:00 - GLOBAL STATUS: OK
```

## Security model

Real credentials, internal addresses and organization-specific values belong in the external runtime configuration and must not be stored in Git.

See [SECURITY.md](SECURITY.md).

## Roadmap

Potential extensions:

- real SQL query health checks
- accumulated warning / degradation state
- structured JSON output
- integration with Grafana/Loki or another event pipeline
- notification hooks
- additional infrastructure dependency checks

## Portfolio context

This project demonstrates a pattern I use frequently in infrastructure work: **small, transparent automation that answers a precise operational question and behaves predictably under failure**.

---

Built by [Julián Miconi](https://github.com/jmiconi).