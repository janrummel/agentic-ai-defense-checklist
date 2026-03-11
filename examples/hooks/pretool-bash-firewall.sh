#!/usr/bin/env bash
# pretool-bash-firewall.sh — PreToolUse hook for Claude Code
# Blocks dangerous shell commands before execution.
#
# Exit 0 = allow, Exit 1 = block (stdout = reason shown to user)
#
# Usage in settings.json:
#   "PreToolUse": [{"matcher": "Bash", "command": "~/.claude/hooks/pretool-bash-firewall.sh \"$TOOL_INPUT\""}]

set -euo pipefail

INPUT="${1:-$(cat /dev/stdin)}"

# Extract command from JSON input
COMMAND=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print(data.get('command', data.get('input', '')))
except:
    print(sys.stdin.read())
" 2>/dev/null || echo "$INPUT")

# =============================================================================
# DANGEROUS PATTERNS — customize as needed
# =============================================================================

DANGEROUS_PATTERNS=(
    # Destructive operations
    'rm -rf /'
    'rm -rf ~'
    'rm -rf \*'
    'rm -rf \.'
    'mkfs\.'
    'dd if=.* of=/dev/'
    '> /dev/sd'
    'chmod 777'
    'chmod -R 777'

    # Pipe-to-shell (remote code execution)
    'curl.*|.*sh'
    'curl.*|.*bash'
    'wget.*|.*sh'
    'wget.*|.*bash'
    'curl.*| sh'
    'curl.*| bash'

    # Reverse shells
    'bash -i >& /dev/tcp'
    'nc -e /bin'
    'nc -c /bin'
    'python.*socket.*connect'
    'mkfifo.*/tmp/'

    # Credential exfiltration via DNS
    'dig.*\$('
    'nslookup.*\$('
    'host.*\$('

    # History/credential access
    'cat.*\.bash_history'
    'cat.*/etc/shadow'
    'cat.*/etc/passwd'

    # Environment variable dumping (can leak secrets)
    '^env$'
    '^printenv$'
    'export.*API_KEY'
    'export.*SECRET'
    'export.*TOKEN'
    'export.*PASSWORD'

    # Process/network sniffing
    'tcpdump'
    'wireshark'
    'strace.*-p'
)

# =============================================================================
# BLOCKED EXTERNAL HOSTS — add legitimate hosts to ALLOWED_HOSTS
# =============================================================================

ALLOWED_HOSTS=(
    'github.com'
    'registry.npmjs.org'
    'pypi.org'
    'api.anthropic.com'
    'localhost'
    '127.0.0.1'
)

# =============================================================================
# CHECK: Dangerous patterns
# =============================================================================

for pattern in "${DANGEROUS_PATTERNS[@]}"; do
    if echo "$COMMAND" | grep -qiE "$pattern"; then
        echo "🚫 BLOCKED by bash-firewall: Command matches dangerous pattern '$pattern'"
        echo "   Command: $COMMAND"
        exit 1
    fi
done

# =============================================================================
# CHECK: External curl/wget to non-allowlisted hosts
# =============================================================================

if echo "$COMMAND" | grep -qiE '(curl|wget)\s'; then
    # Extract the URL/host from the command
    TARGET_HOST=$(echo "$COMMAND" | grep -oiE '(https?://[^/\s]+|[a-z0-9.-]+\.[a-z]{2,})' | head -1 | sed 's|https\?://||')

    if [ -n "$TARGET_HOST" ]; then
        ALLOWED=false
        for host in "${ALLOWED_HOSTS[@]}"; do
            if echo "$TARGET_HOST" | grep -qiF "$host"; then
                ALLOWED=true
                break
            fi
        done

        if [ "$ALLOWED" = false ]; then
            echo "🚫 BLOCKED by bash-firewall: curl/wget to non-allowlisted host '$TARGET_HOST'"
            echo "   Add to ALLOWED_HOSTS in this hook if this is legitimate."
            echo "   Command: $COMMAND"
            exit 1
        fi
    fi
fi

# =============================================================================
# CHECK: Secrets in command (potential exfiltration)
# =============================================================================

if echo "$COMMAND" | grep -qiE '(sk-[a-zA-Z0-9]{20,}|AKIA[A-Z0-9]{16}|ghp_[a-zA-Z0-9]{36}|xox[bprs]-[a-zA-Z0-9-]+)'; then
    echo "🚫 BLOCKED by bash-firewall: Command appears to contain API keys/secrets"
    echo "   Never pass secrets directly in commands."
    exit 1
fi

# All checks passed
exit 0
