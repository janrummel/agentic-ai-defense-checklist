# 06 · MCP Server Security

## Checkpoints

### 🔴 6.1 No Blanket Server Enable
`enableAllProjectMcpServers: true` allows any MCP server found in project config to run. This is equivalent to auto-running untrusted code.

### 🔴 6.2 Explicit Allowlist
Only MCP servers you have vetted and explicitly enabled should be active.

### 🔴 6.3 Prompt Injection Assessment
MCP servers return tool responses that the AI processes. A compromised or malicious server can craft responses that manipulate the AI into executing unintended actions. Assess each server for this risk.

### 🟡 6.4 Network Isolation
MCP servers on remote hosts should not be directly reachable from the public internet. Use VPN, SSH tunnels, or private networking.

### 🟡 6.5 Transport Encryption
HTTP/SSE-based MCP connections must use TLS. Local stdio connections are inherently secure but verify no network proxying occurs.
