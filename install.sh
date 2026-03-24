#!/bin/bash
set -e

CLAUDE_DIR="$HOME/.claude"
COMMANDS_DIR="$CLAUDE_DIR/commands"
WORKFLOWS_DIR="$CLAUDE_DIR/workflows"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== GSD Orchestrator Installer ==="
echo ""

# Ensure directories exist
mkdir -p "$COMMANDS_DIR"
mkdir -p "$WORKFLOWS_DIR"

# Copy files
cp "$SCRIPT_DIR/commands/g.md" "$COMMANDS_DIR/g.md"
cp "$SCRIPT_DIR/workflows/gsd-orchestrator.md" "$WORKFLOWS_DIR/gsd-orchestrator.md"

# Fix paths in command file to use absolute workflow path
sed -i "s|@workflows/gsd-orchestrator.md|@$WORKFLOWS_DIR/gsd-orchestrator.md|g" "$COMMANDS_DIR/g.md"

echo "Installed:"
echo "  $COMMANDS_DIR/g.md"
echo "  $WORKFLOWS_DIR/gsd-orchestrator.md"
echo ""
echo "Use: /g <o que voce quer fazer>"
echo ""
echo "Done!"
