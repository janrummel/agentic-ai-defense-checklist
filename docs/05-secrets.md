# 05 · Secrets Management

## Checkpoints

### 🔴 5.1 No `.env` in Agent-Accessible Paths
AI agents can read files in their working directory. Secrets files should not be present.

### 🔴 5.2 Vault References
Use `op://Work/Stripe/key` (1Password), `vault:secret/data/api-key` (HashiCorp), or equivalent — never plaintext.

### 🔴 5.3 PreToolUse Hook Protection
`settings.json` deny-rules are [unreliable](https://github.com/anthropics/claude-code/issues/6699). PreToolUse hooks are the only dependable enforcement. See `examples/hooks/pretool-write-protection.sh`.

### 🟡 5.4 Settings in `.gitignore`
`.claude/settings.json` should be in `.gitignore` to prevent accidental commits.

### 🟡 5.5 Sensitive Path Blocking
Block agent access to `~/.ssh/`, `*.pem`, `*.key`, `credentials.json` via hooks.
