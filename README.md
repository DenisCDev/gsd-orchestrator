# GSD Orchestrator (`/g`)

Orquestrador inteligente para o [GSD (Get Shit Done)](https://github.com/gsd-build/get-shit-done). Fale naturalmente com o Claude e receba a eficiencia maxima do GSD.

## O que resolve

Ao inves de decorar 57+ comandos GSD e saber a ordem correta, voce so fala o que quer:

| Voce fala | Orchestrator executa |
|-----------|---------------------|
| "continua de onde parei" | Detecta estado → resume-work ou execute-phase |
| "tem um bug no login" | Avalia complexidade → debug ou quick |
| "planeja e executa a fase 3" | discuss → plan → execute (sequencia confirmada) |
| "como ta o projeto?" | Responde direto dos dados pre-carregados |
| "faz tudo automatico" | autonomous |

## Arquitetura: Dynamic Discovery (zero drift)

Diferente de uma routing table hardcoded, o orchestrator **descobre comandos em runtime**:

```
SKILL.md                              Workflow
┌─────────────────────────┐           ┌──────────────────────┐
│ !`scan gsd commands`    │──────────>│ Match user intent    │
│ !`load project state`   │           │ against descriptions │
│ !`read config.json`     │           │ (semantic, not       │
│                         │           │  keyword-based)      │
│ Available Commands:     │           │                      │
│ - /gsd:do — Route...   │           │ Dispatch best match  │
│ - /gsd:next — Auto...  │           └──────────────────────┘
│ - /gsd:fast — Triv...  │
│ - (auto-discovered)     │
└─────────────────────────┘
```

**Quando o GSD atualiza** (npx get-shit-done-cc@latest):
- Novos comandos aparecem automaticamente no registry
- Comandos removidos desaparecem
- Argumentos e descricoes refletem a versao atual
- Zero manutencao no orchestrator

## Diferenciais vs `/gsd:do` + `/gsd:next`

| Feature | `/gsd:do` | `/gsd:next` | `/g` |
|---------|-----------|-------------|------|
| Texto livre → comando | Sim | Nao | Sim |
| Auto-detecta estado | Nao | Sim | Sim |
| Pre-carrega estado (0 turns) | Nao | Nao | Sim |
| Encadeia multi-step | Nao | Nao | Sim |
| Le config.json do GSD | Via workflow | Via workflow | Pre-loaded |
| Side questions sem comando | Nao | Nao | Sim |
| Sugere verificacao | Nao | Nao | Sim |
| Sugere worktrees/screenshots | Nao | Nao | Sim |

## Instalacao

```bash
git clone https://github.com/DenisCDev/gsd-orchestrator.git ~/.gsd-orchestrator
cd ~/.gsd-orchestrator
bash install.sh
```

## Uso

```
/g quero comecar o app de delivery
/g continua
/g tem um bug no formulario
/g planeja e executa a fase 4
/g qual fase eu to?
```

## Atualizacao

```bash
cd ~/.gsd-orchestrator
git pull
bash install.sh
```

O install.sh e idempotente: remove artefatos legacy, sobrescreve com versao atual.

## Pre-requisitos

- [Claude Code](https://claude.com/claude-code)
- [GSD](https://github.com/gsd-build/get-shit-done) instalado (`npx get-shit-done-cc@latest`)

## Decisoes de Arquitetura

### Por que dynamic discovery?

> O GSD evolui rapido (v1.25 → v1.28 em semanas). Uma routing table hardcoded diverge silenciosamente — roteia pra comandos que nao existem ou ignora comandos novos. A dynamic discovery elimina esse risco lendo `~/.claude/commands/gsd/*.md` em runtime.

### Por que sem arquivo de preferencias separado?

> O GSD ja tem `.planning/config.json` com settings reais (`skip_discuss`, `auto_advance`, `model_profile`). Manter um `preferences.md` separado cria duas fontes de verdade que podem divergir. O orchestrator le o config.json do GSD diretamente.

### Por que routing semantico em vez de keywords?

> Claude e um LLM. Ele entende "fix the auth bug" e "tem um bug no login" igualmente bem. Dar a ele a lista de comandos com descricoes e deixar que faca matching semantico funciona em qualquer idioma, sem tabela de keywords.

### Context strategy (1M tokens)

> *"Most best practices are based on one constraint: Claude's context window fills up fast."* Com 1M de contexto, a unica recomendacao e novo chat para feature pesada completamente diferente. Sem /clear, sem /compact.
>
> — [Claude Code Best Practices](https://code.claude.com/docs/en/best-practices)

### Verificacao como pratica #1

> *"Include tests, screenshots, or expected outputs so Claude can check itself. This is the single highest-leverage thing you can do."*
>
> — [Claude Code Best Practices](https://code.claude.com/docs/en/best-practices)

### Dynamic context injection

> Skills usam `!`command`` para executar shell commands antes do conteudo chegar ao Claude.
>
> — [Extend Claude with Skills](https://code.claude.com/docs/en/skills)

### Writer/Reviewer com worktrees

> *Uma sessao escreve, outra revisa com contexto fresco.*
>
> — [Common Workflows](https://code.claude.com/docs/en/common-workflows)

## Fontes oficiais

| Artigo | URL |
|--------|-----|
| Claude Code Best Practices | https://code.claude.com/docs/en/best-practices |
| Context Engineering for AI Agents | https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents |
| Extend Claude with Skills | https://code.claude.com/docs/en/skills |
| Custom Subagents | https://code.claude.com/docs/en/sub-agents |
| Hooks Guide | https://code.claude.com/docs/en/hooks-guide |
| Common Workflows | https://code.claude.com/docs/en/common-workflows |
| CLAUDE.md and Memory | https://code.claude.com/docs/en/memory |

## Licenca

MIT
