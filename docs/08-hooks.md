# 08 · Hooks & Execution Gates

## Checkpoints

### 🔴 8.1 Bash Firewall Hook
Block destructive commands (`rm -rf`), external data transfer (`curl` to non-allowlisted hosts), and pipe-to-shell patterns. See `examples/hooks/pretool-bash-firewall.sh`.

### 🔴 8.2 Extended Write Protection
Write-protection should cover not just secrets files, but also system prompt/config files (SKILL.md, CLAUDE.md, AGENTS.md).

### 🟡 8.3 HITL Protocol as Security Gate
A human-in-the-loop (HITL) "clarification protocol" defines explicit thresholds for when an agent must stop and ask. This is not just a UX feature — it is a security boundary. Define: which actions are NEVER allowed without human confirmation?

Examples: deleting >5 files, modifying public APIs, running database migrations, accessing secrets.

### 🟡 8.4 Audit Logging
Log all tool calls for forensic analysis. See `examples/hooks/pretool-audit-logger.sh`.

### 🟡 8.5 Precise Hook Matchers
Wildcard `*` matchers process every tool call. Use specific matchers (`Bash`, `Edit|Write`) for better performance and clearer intent.
