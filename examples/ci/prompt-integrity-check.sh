#!/usr/bin/env bash
# prompt-integrity-check.sh — Verify that system prompt/config files haven't been tampered with.
#
# Usage:
#   ./prompt-integrity-check.sh --baseline    # Generate baseline hashes (run once, commit output)
#   ./prompt-integrity-check.sh --check       # Check current files against baseline
#   ./prompt-integrity-check.sh --diff        # Show what changed since baseline
#
# The baseline file (.prompt-integrity-baseline) should be committed to git.
# It contains SHA256 hashes of all prompt/config files.

set -euo pipefail

BASELINE_FILE=".prompt-integrity-baseline"

# =============================================================================
# CONFIG: Files to monitor — customize for your project
# =============================================================================

CONFIG_PATTERNS=(
    "CLAUDE.md"
    "AGENTS.md"
    "**/SKILL.md"
    ".claude/settings.json"
    ".claude/hooks/*"
)

# =============================================================================
# FUNCTIONS
# =============================================================================

find_config_files() {
    for pattern in "${CONFIG_PATTERNS[@]}"; do
        find . -path "./.git" -prune -o -path "./node_modules" -prune -o -name "$(basename "$pattern")" -print 2>/dev/null
    done | sort -u
}

generate_hashes() {
    find_config_files | while read -r file; do
        if [ -f "$file" ]; then
            sha256sum "$file"
        fi
    done
}

# =============================================================================
# COMMANDS
# =============================================================================

case "${1:-}" in
    --baseline)
        echo "📝 Generating prompt integrity baseline..."
        HASHES=$(generate_hashes)
        if [ -z "$HASHES" ]; then
            echo "⚠️  No config files found matching patterns."
            echo "   Patterns searched: ${CONFIG_PATTERNS[*]}"
            exit 1
        fi
        echo "$HASHES" > "$BASELINE_FILE"
        echo ""
        echo "Baseline written to $BASELINE_FILE:"
        echo "$HASHES" | sed 's/^/  /'
        echo ""
        echo "✅ Commit this file to git:"
        echo "   git add $BASELINE_FILE && git commit -m 'chore: update prompt integrity baseline'"
        ;;

    --check)
        if [ ! -f "$BASELINE_FILE" ]; then
            echo "❌ No baseline found. Generate one first:"
            echo "   $0 --baseline"
            exit 1
        fi

        echo "🔍 Checking prompt/config integrity against baseline..."

        CURRENT=$(generate_hashes)
        BASELINE=$(cat "$BASELINE_FILE")

        # Check for modified files
        MODIFIED=0
        while IFS= read -r line; do
            HASH=$(echo "$line" | awk '{print $1}')
            FILE=$(echo "$line" | awk '{print $2}')

            CURRENT_HASH=$(echo "$CURRENT" | grep "$FILE" | awk '{print $1}' || echo "MISSING")

            if [ "$CURRENT_HASH" = "MISSING" ]; then
                echo "🚨 DELETED: $FILE"
                MODIFIED=1
            elif [ "$HASH" != "$CURRENT_HASH" ]; then
                echo "🚨 MODIFIED: $FILE"
                echo "   Baseline: $HASH"
                echo "   Current:  $CURRENT_HASH"
                MODIFIED=1
            fi
        done <<< "$BASELINE"

        # Check for new files not in baseline
        while IFS= read -r line; do
            FILE=$(echo "$line" | awk '{print $2}')
            if ! grep -qF "$FILE" "$BASELINE_FILE" 2>/dev/null; then
                echo "⚠️  NEW FILE: $FILE (not in baseline)"
                MODIFIED=1
            fi
        done <<< "$CURRENT"

        if [ $MODIFIED -eq 1 ]; then
            echo ""
            echo "❌ Prompt/config files have been modified since baseline."
            echo "   If intentional, update baseline: $0 --baseline"
            exit 1
        fi

        echo "✅ All prompt/config files match baseline."
        ;;

    --diff)
        if [ ! -f "$BASELINE_FILE" ]; then
            echo "❌ No baseline found."
            exit 1
        fi

        echo "📊 Comparing current state to baseline..."
        CURRENT=$(generate_hashes)
        diff <(cat "$BASELINE_FILE") <(echo "$CURRENT") || echo "(files differ)"
        ;;

    *)
        echo "Usage: $0 [--baseline | --check | --diff]"
        echo ""
        echo "  --baseline  Generate hash baseline (run once, commit output)"
        echo "  --check     Verify files against baseline (run in CI)"
        echo "  --diff      Show differences from baseline"
        exit 1
        ;;
esac
