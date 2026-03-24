---
name: g
description: "GSD Orchestrator — fale naturalmente, receba eficiencia maxima do GSD. Detecta estado do projeto, classifica intencao, encadeia comandos, aplica best practices."
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

## Dynamic Project State (pre-loaded)

- Project init: !`node "C:/Users/rodri/.claude/get-shit-done/bin/gsd-tools.cjs" init progress 2>/dev/null || echo '{"project_exists":false}'`
- Roadmap analysis: !`node "C:/Users/rodri/.claude/get-shit-done/bin/gsd-tools.cjs" roadmap analyze 2>/dev/null || echo '{}'`
- State snapshot: !`node "C:/Users/rodri/.claude/get-shit-done/bin/gsd-tools.cjs" state-snapshot 2>/dev/null || echo '{}'`
- Paused work: !`ls .planning/continue-here.md 2>/dev/null && echo "HAS_PAUSED_WORK" || echo "NO_PAUSED_WORK"`
- Debug sessions: !`ls .planning/debug/*.md 2>/dev/null | grep -v resolved | head -3 || echo "NO_DEBUG_SESSIONS"`
- Orchestrator preferences: !`cat "C:/Users/rodri/.claude/skills/g/preferences.md" 2>/dev/null || echo "No preferences yet"`

## User Input

$ARGUMENTS

## Execution

@C:/Users/rodri/.claude/workflows/gsd-orchestrator.md

Execute the orchestrator workflow end-to-end. The project state above is already loaded — skip the detect_state bash commands and parse directly from the pre-loaded data.
