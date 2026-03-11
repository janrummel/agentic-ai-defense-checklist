# Agentic AI Threat Model

## Scope

This threat model covers AI systems that **autonomously use tools** — including but not limited to:

- LLM-based coding agents (Claude Code, Cursor, Windsurf, Copilot)
- AI platforms with RAG, document analysis, and search (like McKinsey's Lilli)
- Multi-agent orchestration systems with MCP servers or equivalent tool protocols
- AI gateways connecting LLMs to messaging platforms (Slack, Teams, WhatsApp bots)
- Autonomous AI workflows with minimal human oversight

## Attacker Profiles

### Profile A: Autonomous Offensive Agent

As demonstrated by the Lilli breach, autonomous AI agents can now conduct full attack chains:

- **Reconnaissance**: Systematic API mapping, documentation discovery, endpoint enumeration
- **Exploitation**: Creative payload generation, multi-step exploit chaining, blind probing
- **Persistence**: Prompt manipulation, silent behavior modification
- **Speed**: Hours, not days. Continuous, not periodic.

### Profile B: Malicious MCP Server / Tool Provider

A compromised or intentionally malicious tool provider can:

- Return crafted responses that manipulate the AI agent's behavior (prompt injection via tool response)
- Exfiltrate data passed to the tool by the agent
- Modify data the agent writes through the tool

### Profile C: Malicious User Input

Users (or compromised user accounts) can submit:

- Injection payloads through chat interfaces or API calls
- Adversarial prompts designed to override system instructions
- Crafted documents that, when processed by RAG, inject instructions into the AI context

### Profile D: Supply Chain Compromise

- Compromised npm/pip packages executed during AI agent sessions
- Malicious `.claude.md` or equivalent config files in cloned repositories
- Backdoored MCP server packages

---

## Attack Vectors

### V1: Unauthenticated API Endpoints

**Description**: API endpoints accessible without authentication, particularly those that interact with databases or internal systems.

**Lilli example**: 22 of 200+ endpoints required no authentication. One wrote user queries to the database.

**Impact**: Direct database access, data exfiltration, data manipulation.

**Mitigations**:
- Authentication required on all endpoints, no exceptions
- Remove public API documentation from production
- Rate limiting on all endpoints
- Regular endpoint inventory audits

### V2: Input Injection (SQL, NoSQL, Command)

**Description**: User-supplied input incorporated into database queries, system commands, or tool invocations without proper sanitization.

**Lilli example**: JSON keys (field names) concatenated directly into SQL. Values were parameterized, but keys were not.

**Impact**: Full database read/write access, command execution, data destruction.

**Mitigations**:
- Parameterize ALL parts of queries, including field names
- Allowlist valid field names, sort orders, and operators
- Input validation at every boundary (user → API → tool → database)
- Differential error response suppression

### V3: Prompt/Config Tampering

**Description**: Modification of system prompts, configuration files, or skill definitions that control AI behavior.

**Lilli example**: System prompts stored in the same database as user data. Write access to prompts via SQL injection.

**Impact**: AI behavior modification for all users, guardrail removal, silent data exfiltration through altered AI responses.

**Mitigations**:
- Store prompts/configs separately from user data
- Version control with protected branches
- Integrity verification (hash comparison) at startup and in CI
- Write-protection hooks on config files
- Monitoring for unexpected prompt changes

### V4: Cross-User Data Access (IDOR)

**Description**: Accessing other users' data by manipulating identifiers (user IDs, session tokens, resource IDs).

**Lilli example**: IDOR chained with SQL injection to read individual employees' search histories.

**Impact**: Privacy violation, competitive intelligence exposure, targeted social engineering.

**Mitigations**:
- Use UUIDs instead of sequential IDs
- Enforce authorization checks at every data access point
- RAG queries must include tenant/user filters
- Session tokens must be cryptographically random

### V5: Prompt Injection via Tool Responses (MCP)

**Description**: A tool (MCP server or equivalent) returns crafted content that, when processed by the AI, causes unintended behavior — such as executing commands, accessing files, or ignoring safety instructions.

**Impact**: Arbitrary action execution through the AI agent, privilege escalation, data exfiltration.

**Mitigations**:
- Treat all tool responses as untrusted input
- Validate/sanitize tool responses before AI processing where possible
- Limit the tools available to the AI based on the current task
- Monitor for unexpected tool-call patterns
- PreToolUse hooks that block dangerous operations regardless of the prompt

### V6: Secrets Leakage

**Description**: AI agents reading, logging, or transmitting secrets (API keys, credentials, tokens) found in the working environment.

**Impact**: Credential compromise, lateral movement, service impersonation.

**Mitigations**:
- No plaintext secrets in agent-accessible paths
- Vault references instead of inline secrets
- PreToolUse hooks blocking access to secret files
- Hook-based enforcement (not `settings.json` deny-rules, which are unreliable)
- Transcript retention limits

### V7: Supply Chain Attacks

**Description**: Malicious code executed during package installation, repository cloning, or tool setup within an AI agent session.

**Impact**: Code execution, persistent backdoors, credential theft.

**Mitigations**:
- Disable npm/pip lifecycle scripts by default
- Open untrusted repositories in containers/VMs
- Container hardening (mount `/dev/null` over `.env`)
- Version pinning and lockfile verification

---

## Risk Matrix

| Vector | Likelihood (with AI agents) | Impact | Priority |
|--------|:--:|:--:|:--:|
| V1: Unauth Endpoints | High | Critical | 🔴 Immediate |
| V2: Input Injection | High | Critical | 🔴 Immediate |
| V3: Prompt Tampering | Medium | Critical | 🔴 Immediate |
| V4: Cross-User Access | Medium | High | 🟠 Short-term |
| V5: MCP Prompt Injection | Medium | High | 🟠 Short-term |
| V6: Secrets Leakage | Medium | High | 🟠 Short-term |
| V7: Supply Chain | Low–Medium | High | 🟡 Planned |

> **Note on likelihood**: All vectors have elevated likelihood when autonomous AI agents are assumed as potential attackers, because agents can systematically probe at machine speed.

---

## Defense-in-Depth Layers

```
┌─────────────────────────────────────────────┐
│  Layer 1: Network & Access Control          │
│  • Auth on all endpoints                    │
│  • No public API docs                       │
│  • Rate limiting                            │
│  • Firewall / network segmentation          │
├─────────────────────────────────────────────┤
│  Layer 2: Input Validation                  │
│  • Parameterized queries (keys AND values)  │
│  • Allowlisted field names                  │
│  • Input sanitization at every boundary     │
├─────────────────────────────────────────────┤
│  Layer 3: Prompt & Config Integrity         │
│  • Separate storage from user data          │
│  • Version control + protected branches     │
│  • Hash verification                        │
│  • Write-protection hooks                   │
├─────────────────────────────────────────────┤
│  Layer 4: Execution Control                 │
│  • PreToolUse hooks (bash firewall)         │
│  • HITL gates for critical operations       │
│  • Audit logging                            │
│  • Tool-call monitoring                     │
├─────────────────────────────────────────────┤
│  Layer 5: Isolation                         │
│  • Container/VM for untrusted code          │
│  • Least-privilege user accounts            │
│  • Secrets in vaults, not files             │
│  • Tenant isolation in data layer           │
└─────────────────────────────────────────────┘
```

---

*This threat model is a living document. Contributions welcome via pull request.*
