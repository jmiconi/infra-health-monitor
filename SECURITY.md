# Security

This repository is intended to be safe for public use and portfolio review.

## Do not commit

Never store the following in this repository:

- production credentials or tokens
- private keys or certificates
- real internal DNS names
- production IP addresses
- customer or employee data
- organization-specific configuration exports

## Runtime configuration

The monitor loads its environment-specific values from a file outside the repository:

```text
/etc/infra-monitor/infra-monitor.secrets
```

Keep that file readable only by the required privileged context. A typical baseline is:

```bash
chmod 600 /etc/infra-monitor/infra-monitor.secrets
chown root:root /etc/infra-monitor/infra-monitor.secrets
```

The file under `examples/` contains placeholders only and exists to document the expected variables.

## Public examples

Documentation and sample output should use synthetic names such as:

```text
db.example.internal
files.example.internal
192.0.2.10
```

Do not copy production logs into issues or documentation without sanitizing them first.