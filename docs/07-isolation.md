# 07 · Isolation & Sandboxing

## Checkpoints

### 🔴 7.1 Standard User Account
AI coding tools should never run as admin/root. Principle of least privilege.

### 🟡 7.2 Container Isolation for Untrusted Code
Open repositories from unknown sources in devcontainers or VMs, never directly on the host.

### 🟡 7.3 Container Hardening
Mount `/dev/null` over `.env` in containers: `-v /dev/null:/workspace/.env`

### 🟡 7.4 SSH Key Protection
Block agent access to `~/.ssh/` via PreToolUse hooks.
