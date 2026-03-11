# 09 · Supply Chain & Updates

## Checkpoints

### 🔴 9.1 Current Versions
Keep AI tools updated. Known CVEs (e.g., CVE-2025-55284 for Claude Code) are patched in newer versions.

```bash
claude --version
npm list -g @anthropic-ai/claude-code
```

### 🟡 9.2 Disabled Lifecycle Scripts
npm `postinstall` scripts can execute arbitrary code during package installation. Disable by default:

```bash
npm config set ignore-scripts true
```

### 🔴 9.3 No PII in Agent Context
Never load production customer data, PII, or PHI into AI agent sessions.

### 🟡 9.4 Transcript Retention
Session transcripts may contain secrets or sensitive data. Limit retention to 7–14 days.

### 🟡 9.5 Monthly Audit Process
Configuration drift happens. Schedule monthly reviews of security settings, hook configurations, and MCP server lists.
