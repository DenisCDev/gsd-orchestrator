---
name: g
description: "GSD Orchestrator — fale naturalmente, receba eficiencia maxima do GSD. Descobre comandos dinamicamente, zero drift de versao."
argument-hint: "<o que voce quer fazer, em linguagem natural>"
allowed-tools:
  - Bash
  - Skill
  - AskUserQuestion
  - Read
---

## User Input

$ARGUMENTS

## Workflow

@../../workflows/gsd-orchestrator.md
