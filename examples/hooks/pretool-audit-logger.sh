#!/usr/bin/env bash
# pretool-audit-logger.sh — PostToolUse hook for Claude Code
# Logs all tool calls for security forensics and incident analysis.
#
# Always exits 0 (log-only, never blocks).
#
# Usage in settings.json:
#   "PostToolUse": [{"matcher": "*", "command": "~/.claude/hooks/pretool-audit-logger.sh \"$TOOL_NAME\" \"$TOOL_INPUT\""}]

set -uo pipefail

TOOL_NAME="${1:-unknown}"
TOOL_INPUT="${2:-$(cat /dev/stdin 2>/dev/null || echo '{}')}"

# =============================================================================
# CONFIGURATION
# =============================================================================

LOG_DIR="${CLAUDE_AUDIT_LOG_DIR:-$HOME/.claude/audit}"
LOG_FILE="$LOG_DIR/tool-calls-$(date +%Y-%m-%d).log"
MAX_INPUT_LOG_LENGTH=500  # Truncate long inputs in log
RETENTION_DAYS=14         # Auto-delete logs older than this

# =============================================================================
# SETUP
# =============================================================================

mkdir -p "$LOG_DIR"

# =============================================================================
# LOG ENTRY
# =============================================================================

TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
SESSION_ID="${CLAUDE_SESSION_ID:-$(echo $PPID)}"
WORKING_DIR=$(pwd)

# Truncate long input for log readability
TRUNCATED_INPUT=$(echo "$TOOL_INPUT" | head -c "$MAX_INPUT_LOG_LENGTH")
if [ ${#TOOL_INPUT} -gt $MAX_INPUT_LOG_LENGTH ]; then
    TRUNCATED_INPUT="${TRUNCATED_INPUT}... [truncated, full length: ${#TOOL_INPUT}]"
fi

# Classify risk level
RISK="LOW"
if echo "$TOOL_NAME" | grep -qiE "Bash|Shell|Execute"; then
    RISK="MEDIUM"
    if echo "$TOOL_INPUT" | grep -qiE "curl|wget|rm|chmod|ssh|scp|eval|exec"; then
        RISK="HIGH"
    fi
fi
if echo "$TOOL_NAME" | grep -qiE "Edit|Write|MultiEdit|CreateFile"; then
    if echo "$TOOL_INPUT" | grep -qiE "\.env|\.ssh|\.claude|CLAUDE\.md|SKILL\.md|AGENTS\.md|\.pem|\.key|credentials"; then
        RISK="HIGH"
    fi
fi

# Write structured log entry
cat >> "$LOG_FILE" << EOF
---
timestamp: $TIMESTAMP
session: $SESSION_ID
tool: $TOOL_NAME
risk: $RISK
cwd: $WORKING_DIR
input: |
  $TRUNCATED_INPUT
EOF

# =============================================================================
# HIGH-RISK ALERT (optional: write to separate file for monitoring)
# =============================================================================

if [ "$RISK" = "HIGH" ]; then
    echo "[$TIMESTAMP] ⚠️  HIGH-RISK tool call: $TOOL_NAME in $WORKING_DIR" >> "$LOG_DIR/high-risk.log"
fi

# =============================================================================
# RETENTION: Clean up old logs
# =============================================================================

if [ -d "$LOG_DIR" ]; then
    find "$LOG_DIR" -name "tool-calls-*.log" -mtime +$RETENTION_DAYS -delete 2>/dev/null || true
fi

# Always allow — this is a logger, not a blocker
exit 0
