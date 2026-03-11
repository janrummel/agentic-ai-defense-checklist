# Claude Code Security Audit v2 — Lilli-Extended

> **How to use**: Copy this entire file and paste it into a new Claude Code session.
> Claude will systematically check your system against all 43 points and produce a prioritized report.

---

You are a security auditor for an agentic AI development system. Systematically check the current system state against the following categories. For each item, report:

- ✅ **IMPLEMENTED** (with evidence / command output)
- ⚠️ **PARTIAL** (what's missing)
- ❌ **NOT IMPLEMENTED** (recommended fix + priority)
- ℹ️ **NOT APPLICABLE** (with justification)

Run the check commands where provided. For review items, inspect the relevant code/config and assess.

---

## CATEGORY 1: API SURFACE & EXPOSURE
### [Lilli Vector: Publicly exposed API docs → 22 unauthenticated endpoints]

1. **Complete endpoint inventory** of all publicly reachable services
   → `nmap -sV <host-ip>` and check for exposed web services
2. **No publicly exposed API documentation** (`/docs`, `/swagger`, `/openapi.json`, `/redoc`, `/api-docs`)
   → `for path in /docs /swagger /openapi.json /redoc /api-docs; do curl -s -o /dev/null -w "%{http_code} $path\n" http://<host>$path; done`
3. **All endpoints require authentication** — including health checks that may leak internal info
   → Test each discovered endpoint without auth token
4. **Rate limiting active** on all endpoints
   → `for i in $(seq 1 100); do curl -s -o /dev/null -w '%{http_code}\n' http://<host>/api/health; done | sort | uniq -c`
5. **Error responses don't leak internals** (stack traces, DB schemas, internal paths)
   → Test with malformed requests: `curl -s -X POST http://<host>/api/v1/search -d '{"invalid'`

## CATEGORY 2: INJECTION & INPUT VALIDATION
### [Lilli Vector: JSON keys concatenated directly into SQL]

6. **All database queries fully parameterized** — including field names, not just values
   → `grep -rn 'f".*SELECT\|f".*INSERT\|f".*UPDATE\|format.*SELECT\|%s.*SELECT\|\.format.*query' --include="*.py" --include="*.js" --include="*.ts" .`
7. **External input sanitized** before forwarding to tools or databases
   → Review: How does input from messaging platforms flow through to DB/tool calls?
8. **Allowlist for dynamic query field names** — no user-controlled keys in SQL/NoSQL
   → Review: Are there any places where `request.body` keys flow into queries?
9. **MCP tool responses validated** for prompt injection content
   → Review: Are MCP tool responses sanitized before the AI processes them?
10. **No differential error responses** enabling DB schema enumeration
    → Test: Do malformed queries return different error codes/messages that reveal schema info?

## CATEGORY 3: PROMPT & SKILL INTEGRITY
### [Lilli Vector: System prompts stored in same DB as user data — writable]

11. **System prompts / config files under version control** with protected branches
    → `git log --oneline -5 -- CLAUDE.md AGENTS.md 2>/dev/null` and check branch protection
12. **Write-protection hook** for configuration files
    → `cat ~/.claude/settings.json | python3 -c "import sys,json; d=json.load(sys.stdin); print(json.dumps(d.get('hooks',{}), indent=2))" 2>/dev/null`
    → Check if SKILL.md, CLAUDE.md, AGENTS.md are in the protected file list
13. **Prompt integrity hash** verification at startup or in CI
    → `sha256sum CLAUDE.md AGENTS.md skills/*.md 2>/dev/null`
    → Is there a baseline to compare against?
14. **Prompt/config storage separated** from user data stores
    → Review: Where are config files stored? Are they on the same access path as user data?
15. **Skill activation only through manual configuration**
    → Review: Can an agent create and activate new SKILL.md files through tool calls?

## CATEGORY 4: CROSS-USER ISOLATION
### [Lilli Vector: IDOR → access to other employees' search histories]

16. **User data strictly separated** across platforms and tenants
    → Review: Can a Telegram user access WhatsApp conversations of another user?
17. **No sequential or predictable IDs** — UUIDs or equivalent in use
    → Check user/session/resource ID formats in the codebase
18. **RAG queries enforce user/tenant filters**
    → Review: Is there a mandatory where clause or filter for user/tenant in all data queries?
19. **Session tokens cryptographically secure**
    → Review: How are sessions generated and validated?

## CATEGORY 5: SECRETS MANAGEMENT

20. **No `.env` files in workspace root** or agent-accessible paths
    → `find . -name ".env*" -not -path "*/node_modules/*" 2>/dev/null`
21. **Vault references** instead of plaintext secrets
    → `grep -rn 'sk-\|AKIA\|ghp_\|xoxb-\|xoxp-' .env* *.env 2>/dev/null`
22. **PreToolUse hook blocks `.env` access**
    → Check hooks config (NOTE: `settings.json` deny-rules are unreliable per GitHub Issue #6699)
23. **`.claude/settings.json` in `.gitignore`**
    → `grep -r ".claude" .gitignore 2>/dev/null`
24. **Sensitive paths blocked via hook** (`~/.ssh/`, `*.pem`, `*.key`, `credentials.json`)

## CATEGORY 6: MCP SERVER SECURITY

25. **`enableAllProjectMcpServers` is `false`** or unset
    → `cat ~/.claude/settings.json 2>/dev/null | grep "enableAll"`
26. **Only explicitly allowlisted MCP servers** active
    → `cat ~/.claude/settings.json 2>/dev/null | grep -A 10 "enabledMcp"`
27. **Each MCP server assessed** for prompt injection risk via tool responses
    → List all active servers and their tool response types
28. **MCP servers on remote hosts** not directly reachable from public internet
    → `nmap -sV <remote-host-ip>` from external network
29. **MCP transport encrypted** (TLS for HTTP/SSE, stdio for local)
    → Check connection strings in MCP config

## CATEGORY 7: ISOLATION & SANDBOXING

30. **AI tool runs under standard user** (no admin/root)
    → `whoami && groups $USER`
31. **Untrusted repos opened in containers/VMs**
    → `ls .devcontainer/ 2>/dev/null`
32. **Container hardening active** (e.g., `-v /dev/null:/workspace/.env`)
    → `cat .devcontainer/devcontainer.json 2>/dev/null | grep "null"`
33. **SSH keys excluded from agent access**
    → Check if `~/.ssh/` is in hook blocklist

## CATEGORY 8: HOOKS & EXECUTION GATES

34. **PreToolUse bash firewall hook** active
    → Blocks: `rm -rf`, external `curl`, pipe-to-shell patterns
    → `cat ~/.claude/settings.json | python3 -c "import sys,json; d=json.load(sys.stdin); [print(json.dumps(v,indent=2)) for k,v in d.get('hooks',{}).items()]" 2>/dev/null | head -60`
35. **Write-protection extended** to include system prompt/config files
    → Check if SKILL.md/CLAUDE.md/AGENTS.md are in the hook's protected file list
36. **HITL protocol formalized** with explicit thresholds
    → Review: Is there a documented "clarification protocol" with defined thresholds for when the agent must ask vs. proceed?
37. **Audit logging** for all tool calls
    → Check if a logging hook exists
38. **Hook matchers are precise** (not wildcard `*`)
    → Review hook matcher patterns for balance of security and performance

## CATEGORY 9: SUPPLY CHAIN & UPDATES

39. **AI tool on current version**
    → `claude --version 2>/dev/null && npm list -g @anthropic-ai/claude-code 2>/dev/null`
40. **npm/pip lifecycle scripts disabled** by default
    → `npm config get ignore-scripts 2>/dev/null`
41. **No PII/PHI/production data** in agent context
    → Review: Are customer data files loaded into Claude sessions?
42. **Transcript retention limited** (7–14 days recommended)
    → `ls -la ~/.claude/transcripts/ 2>/dev/null | wc -l` and check oldest files
43. **Monthly settings audit process** documented
    → Is there a recurring review of security configuration?

---

## OUTPUT FORMAT

### Executive Summary
- **Score**: X of 43 implemented
- **Critical gaps** (🔴): [list]
- **Lilli-specific risks**: Which of the 4 Lilli attack vectors apply to this system?

### Detail Report
For each item: Status + Finding + Recommended fix (if needed)

### Prioritized Roadmap
1. **IMMEDIATE** (this week): [critical items]
2. **SHORT-TERM** (2 weeks): [high-priority items]
3. **MEDIUM-TERM** (1 month): [remaining items]
