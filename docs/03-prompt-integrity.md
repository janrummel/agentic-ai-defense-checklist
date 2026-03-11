# 03 · Prompt & Skill Integrity

> **Lilli lesson**: System prompts were stored in the same database as user data — and the SQL injection gave write access. An attacker could silently rewrite how the AI behaves for all users.

## Why This Matters

In agentic AI systems, system prompts and configuration files (SKILL.md, CLAUDE.md, AGENTS.md) are equivalent to code. Modifying them changes the system's behavior without any traditional deployment, code review, or audit trail. This makes prompt storage a tier-one security target.

## Checkpoints

### 🔴 3.1 Version Control with Protected Branches

All system prompt and configuration files must be under version control. Changes should require pull request review — just like code changes.

### 🔴 3.2 Write-Protection Hooks

PreToolUse hooks should block automated writes to configuration files. See `examples/hooks/pretool-write-protection.sh` for a reference implementation.

### 🟡 3.3 Integrity Hash Verification

Generate SHA256 hashes of all prompt/config files and verify them at startup or in CI. See `examples/ci/prompt-integrity-check.sh`.

### 🔴 3.4 Separate Storage

System prompts must not be stored in the same database or storage layer as user data. If your database is compromised, your prompts should remain intact.

### 🟡 3.5 Manual-Only Skill Activation

New skills/plugins should only be activatable through manual configuration changes, never through user input or AI tool calls.

## Key Principle

**Treat prompt files as source code.** They control system behavior. Apply the same change management, review, and integrity verification you would apply to production code.
