#!/bin/bash
# Producer Agent Supervisor — Setup Script
# Auto-detects your Claude environment and creates the scheduled task.

set -e

echo "🔍 Producer Agent Supervisor — Setup"
echo "======================================"
echo ""

# --- 1. Detect session directory ---
CLAUDE_SUPPORT="$HOME/Library/Application Support/Claude"
SESSION_BASE="$CLAUDE_SUPPORT/local-agent-mode-sessions"

if [ ! -d "$SESSION_BASE" ]; then
    echo "❌ Could not find Claude session directory at:"
    echo "   $SESSION_BASE"
    echo "   Make sure Claude Desktop is installed and you've used Cowork mode at least once."
    exit 1
fi

# Find the session directory (two nested UUIDs)
SESSION_DIR=$(find "$SESSION_BASE" -name "local_*.json" -maxdepth 3 2>/dev/null | head -1 | xargs dirname 2>/dev/null)

if [ -z "$SESSION_DIR" ]; then
    echo "❌ No cowork sessions found. Start at least one Cowork session in Claude first."
    exit 1
fi

echo "✅ Found session directory:"
echo "   $SESSION_DIR"
echo ""

# Count sessions
SESSION_COUNT=$(ls "$SESSION_DIR"/local_*.json 2>/dev/null | wc -l | tr -d ' ')
echo "   Found $SESSION_COUNT cowork sessions."
echo ""

# --- 2. Get Slack user ID ---
echo "To receive alerts, the agent needs your Slack user ID."
echo "  (Find it in Slack: click your profile → ⋮ → Copy member ID)"
echo ""
read -p "Enter your Slack user ID (e.g., U08HJV64MPB): " SLACK_USER_ID

if [ -z "$SLACK_USER_ID" ]; then
    echo "❌ Slack user ID is required for alerts."
    exit 1
fi

echo ""

# --- 3. Get user's name (for personalized prompts) ---
read -p "Enter your first name (for alert messages): " USER_NAME
USER_NAME=${USER_NAME:-"User"}

echo ""

# --- 4. Choose check frequency ---
echo "How often should the supervisor check? (in minutes)"
echo "  Recommended: 5 (catches reboots quickly)"
echo "  Conservative: 15 (less frequent, still good coverage)"
read -p "Check interval [5]: " CHECK_INTERVAL
CHECK_INTERVAL=${CHECK_INTERVAL:-5}

echo ""

# --- 5. Generate the SKILL.md ---
SKILL_DIR="$HOME/.claude/scheduled-tasks/producer-agent-supervisor"
mkdir -p "$SKILL_DIR"

# Use the template and substitute variables
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
sed \
    -e "s|{{SESSION_DIR}}|$SESSION_DIR|g" \
    -e "s|{{SLACK_USER_ID}}|$SLACK_USER_ID|g" \
    -e "s|{{USER_NAME}}|$USER_NAME|g" \
    -e "s|{{CHECK_INTERVAL}}|$CHECK_INTERVAL|g" \
    "$SCRIPT_DIR/SKILL.template.md" > "$SKILL_DIR/SKILL.md"

echo "✅ Installed SKILL.md to:"
echo "   $SKILL_DIR/SKILL.md"
echo ""

# --- 6. Print next steps ---
echo "======================================"
echo "✅ Setup complete!"
echo ""
echo "Next steps:"
echo "  1. Open Claude Desktop"
echo "  2. Open any Cowork session (or start a new one)"
echo "  3. Tell Claude:"
echo ""
echo "     Create a scheduled task called 'producer-agent-supervisor'"
echo "     with cron expression '*/$CHECK_INTERVAL * * * *'"
echo "     using the SKILL.md at ~/.claude/scheduled-tasks/producer-agent-supervisor/SKILL.md"
echo ""
echo "  Or if the task already exists, Claude will pick up the updated SKILL.md"
echo "  on the next run automatically."
echo ""
echo "The supervisor will:"
echo "  • Check scheduled tasks for missed/overdue runs"
echo "  • Inspect cowork sessions for stalled work or unanswered questions"
echo "  • Monitor Claude.app and auto-restart if it crashes"
echo "  • Alert you via Slack DM when issues are found"
echo "  • Stay silent when everything is healthy"
