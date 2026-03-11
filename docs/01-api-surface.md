# 01 · API Surface & Exposure

> **Lilli lesson**: Publicly exposed API documentation with 200+ fully documented endpoints — 22 of which required no authentication — was the entry point for the entire attack chain.

## Why This Matters

An AI agent can process API documentation faster and more thoroughly than any human pentester. Publicly exposed Swagger/OpenAPI specs give an attacker a complete map of your system's capabilities, including endpoints that may have been intended for internal use only.

## Checkpoints

### 🔴 1.1 Complete Endpoint Inventory

Every publicly reachable service should have a documented inventory of endpoints. You can't protect what you don't know exists.

```bash
# Discover open ports and services
nmap -sV <your-host-ip>

# Check common API documentation paths
for path in /docs /swagger /openapi.json /redoc /api-docs /graphql; do
  curl -s -o /dev/null -w "%{http_code} $path\n" http://<host>$path
done
```

### 🔴 1.2 No Public API Documentation

Remove API documentation from production environments. If documentation must be accessible externally, gate it behind authentication.

### 🔴 1.3 All Endpoints Require Authentication

Test every endpoint without authentication tokens. Health check endpoints that return version numbers, environment names, or dependency information are information leaks.

```bash
# Test an endpoint without auth
curl -s -H 'Authorization: ' http://<host>/api/v1/<endpoint>
```

### 🟡 1.4 Rate Limiting

Without rate limiting, an autonomous agent can probe hundreds of endpoints per second.

```bash
# Quick rate limit test: 100 requests in rapid succession
for i in $(seq 1 100); do
  curl -s -o /dev/null -w '%{http_code}\n' http://<host>/api/health
done | sort | uniq -c
```

If all 100 return `200`, rate limiting is likely not active.

### 🟡 1.5 Clean Error Responses

Error responses should not contain stack traces, database schemas, internal file paths, or framework version numbers.

```bash
# Test with malformed input
curl -s -X POST http://<host>/api/v1/search -d '{"invalid'
curl -s http://<host>/api/v1/../../../etc/passwd
```

## Key Principle

**Assume your API will be probed by autonomous agents.** Design error messages, authentication, and rate limiting for machine-speed attacks, not human-speed manual testing.
