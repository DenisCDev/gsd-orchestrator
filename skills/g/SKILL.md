---
name: g
description: "GSD Orchestrator — fale naturalmente, receba eficiencia maxima do GSD. Descobre comandos dinamicamente, zero drift de versao."
argument-hint: "<o que voce quer fazer, em linguagem natural>"
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Grep
  - Glob
  - Skill
  - Agent
  - AskUserQuestion
  - Task
  - TaskCreate
  - TaskGet
  - TaskList
  - TaskOutput
  - TaskUpdate
---

## GSD Installation

- Status: !`[ -f "$HOME/.claude/get-shit-done/bin/gsd-tools.cjs" ] && echo "INSTALLED" || echo "NOT_INSTALLED"`
- Version: !`cat "$HOME/.claude/get-shit-done/VERSION" 2>/dev/null || echo "unknown"`

## Project State

- Init: !`node "$HOME/.claude/get-shit-done/bin/gsd-tools.cjs" init progress 2>/dev/null || echo '{"project_exists":false}'`
- Roadmap: !`[ -d ".planning" ] && node "$HOME/.claude/get-shit-done/bin/gsd-tools.cjs" roadmap analyze 2>/dev/null || echo '{}'`
- State: !`[ -d ".planning" ] && node "$HOME/.claude/get-shit-done/bin/gsd-tools.cjs" state-snapshot 2>/dev/null || echo '{}'`
- Paused: !`[ -d ".planning" ] && ls .planning/continue-here.md 2>/dev/null && echo "PAUSED" || echo "NOT_PAUSED"`
- Debug: !`[ -d ".planning" ] && ls .planning/debug/*.md 2>/dev/null | grep -v resolved | head -3 || echo "NONE"`

## GSD Config (source of truth — NOT a separate preferences file)

!`[ -d ".planning" ] && cat .planning/config.json 2>/dev/null || echo "NO_CONFIG"`

## Available GSD Commands (dynamically discovered — scans both commands/ and skills/)

!`result=$(for f in "$HOME/.claude/commands/gsd/"*.md "$HOME/.claude/skills/gsd-*/SKILL.md"; do [ -f "$f" ] && name=$(sed -n 's/^name: *//p' "$f" | head -1) && desc=$(sed -n 's/^description: *//p' "$f" | head -1 | tr -d '"') && hint=$(sed -n 's/^argument-hint: *//p' "$f" | head -1 | tr -d '"') && [ -n "$name" ] && echo "- /$name $hint — $desc"; done 2>/dev/null | sort -u); [ -n "$result" ] && echo "$result" || echo "NO_GSD_COMMANDS"`

## User Input

$ARGUMENTS

## Workflow

@../../workflows/gsd-orchestrator.md
