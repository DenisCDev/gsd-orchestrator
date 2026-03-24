# GSD Orchestrator (`/g`)

Orquestrador inteligente para o [GSD (Get Shit Done)](https://github.com/gsd-build/get-shit-done). Fale naturalmente com o Claude e receba a eficiencia maxima do GSD.

## O que resolve

Ao inves de decorar 57+ comandos GSD e saber a ordem correta, voce so fala o que quer:

| Voce fala | Orchestrator executa |
|-----------|---------------------|
| "continua de onde parei" | Detecta estado → `/gsd:resume-work` ou `/gsd:execute-phase` |
| "tem um bug no login" | Avalia complexidade → `/gsd:debug` ou `/gsd:quick` |
| "planeja e executa a fase 3" | `/gsd:discuss-phase 3` → `/gsd:plan-phase 3` → `/gsd:execute-phase 3` |
| "adiciona autenticacao com Google" | Avalia scope → `/gsd:add-phase` ou `/gsd:quick` |
| "como ta o projeto?" | `/gsd:progress` |
| "faz tudo automatico" | `/gsd:autonomous` |
| "qual fase eu to?" | Responde direto dos dados pre-carregados (zero overhead) |

## Diferenciais vs `/gsd:do`

| Feature | `/gsd:do` | `/g` |
|---------|-----------|------|
| Roteia para comando GSD | Single command | Multi-step workflows |
| Detecta estado do projeto | Nao | Sim — pre-carregado via dynamic context injection |
| Encadeia comandos | Nao | Sim — discuss → plan → execute |
| Aprende preferencias | Nao | Sim — persistent preferences file |
| Sugere verificacao | Nao | Sim — always after execute |
| Sugere Writer/Reviewer | Nao | Sim — para mudancas criticas |
| Side questions | Nao | Sim — responde sem invocar comandos |
| Formato | Legacy commands/ | Modern skills/ (SKILL.md) |

## Instalacao

```bash
git clone https://github.com/DenisCDev/gsd-orchestrator.git ~/.gsd-orchestrator
cd ~/.gsd-orchestrator
bash install.sh
```

Ou manualmente:
```bash
mkdir -p ~/.claude/skills/g ~/.claude/workflows
cp skills/g/SKILL.md ~/.claude/skills/g/SKILL.md
cp skills/g/preferences.md ~/.claude/skills/g/preferences.md
cp workflows/gsd-orchestrator.md ~/.claude/workflows/gsd-orchestrator.md
```

## Uso

No Claude Code, digite:

```
/g quero comecar o app de delivery
/g continua
/g tem um bug no formulario
/g planeja e executa a fase 4
/g anota: revisar as rotas depois
/g qual fase eu to?
```

## Pre-requisitos

- [Claude Code](https://claude.com/claude-code)
- [GSD](https://github.com/gsd-build/get-shit-done) instalado (`npx get-shit-done-cc@latest`)

## Como funciona

1. **Pre-load** — Dynamic context injection (`!`command``) carrega estado do projeto antes do prompt chegar ao Claude
2. **Preferences** — Le preferencias aprendidas de interacoes anteriores
3. **Classify** — Classifica a intencao (build, fix, plan, continue, etc.) + modificadores (fast, thorough, yolo)
4. **Resolve** — Cruza intent + estado + preferences para sequencia otima de comandos
5. **Guard** — Verifica pre-condicoes, sugere patterns avancados (worktrees, writer/reviewer)
6. **Dispatch** — Invoca os comandos GSD na ordem correta
7. **Orient** — Sugere proximo passo com enfase em verificacao
8. **Learn** — Atualiza preferences silenciosamente baseado nos patterns do usuario

## Decisoes de Arquitetura

As decisoes de design deste orchestrador foram baseadas nas best practices oficiais publicadas pela Anthropic:

### Context Management com 1M tokens

> *"Most best practices are based on one constraint: Claude's context window fills up fast, and performance degrades as it fills."*

Com o contexto de 1M tokens, a estrategia muda: nao e necessario `/clear` ou `/compact` obsessivamente. A unica recomendacao e abrir novo chat quando mudar para uma **feature pesada completamente diferente**.

**Fonte:** [Claude Code Best Practices](https://code.claude.com/docs/en/best-practices)

### Verificacao como pratica #1

> *"Include tests, screenshots, or expected outputs so Claude can check itself. This is the single highest-leverage thing you can do."*

O orchestrador sempre sugere verificacao apos execucao (`/gsd:verify-work` ou `/gsd:add-tests`).

**Fonte:** [Claude Code Best Practices](https://code.claude.com/docs/en/best-practices)

### Skills format (SKILL.md) com dynamic context injection

> Skills usam `!`command`` para executar shell commands antes do conteudo ser enviado ao Claude, injetando estado dinamico sem consumir turns.

O orchestrador pre-carrega `init progress`, `roadmap analyze`, e `state-snapshot` via dynamic injection, eliminando o custo de turns para detecao de estado.

**Fonte:** [Extend Claude with Skills](https://code.claude.com/docs/en/skills) | [Introducing Agent Skills](https://claude.com/blog/skills)

### Subagents para investigacao

> *"Specialized sub-agents handle focused tasks with clean context windows while main agents coordinate high-level strategy."*

O orchestrador delega pesquisa e exploracao para subagents (Explore, Research) mantendo o contexto principal limpo.

**Fonte:** [Create Custom Subagents](https://code.claude.com/docs/en/sub-agents) | [Effective Context Engineering](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents)

### Writer/Reviewer pattern para mudancas criticas

> *"Use git worktrees with `claude --worktree feature-auth` for isolated parallel sessions."* Uma sessao escreve, outra revisa com contexto fresco.

Para refactors de auth, database, ou features criticas, o orchestrador sugere usar `claude -w <name>` em paralelo.

**Fonte:** [Common Workflows](https://code.claude.com/docs/en/common-workflows)

### Explore → Plan → Implement → Commit

> O workflow de 4 fases recomendado pela Anthropic: explorar com Plan Mode, planejar, implementar, commitar.

O GSD ja segue esse pattern (discuss → plan → execute → verify). O orchestrador garante a sequencia correta baseado no estado.

**Fonte:** [Claude Code Best Practices](https://code.claude.com/docs/en/best-practices)

### Hooks para automacao

> Hooks automatizam tarefas repetitivas: auto-format apos edits, notificacoes desktop, protecao de arquivos sensiveis.

O orchestrador sugere configuracao de hooks na primeira interacao.

**Fonte:** [Automate Workflows with Hooks](https://code.claude.com/docs/en/hooks-guide)

### Persistent memory / preferences

> *"Combining memory with context editing yielded a 39% performance boost over baseline."*

O orchestrador mantem um `preferences.md` que aprende patterns do usuario (pula discuss? prefere quick para bugs?) para roteamento cada vez mais preciso.

**Fonte:** [Managing Context](https://claude.com/blog/context-management) | [CLAUDE.md and Memory](https://code.claude.com/docs/en/memory)

## Todas as fontes oficiais consultadas

| Artigo | URL |
|--------|-----|
| Claude Code Best Practices | https://code.claude.com/docs/en/best-practices |
| Effective Context Engineering for AI Agents | https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents |
| How Anthropic Teams Use Claude Code | https://claude.com/blog/how-anthropic-teams-use-claude-code |
| Introducing Agent Skills | https://claude.com/blog/skills |
| Claude Code Plugins | https://claude.com/blog/claude-code-plugins |
| Claude Code Sandboxing | https://www.anthropic.com/engineering/claude-code-sandboxing |
| Automate Workflows with Hooks | https://code.claude.com/docs/en/hooks-guide |
| Create Custom Subagents | https://code.claude.com/docs/en/sub-agents |
| Managing Context on the Claude Developer Platform | https://claude.com/blog/context-management |
| Claude Code Overview | https://code.claude.com/docs |
| CLAUDE.md and Memory | https://code.claude.com/docs/en/memory |
| Common Workflows | https://code.claude.com/docs/en/common-workflows |
| Extend Claude with Skills | https://code.claude.com/docs/en/skills |

## Licenca

MIT
