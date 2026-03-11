# 04 · Cross-User Isolation

> **Lilli lesson**: The agent chained SQL injection with an IDOR vulnerability to access individual employees' search histories.

## Why This Matters

Multi-user AI systems that serve different users, tenants, or platforms must enforce strict data isolation. An IDOR (Insecure Direct Object Reference) vulnerability means one user can access another user's data by manipulating identifiers in API requests.

## Checkpoints

### 🔴 4.1 Strict User Data Separation
Users on different platforms (Slack, WhatsApp, Telegram) or tenants must not be able to access each other's conversations, documents, or search histories.

### 🔴 4.2 Non-Predictable IDs
Use UUIDs or similar non-sequential identifiers. Sequential IDs (user_1, user_2, msg_1001) enable trivial enumeration.

### 🔴 4.3 RAG Tenant Filters
Every RAG query must include a mandatory user/tenant filter. This filter should be enforced at the data access layer, not the application layer.

### 🟡 4.4 Secure Session Tokens
Session tokens must be cryptographically random and of sufficient length. Never derive session identifiers from user-visible information.

## Key Principle

**Authorization checks at the data layer, not just the API layer.** Even if your API correctly checks permissions, a SQL injection bypass (as in Lilli) can skip the API entirely.
