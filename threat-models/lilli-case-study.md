# Case Study: The McKinsey/Lilli Breach (March 2026)

## Summary

On March 9, 2026, security startup CodeWall.ai publicly disclosed that their autonomous offensive AI agent had compromised McKinsey's internal AI platform **Lilli** within 2 hours, achieving full read and write access to the production database — without credentials, insider knowledge, or human involvement.

> **Important context**: CodeWall sells offensive AI security tools. This disclosure also functions as a product demonstration. Independent reporting (The Register, Edward Kiledjian) has described the core vulnerability as credible, while noting the full scope of impact is not yet independently verified. This case study treats the technical attack chain as credible and the claimed data scope as alleged.

## What Is Lilli?

Lilli is McKinsey's internal generative AI platform, launched in 2023. It provides chat, document analysis, and RAG-powered search across decades of proprietary research and over 100,000 internal documents. Approximately 72% of McKinsey's 43,000+ employees use it, processing over 500,000 prompts per month.

The platform is named after Lillian Dombrowski, the first professional woman hired by McKinsey in 1945.

## The Attack Chain

### Phase 1: Reconnaissance (Automated)

CodeWall's agent began with only a domain name. It:

1. Mapped the attack surface autonomously
2. Found publicly exposed API documentation
3. Identified 200+ endpoints, fully documented
4. Determined that **22 endpoints required no authentication**

### Phase 2: Exploitation

One of the unauthenticated endpoints accepted user search queries and wrote them to the database. The implementation had a subtle but critical flaw:

- **Values** in the JSON payload were parameterized (safe)
- **Keys** (field names) in the JSON payload were concatenated directly into SQL (vulnerable)

This created a SQL injection path that traditional scanners — including OWASP ZAP — did not detect. The field-name injection is a less common variant that many static analysis tools are not configured to catch.

The agent then performed blind error-based probing, iterating through payloads until production data was returned.

### Phase 3: Data Access (Alleged)

According to CodeWall's disclosure, the agent accessed:

- 46.5 million chat messages (strategy, M&A, client engagements — plaintext)
- 728,000 files containing confidential client data
- 57,000 user accounts
- 384,000 AI assistants and 94,000 workspaces
- System prompts and model configurations
- 3.68 million RAG document chunks (with S3 paths and metadata)
- 1.1 million files and 217,000 agent messages routed through external AI APIs

### Phase 4: IDOR Chaining

The agent combined the SQL injection with an IDOR (Insecure Direct Object Reference) vulnerability to access individual employees' search histories, revealing what specific people were actively working on.

### Phase 5: Write Access (Most Critical)

The SQL injection was **not read-only**. Lilli's system prompts — the instructions controlling how the AI behaves — were stored in the same database. An attacker with write access could have:

- **Poisoned advice**: Subtly altered financial models, strategic recommendations, or risk assessments
- **Exfiltrated data via output**: Instructed the AI to embed confidential information into responses
- **Removed guardrails**: Stripped safety instructions so the AI would disclose internal data
- **Maintained silent persistence**: Modified prompts leave no log trail, no file changes, no process anomalies

## Timeline

| Date | Event |
|------|-------|
| Feb 28, 2026 | CodeWall agent discovers the vulnerability |
| Mar 1, 2026 | Responsible disclosure email sent to McKinsey security team |
| Mar 2, 2026 | McKinsey patches all unauthenticated endpoints, takes dev environment offline, blocks API docs |
| Mar 9, 2026 | CodeWall publishes blog post; The Register reports independently |

## McKinsey's Response

McKinsey acknowledged the issues and stated: their investigation, supported by a third-party forensics firm, found **no evidence that client data or confidential information were accessed by the researcher or any unauthorized third party**.

## Lessons for Agentic AI Systems

### 1. API Documentation Is Attack Surface

Publicly exposed Swagger/OpenAPI documentation gives an attacker a complete map. This is amplified when the attacker is an AI agent that can systematically process and test every documented endpoint.

**Mitigation**: Remove public API documentation from production. If documentation must be accessible, gate it behind authentication.

### 2. Field-Name Injection Is Underscanned

Most SQL injection scanners focus on value injection. Lilli's implementation parameterized values correctly but concatenated JSON keys into SQL — a pattern many security tools don't flag.

**Mitigation**: Allowlist valid field names. Never construct queries using user-supplied keys, even when values are parameterized.

### 3. System Prompts Are Crown Jewels

Storing system prompts in the same database as user data means any database compromise is also a prompt compromise. Write access to prompts is equivalent to controlling the AI's behavior for all users.

**Mitigation**: Store system prompts separately from user data. Implement integrity verification. Monitor for unexpected prompt changes.

### 4. Autonomous Agents Change the Threat Model

The attack was fully automated — from target selection to exploitation. This means the same attack can be run against thousands of targets simultaneously. The cost of sophisticated attacks drops while the scale goes up.

**Mitigation**: Assume your system will be probed by autonomous agents. Design security controls for machine-speed attacks, not human-speed ones.

### 5. Traditional Scanners Are Insufficient

OWASP ZAP did not flag the vulnerability. The agent found it because it doesn't follow checklists — it maps, probes, chains, and escalates, like a skilled human attacker but faster.

**Mitigation**: Supplement traditional scanning with adversarial testing that mimics agentic behavior: automated reconnaissance, creative payload generation, and multi-step exploit chaining.

## Sources

- [CodeWall.ai: "How We Hacked McKinsey's AI Platform"](https://codewall.ai/blog/how-we-hacked-mckinseys-ai-platform)
- [The Register: "AI agent hacked McKinsey chatbot for read-write access"](https://www.theregister.com/2026/03/09/mckinsey_ai_chatbot_hacked/)
- [Edward Kiledjian: Independent Analysis](https://kiledjian.com/2026/03/10/codewall-says-it-hacked-mckinseys.html)
- [CXOToday: "McKinsey's AI chatbot hack reveals the security risks agentic AI poses"](https://cxotoday.com/daily-news/mckinseys-ai-chatbot-hack-reveals-the-security-risks-agentic-ai-poses/)

---

*This case study is based on publicly available information as of March 11, 2026. It is intended for educational purposes and to inform defensive security practices.*
