#!/bin/bash
set -e

CLAUDE_DIR="$HOME/.claude"
SKILLS_DIR="$CLAUDE_DIR/skills/g"
WORKFLOWS_DIR="$CLAUDE_DIR/workflows"
COMMANDS_DIR="$CLAUDE_DIR/commands"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== GSD Orchestrator Installer ==="
echo ""

# Check GSD is installed
if [ ! -f "$CLAUDE_DIR/get-shit-done/bin/gsd-tools.cjs" ]; then
    echo "WARNING: GSD not found. Install first: npx get-shit-done-cc@latest"
    echo ""
fi

# Remove legacy files
[ -f "$COMMANDS_DIR/g.md" ] && rm "$COMMANDS_DIR/g.md" && echo "Removed legacy: commands/g.md"
[ -f "$SKILLS_DIR/preferences.md" ] && rm "$SKILLS_DIR/preferences.md" && echo "Removed deprecated: preferences.md"

# Ensure directories exist
mkdir -p "$SKILLS_DIR"
mkdir -p "$WORKFLOWS_DIR"

# Copy files (no path substitution needed — uses $HOME at runtime)
cp "$SCRIPT_DIR/skills/g/SKILL.md" "$SKILLS_DIR/SKILL.md"
cp "$SCRIPT_DIR/workflows/gsd-orchestrator.md" "$WORKFLOWS_DIR/gsd-orchestrator.md"

echo ""
echo "Installed:"
echo "  $SKILLS_DIR/SKILL.md"
echo "  $WORKFLOWS_DIR/gsd-orchestrator.md"
echo ""
echo "Use: /g <o que voce quer fazer>"
echo ""
echo "Done!"
