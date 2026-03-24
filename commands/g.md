---
name: g
description: "GSD Orchestrator — fale naturalmente, receba eficiencia maxima do GSD"
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
<objective>
Orchestrator inteligente para o sistema GSD. Recebe linguagem natural e executa o workflow GSD mais eficiente possivel, encadeando comandos quando necessario.

Diferente do `/gsd:do` (dispatcher simples que roteia para UM comando), este orchestrator:
1. Detecta estado do projeto automaticamente
2. Encadeia multiplos comandos GSD na sequencia correta
3. Aplica best practices (clear entre operacoes pesadas, model profile correto)
4. Resolve intencoes compostas ("planeja e executa fase 3")
5. Sugere proativamente o proximo passo ideal
</objective>

<execution_context>
@workflows/gsd-orchestrator.md
</execution_context>

<context>
$ARGUMENTS
</context>

<process>
Execute the orchestrator workflow from @workflows/gsd-orchestrator.md end-to-end.
</process>
