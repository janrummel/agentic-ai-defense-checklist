#!/usr/bin/env bash
# pretool-write-protection.sh — PreToolUse hook for Claude Code
# Blocks write/edit operations on protected files and paths.
#
# Exit 0 = allow, Exit 1 = block
#
# Usage in settings.json:
#   "PreToolUse": [{"matcher": "Edit|Write|MultiEdit|CreateFile", "command": "~/.claude/hooks/pretool-write-protection.sh \"$TOOL_INPUT\""}]

set -euo pipefail

INPUT="${1:-$(cat /dev/stdin)}"

# Extract file path from JSON input
FILE_PATH=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    # Different tool types use different field names
    path = data.get('path', data.get('file_path', data.get('filename', '')))
    print(path)
except:
    print('')
" 2>/dev/null || echo "")

if [ -z "$FILE_PATH" ]; then
    # Can't determine path — allow (fail-open for usability, but log)
    exit 0
fi

# =============================================================================
# PROTECTED FILES — exact matches
# =============================================================================

PROTECTED_FILES=(
    # Secrets & credentials
    '.env'
    '.env.local'
    '.env.production'
    '.env.staging'
    '.env.development'

    # Git internals
    '.git/config'
    '.git/hooks'
    '.gitignore'

    # Package locks (prevent supply chain tampering)
    'package-lock.json'
    'yarn.lock'
    'pnpm-lock.yaml'
    'Pipfile.lock'
    'poetry.lock'

    # Claude / Agent configuration — CRITICAL (Lilli lesson: prompt integrity)
    'CLAUDE.md'
    'AGENTS.md'
    '.claude/settings.json'
    '.claude/hooks'

    # SSH keys
    '.ssh/id_rsa'
    '.ssh/id_ed25519'
    '.ssh/config'
    '.ssh/authorized_keys'
)

# =============================================================================
# PROTECTED PATTERNS — regex matches on file path
# =============================================================================

PROTECTED_PATTERNS=(
    # Any .env file variant
    '\.env(\.[a-zA-Z]+)?$'

    # Private keys and certificates
    '\.pem$'
    '\.key$'
    '\.p12$'
    '\.pfx$'
    '\.jks$'

    # Credential files
    'credentials\.json$'
    'service.account\.json$'
    'service-account.*\.json$'
    'token\.json$'
    'secrets\.ya?ml$'

    # SKILL files (prompt integrity protection)
    'SKILL\.md$'

    # Docker secrets
    'docker-compose.*\.ya?ml$'

    # Terraform state (contains secrets)
    '\.tfstate$'
    '\.tfvars$'

    # SSH directory
    '\.ssh/'

    # Claude configuration directory
    '\.claude/'
)

# =============================================================================
# CHECK: Exact file matches
# =============================================================================

BASENAME=$(basename "$FILE_PATH")
for protected in "${PROTECTED_FILES[@]}"; do
    # Check against both full path and basename
    if [ "$FILE_PATH" = "$protected" ] || [ "$BASENAME" = "$protected" ] || echo "$FILE_PATH" | grep -qF "/$protected"; then
        echo "🔒 BLOCKED by write-protection: '$FILE_PATH' is a protected file"
        echo "   Protected files cannot be modified by automated tools."
        echo "   If this is intentional, edit the file manually."
        exit 1
    fi
done

# =============================================================================
# CHECK: Pattern matches
# =============================================================================

for pattern in "${PROTECTED_PATTERNS[@]}"; do
    if echo "$FILE_PATH" | grep -qiE "$pattern"; then
        echo "🔒 BLOCKED by write-protection: '$FILE_PATH' matches protected pattern '$pattern'"
        echo "   If this is a false positive, add an exception in the hook config."
        exit 1
    fi
done

# =============================================================================
# CHECK: Home directory sensitive paths
# =============================================================================

EXPANDED_PATH="$FILE_PATH"
if echo "$FILE_PATH" | grep -q '^~'; then
    EXPANDED_PATH="${FILE_PATH/#\~/$HOME}"
fi

SENSITIVE_HOME_DIRS=(
    "$HOME/.ssh"
    "$HOME/.gnupg"
    "$HOME/.aws"
    "$HOME/.config/gcloud"
    "$HOME/.azure"
    "$HOME/.claude"
    "$HOME/.kube"
)

for dir in "${SENSITIVE_HOME_DIRS[@]}"; do
    if echo "$EXPANDED_PATH" | grep -q "^$dir"; then
        echo "🔒 BLOCKED by write-protection: '$FILE_PATH' is in sensitive directory '$dir'"
        exit 1
    fi
done

# All checks passed
exit 0
