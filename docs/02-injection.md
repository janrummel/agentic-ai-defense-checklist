# 02 · Injection & Input Validation

> **Lilli lesson**: The JSON values were parameterized (safe), but the JSON keys (field names) were concatenated directly into SQL. This field-name injection variant was missed by OWASP ZAP and traditional scanners.

## Why This Matters

SQL injection is a vulnerability class from 1998. It compromised one of the world's most prestigious consulting firms' AI platform in 2026. The variant was subtle: values were handled correctly, but keys were not. This pattern is common in dynamic query builders that accept user-defined filter/sort parameters.

## Checkpoints

### 🔴 2.1 Full Query Parameterization

Parameterize **everything** — not just values, but also field names, sort orders, table names, and operators.

```bash
# Search for potential injection patterns in Python
grep -rn 'f".*SELECT\|f".*INSERT\|f".*UPDATE\|\.format.*SELECT' --include="*.py" .

# Search in JavaScript/TypeScript
grep -rn 'template.*SELECT\|`.*SELECT.*\${\|\.query.*+' --include="*.js" --include="*.ts" .
```

**Bad** (Lilli pattern):
```python
# Values parameterized, but field name comes from user input
field = request.json.keys()[0]  # User-controlled!
query = f"SELECT * FROM messages WHERE {field} = %s"
cursor.execute(query, (value,))
```

**Good**:
```python
ALLOWED_FIELDS = {"title", "author", "date", "status"}
field = request.json.get("field")
if field not in ALLOWED_FIELDS:
    raise ValueError(f"Invalid field: {field}")
query = f"SELECT * FROM messages WHERE {field} = %s"
cursor.execute(query, (value,))
```

### 🔴 2.2 Input Sanitization at Every Boundary

Messages from external platforms (Slack, WhatsApp, Telegram, webhooks) must be sanitized before being passed to any tool or database query.

### 🔴 2.3 Field Name Allowlists

If your API accepts dynamic field names for filtering, sorting, or searching, maintain an explicit allowlist. Never pass user-supplied strings as column names, table names, or operators.

### 🔴 2.4 MCP Tool Response Validation

MCP (Model Context Protocol) tool responses can contain crafted content that manipulates the AI agent's behavior. This is prompt injection via the tool layer. Treat all tool responses as untrusted input.

### 🟡 2.5 Uniform Error Responses

If different types of malformed input produce different error codes or messages, an attacker can enumerate your database schema through blind error-based probing — exactly what CodeWall's agent did.

Return the same error response for "not found", "invalid field", and "query error".

## Key Principle

**The Lilli vulnerability was not exotic. It was a well-known bug class in an under-checked location.** Check for injection everywhere user input touches a query — including the parts you think are safe because "they're just field names."
