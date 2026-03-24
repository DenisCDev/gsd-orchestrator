#!/bin/bash
set -e

CLAUDE_DIR="$HOME/.claude"
SKILLS_DIR="$CLAUDE_DIR/skills/g"
WORKFLOWS_DIR="$CLAUDE_DIR/workflows"
COMMANDS_DIR="$CLAUDE_DIR/commands"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== GSD Orchestrator Installer ==="
echo ""

# Remove legacy command format if exists
if [ -f "$COMMANDS_DIR/g.md" ]; then
    rm "$COMMANDS_DIR/g.md"
    echo "Removed legacy command: $COMMANDS_DIR/g.md"
fi

# Ensure directories exist
mkdir -p "$SKILLS_DIR"
mkdir -p "$WORKFLOWS_DIR"

# Copy skill files
cp "$SCRIPT_DIR/skills/g/SKILL.md" "$SKILLS_DIR/SKILL.md"

# Only copy preferences if not already present (preserve learned patterns)
if [ ! -f "$SKILLS_DIR/preferences.md" ]; then
    cp "$SCRIPT_DIR/skills/g/preferences.md" "$SKILLS_DIR/preferences.md"
    echo "Created fresh preferences file"
else
    echo "Preserved existing preferences (learned patterns kept)"
fi

# Copy workflow
cp "$SCRIPT_DIR/workflows/gsd-orchestrator.md" "$WORKFLOWS_DIR/gsd-orchestrator.md"

# Fix paths in SKILL.md to use user's home directory
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" || "$OSTYPE" == "win32" ]]; then
    CLAUDE_PATH=$(cygpath -w "$CLAUDE_DIR" 2>/dev/null || echo "$CLAUDE_DIR")
    # Convert backslashes to forward slashes for consistency
    CLAUDE_PATH="${CLAUDE_PATH//\\//}"
else
    CLAUDE_PATH="$CLAUDE_DIR"
fi

sed -i "s|C:/Users/rodri/.claude|$CLAUDE_PATH|g" "$SKILLS_DIR/SKILL.md"
sed -i "s|C:/Users/rodri/.claude|$CLAUDE_PATH|g" "$WORKFLOWS_DIR/gsd-orchestrator.md"

echo ""
echo "Installed:"
echo "  $SKILLS_DIR/SKILL.md"
echo "  $SKILLS_DIR/preferences.md"
echo "  $WORKFLOWS_DIR/gsd-orchestrator.md"
echo ""
echo "Use: /g <o que voce quer fazer>"
echo ""
echo "Done!"
