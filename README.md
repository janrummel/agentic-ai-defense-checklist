# 🛡 Agentic AI Defense Checklist

**43 security checkpoints for AI agent systems — born from the McKinsey/Lilli breach (March 2026).**

**[Interactive Checklist →](https://janrummel.github.io/agentic-ai-defense-checklist/)**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)

---

## Why This Exists

On March 9, 2026, security startup [CodeWall.ai](https://codewall.ai) disclosed that their autonomous AI agent breached McKinsey's internal AI platform **Lilli** — gaining full read/write access to the production database within **2 hours**. No credentials. No insider knowledge. No human-in-the-loop.

The attack exposed **46.5 million chat messages**, **728,000 confidential files**, **57,000 user accounts**, and **95 writable system prompts** that controlled AI behavior for 40,000+ consultants.

The vulnerability? **SQL injection** — one of the oldest bug classes in the book — hiding in plain sight for over two years.

This repository distills the lessons from that breach (and independent analysis of it) into an **actionable security framework** for anyone building or operating agentic AI systems.

## Origin Story

This started as a personal security audit after the Lilli breach was disclosed on LinkedIn: a systematic check of one real AI agent stack against the attack patterns described by CodeWall.ai. The result turned out to be useful beyond that single setup — a structured, source-backed checklist that any team can apply — so it was open-sourced.

## Who This Is For

- **AI Engineers** building agent systems with tool-use, RAG, or multi-agent orchestration
- **Security Teams** evaluating AI platforms for vulnerabilities traditional scanners miss
- **Platform Teams** operating MCP servers, AI gateways, or LLM-powered internal tools
- **CTOs / Engineering Leads** who need a threat model for agentic AI that goes beyond "prompt injection"

## The 9 Security Categories

| # | Category | Focus | Critical Items |
|---|----------|-------|:-:|
| 01 | [API Surface & Exposure](docs/01-api-surface.md) | Endpoint auth, API doc leaks, rate limiting | 3 |
| 02 | [Injection & Input Validation](docs/02-injection.md) | SQL/NoSQL injection, input sanitization, field-name injection | 4 |
| 03 | [Prompt & Skill Integrity](docs/03-prompt-integrity.md) | System prompt protection, config file write-protection | 3 |
| 04 | [Cross-User Isolation](docs/04-cross-user.md) | IDOR, tenant separation, RAG access control | 3 |
| 05 | [Secrets Management](docs/05-secrets.md) | .env protection, vault references, path blocking | 3 |
| 06 | [MCP Server Security](docs/06-mcp-security.md) | Server allowlisting, prompt injection via tool responses | 3 |
| 07 | [Isolation & Sandboxing](docs/07-isolation.md) | Container isolation, privilege separation | 1 |
| 08 | [Hooks & Execution Gates](docs/08-hooks.md) | PreToolUse hooks, HITL gates, audit logging | 2 |
| 09 | [Supply Chain & Updates](docs/09-supply-chain.md) | Version management, transcript retention, PII controls | 2 |

**→ 43 checkpoints total, 24 marked as critical**

## Quick Start

### 1. Run the Audit Prompt

Copy [`audit/prompt-v2.md`](audit/prompt-v2.md) into a Claude Code session. It will systematically check your system against all 43 points and produce a prioritized report.

### 2. Install Example Hooks

```bash
# Copy the PreToolUse firewall hook to your Claude config
cp examples/hooks/pretool-bash-firewall.sh ~/.claude/hooks/
# See examples/hooks/README.md for setup instructions
```

### 3. Add CI Checks

```bash
# Add the security lint to your CI pipeline
cp examples/ci/security-lint.yml .github/workflows/
```

## Threat Model

For the full threat model mapping the Lilli attack chain to common agentic AI architectures, see:

- [**Lilli Case Study**](threat-models/lilli-case-study.md) — What happened, how, and what it means
- [**Agentic AI Threat Model**](threat-models/agentic-threat-model.md) — Generalized attack vectors for AI agent systems
- [**Attack Tree**](threat-models/attack-tree.md) — Visual decision tree of exploit paths

## Repository Structure

```
├── README.md                          # You are here
├── index.html                         # Interactive checklist (GitHub Pages)
├── checklist.json                     # Machine-readable checklist data
├── CHECKLIST.md                       # All 43 checkpoints in one file
├── audit/
│   └── prompt-v2.md                   # Copy-paste audit prompt for Claude Code
├── docs/
│   ├── 01-api-surface.md              # Detailed guidance per category
│   ├── 02-injection.md
│   ├── ...
│   └── 09-supply-chain.md
├── threat-models/
│   ├── lilli-case-study.md            # McKinsey/Lilli breach analysis
│   ├── agentic-threat-model.md        # Generalized threat model
│   └── attack-tree.md                 # Mermaid attack tree diagram
├── examples/
│   ├── hooks/                         # PreToolUse hook examples
│   │   ├── README.md
│   │   ├── pretool-bash-firewall.sh
│   │   ├── pretool-write-protection.sh
│   │   └── pretool-audit-logger.sh
│   └── ci/                            # CI/CD security templates
│       ├── README.md
│       ├── security-lint.yml          # GitHub Actions workflow
│       └── prompt-integrity-check.sh  # Hash-based config integrity
├── CONTRIBUTING.md
└── LICENSE
```

## Key Insight

> The Lilli breach wasn't caused by an exotic zero-day. It was SQL injection — a vulnerability class from 1998 — in a platform built by one of the world's most prestigious consulting firms, with world-class technology teams and significant security investment.
>
> **It's not the exotic attacks that compromise enterprise AI systems. It's the basics that get overlooked in the rush to deploy.**

The difference now: **AI agents find these basics at machine speed.** What took a human pentester days takes an autonomous agent hours. The attack surface hasn't fundamentally changed — the speed of exploitation has.

## Contributing

Contributions are welcome! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

Priority areas:
- Additional hook examples for other AI coding tools (Cursor, Windsurf, etc.)
- CI templates for other platforms (GitLab CI, CircleCI)
- Translations
- Real-world case studies (anonymized)

## Sources & Credits

- [CodeWall.ai Blog: "How We Hacked McKinsey's AI Platform"](https://codewall.ai/blog/how-we-hacked-mckinseys-ai-platform) (March 9, 2026)
- [The Register: "AI agent hacked McKinsey chatbot for read-write access"](https://www.theregister.com/2026/03/09/mckinsey_ai_chatbot_hacked/) by Jessica Lyons
- [Edward Kiledjian: Independent Analysis](https://kiledjian.com/2026/03/10/codewall-says-it-hacked-mckinseys.html)
- GitHub Issue [#6699](https://github.com/anthropics/claude-code/issues/6699) — `settings.json` deny-rules reliability

## Disclaimer

This checklist is a **diagnostic tool for self-assessment**, not professional security advice. It helps you identify potential gaps — it does not make changes to your system. Review all findings in the context of your own architecture before taking action. The authors accept no liability for actions taken based on this checklist.

The hook scripts in `examples/` are **reference implementations**. Read and understand them before deploying. Test in a non-critical environment first.

## Publishing

https://janrummel.github.io/agentic-ai-defense-checklist/ is served by GitHub Pages straight from branch `main`, folder `/`. No build step: the files are static HTML, CSS and JavaScript.

## License

MIT — see [LICENSE](LICENSE).

---

<p align="center">
  <sub>Built by practitioners, for practitioners. Star ⭐ if this helps secure your AI stack.</sub>
</p>
