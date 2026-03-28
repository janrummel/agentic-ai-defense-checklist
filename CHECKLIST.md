# Agentic AI Security Checklist — All 43 Checkpoints

> Based on the McKinsey/Lilli breach (March 2026) and independent security analysis of agentic AI systems.

Each item is marked with its criticality level:
- 🔴 **CRITICAL** — Must be addressed before production deployment
- 🟡 **RECOMMENDED** — Should be addressed within first month of operation

---

## 01 · API Surface & Exposure

*Lilli lesson: 22 unauthenticated endpoints were the entry point*

- [ ] 🔴 **1.1** Complete endpoint inventory of all publicly reachable services
- [ ] 🔴 **1.2** No publicly exposed API documentation (`/docs`, `/swagger`, `/openapi.json`, `/redoc`)
- [ ] 🔴 **1.3** All endpoints require authentication — including health checks that leak internal info
- [ ] 🟡 **1.4** Rate limiting active on all endpoints
- [ ] 🟡 **1.5** Error responses do not leak internals (stack traces, DB schemas, internal paths)

## 02 · Injection & Input Validation

*Lilli lesson: JSON keys were concatenated directly into SQL — values were parameterized, but field names were not*

- [ ] 🔴 **2.1** All database queries fully parameterized — including field names, sort orders, and table names
- [ ] 🔴 **2.2** External input (messaging platforms, webhooks) is sanitized before forwarding to tools or databases
- [ ] 🔴 **2.3** Allowlist for dynamic query field names — no user-controlled keys in SQL/NoSQL
- [ ] 🔴 **2.4** MCP tool responses validated for prompt injection content
- [ ] 🟡 **2.5** No differential error responses that enable database schema enumeration (blind error-based probing)

## 03 · Prompt & Skill Integrity

*Lilli lesson: System prompts were stored in the same database as user data — and were writable*

- [ ] 🔴 **3.1** System prompts / config files under version control with protected branches
- [ ] 🔴 **3.2** Write-protection hook for configuration files (SKILL.md, CLAUDE.md, AGENTS.md, or equivalent)
- [ ] 🟡 **3.3** Prompt integrity hash verification (SHA256 comparison at startup or CI)
- [ ] 🔴 **3.4** Prompt/config storage physically separated from user data stores
- [ ] 🟡 **3.5** Skill/plugin activation only through manual configuration, never through user input or tool responses

## 04 · Cross-User Isolation

*Lilli lesson: IDOR vulnerability allowed access to other employees' search histories*

- [ ] 🔴 **4.1** User data strictly separated across platforms and tenants
- [ ] 🔴 **4.2** No sequential or predictable IDs — use UUIDs or equivalent
- [ ] 🔴 **4.3** RAG queries enforce user/tenant filters — no cross-tenant data leakage
- [ ] 🟡 **4.4** Session tokens are cryptographically secure and not predictable

## 05 · Secrets Management

- [ ] 🔴 **5.1** No `.env` files in workspace root or agent-accessible paths
- [ ] 🔴 **5.2** Vault references instead of plaintext secrets (1Password, HashiCorp Vault, etc.)
- [ ] 🔴 **5.3** PreToolUse hook blocks `.env` access (`settings.json` deny-rules are unreliable — see [#6699](https://github.com/anthropics/claude-code/issues/6699))
- [ ] 🟡 **5.4** `.claude/settings.json` in `.gitignore`
- [ ] 🟡 **5.5** Sensitive paths (`~/.ssh/`, `*.pem`, `*.key`, `credentials.json`) blocked via hook

## 06 · MCP Server Security

- [ ] 🔴 **6.1** `enableAllProjectMcpServers` is `false` or unset
- [ ] 🔴 **6.2** Only explicitly allowlisted MCP servers active
- [ ] 🔴 **6.3** Each active MCP server assessed for prompt injection risk via tool responses
- [ ] 🟡 **6.4** MCP servers on remote hosts not directly reachable from public internet
- [ ] 🟡 **6.5** MCP transport encrypted (TLS for HTTP/SSE, stdio for local)

## 07 · Isolation & Sandboxing

- [ ] 🔴 **7.1** AI coding tool runs under standard user account (no admin/root)
- [ ] 🟡 **7.2** Untrusted repositories opened in containers or VMs, never directly on host
- [ ] 🟡 **7.3** Container hardening active (e.g., `-v /dev/null:/workspace/.env` mount)
- [ ] 🟡 **7.4** SSH keys excluded from agent access via hook

## 08 · Hooks & Execution Gates

- [ ] 🔴 **8.1** PreToolUse bash firewall hook (blocks `rm -rf`, external `curl`, pipe-to-shell)
- [ ] 🔴 **8.2** Write-protection hook extended to include system prompt/config files
- [ ] 🟡 **8.3** Human-in-the-loop (HITL) protocol formalized as explicit security gate with defined thresholds
- [ ] 🟡 **8.4** Audit logging for all tool calls
- [ ] 🟡 **8.5** Hook matchers precise (not wildcard `*`) to balance security coverage with performance

## 09 · Supply Chain & Updates

- [ ] 🔴 **9.1** AI coding tool on current version (known CVEs patched)
- [ ] 🟡 **9.2** npm/pip lifecycle scripts disabled by default (`--ignore-scripts`)
- [ ] 🔴 **9.3** No PII/PHI/production data in agent context
- [ ] 🟡 **9.4** Transcript/session retention limited (7–14 days)
- [ ] 🟡 **9.5** Monthly settings audit process in place

---

## Scoring

> Updated: 43 → 51 checkpoints, 9 → 11 categories (v2, March 2026)


| Rating | Criteria |
|--------|----------|
| **🟢 Hardened** | All 28 critical items ✅, ≥80% recommended items |
| **🟡 Acceptable** | All 28 critical items ✅, <80% recommended items |
| **🟠 At Risk** | 1–5 critical items missing |
| **🔴 Critical** | 6+ critical items missing |

---

*Last updated: March 2026*

## 10 · Agent Memory Security

*Emerging threat: "Memory Poisoning" — malicious content injected into long-term agent memory through processed documents or indirect prompt injection, permanently altering agent behavior.*

- [ ] 🔴 **10.1** Agent memory entries validated against injection patterns before storage
- [ ] 🔴 **10.2** Memory writes only from trusted sources — external content (web pages, documents, tool responses) never written to memory without sanitization
- [ ] 🟡 **10.3** Memory integrity auditable (hash comparison, diff tracking, or append-only audit trail)

## 11 · Multi-Agent Security

*When orchestrating multiple agents (sub-agents, tool-calling agents), the communication between them becomes an attack surface.*

- [ ] 🔴 **11.1** Sub-agent output verified before use by orchestrating agent (factual spot-checks, not just format validation)
- [ ] 🟡 **11.2** Least privilege per agent — sub-agents have only the permissions needed for their specific task
- [ ] 🟡 **11.3** Agent-to-agent communication authenticated (no spoofed completion events)

## Additions to existing categories

### 02 · Injection & Input Validation
- [ ] 🔴 **2.6** Long-term memory (vector DB, markdown files, conversation history) protected against indirect injection from retrieved documents

### 09 · Supply Chain & Updates
- [ ] 🟡 **9.6** Incident response plan for AI-specific incidents (compromised agent, prompt injection breach, data exfiltration via tool use)
- [ ] 🟡 **9.7** Regular red teaming — manual or automated (e.g., Microsoft PyRIT) — at least quarterly
