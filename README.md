# GSD Orchestrator (`/g`)

Intelligent orchestrator for [GSD (Get Shit Done)](https://github.com/gsd-build/get-shit-done). Speak naturally to Claude and get maximum GSD efficiency.

**[Portugues](#gsd-orchestrator-g-1)** | English

## What it solves

Instead of memorizing 57+ GSD commands and knowing the correct order, you just say what you want:

| You say | Orchestrator executes |
|---------|----------------------|
| "continue where I left off" | Detects state → resume-work or execute-phase |
| "there's a bug in login" | Evaluates complexity → debug or quick |
| "plan and execute phase 3" | discuss → plan → execute (confirmed sequence) |
| "how's the project going?" | Answers directly from pre-loaded data |
| "do everything automatically" | autonomous |

## Architecture: Dynamic Discovery (zero drift)

Unlike a hardcoded routing table, the orchestrator **discovers commands at runtime**:

```
SKILL.md                              Workflow
┌─────────────────────────┐           ┌──────────────────────┐
│ !`scan gsd commands`    │──────────>│ Match user intent    │
│ !`load project state`   │           │ against descriptions │
│ !`read config.json`     │           │ (semantic, not       │
│                         │           │  keyword-based)      │
│ Available Commands:     │           │                      │
│ - /gsd-do — Route...   │           │ Dispatch best match  │
│ - /gsd-next — Auto...  │           └──────────────────────┘
│ - /gsd-fast — Triv...  │
│ - (auto-discovered)     │
└─────────────────────────┘
```

**When GSD updates** (npx get-shit-done-cc@latest):
- New commands appear automatically in the registry
- Removed commands disappear
- Arguments and descriptions reflect the current version
- Zero orchestrator maintenance

## Differentials vs `/gsd-do` + `/gsd-next`

| Feature | `/gsd-do` | `/gsd-next` | `/g` |
|---------|-----------|-------------|------|
| Free text → command | Yes | No | Yes |
| Auto-detects state | No | Yes | Yes |
| Pre-loads state (0 turns) | No | No | Yes |
| Chains multi-step | No | No | Yes |
| Reads GSD config.json | Via workflow | Via workflow | Pre-loaded |
| Side questions without command | No | No | Yes |
| Suggests verification | No | No | Yes |
| Suggests worktrees/screenshots | No | No | Yes |

## Installation

```bash
git clone https://github.com/DenisCDev/gsd-orchestrator.git ~/.gsd-orchestrator
cd ~/.gsd-orchestrator
bash install.sh
```

## Usage

```
/g I want to start the delivery app
/g continue
/g there's a bug in the form
/g plan and execute phase 4
/g what phase am I on?
```

## Update

```bash
cd ~/.gsd-orchestrator
git pull
bash install.sh
```

The install.sh is idempotent: removes legacy artifacts, overwrites with the current version.

## Prerequisites

- [Claude Code](https://claude.com/claude-code)
- [GSD](https://github.com/gsd-build/get-shit-done) installed (`npx get-shit-done-cc@latest`)

## Compatibility

Tested against **GSD 1.34.2** (skill-based naming: `/gsd-<command>`).

GSD ≥1.30 moved commands from `~/.claude/commands/gsd/*.md` (colon prefix `/gsd:do`) to `~/.claude/skills/gsd-*/SKILL.md` (dash prefix `/gsd-do`). The orchestrator reads both locations, so older versions still work, but the dispatch uses the dash-prefixed skill names when invoking via the Skill tool.

If you hit routing errors after a GSD upgrade, pin to the last known-good version:

```bash
npx get-shit-done-cc@1.34.2
```

Then re-run `bash install.sh` from this repo to refresh the orchestrator.

## Architecture Decisions

### Why dynamic discovery?

> GSD evolves fast. A hardcoded routing table silently diverges — routing to commands that don't exist or ignoring new ones. Dynamic discovery eliminates this risk by reading `~/.claude/commands/gsd/*.md` and `~/.claude/skills/gsd-*/SKILL.md` at runtime.

### Why no separate preferences file?

> GSD already has `.planning/config.json` with real settings (`skip_discuss`, `auto_advance`, `model_profile`). Maintaining a separate `preferences.md` creates two sources of truth that can diverge. The orchestrator reads GSD's config.json directly.

### Why semantic routing instead of keywords?

> Claude is an LLM. It understands "fix the auth bug" and "there's a bug in login" equally well. Giving it the command list with descriptions and letting it do semantic matching works in any language, without a keyword table.

### Context strategy (1M tokens)

> *"Most best practices are based on one constraint: Claude's context window fills up fast."* With 1M context, the only recommendation is a new chat for a completely different heavy feature. No /clear, no /compact.
>
> — [Claude Code Best Practices](https://code.claude.com/docs/en/best-practices)

### Verification as practice #1

> *"Include tests, screenshots, or expected outputs so Claude can check itself. This is the single highest-leverage thing you can do."*
>
> — [Claude Code Best Practices](https://code.claude.com/docs/en/best-practices)

### Dynamic context injection

> Skills use `!`command`` to execute shell commands before content reaches Claude.
>
> — [Extend Claude with Skills](https://code.claude.com/docs/en/skills)

### Writer/Reviewer with worktrees

> *One session writes, another reviews with fresh context.*
>
> — [Common Workflows](https://code.claude.com/docs/en/common-workflows)

## Official Sources

| Article | URL |
|---------|-----|
| Claude Code Best Practices | https://code.claude.com/docs/en/best-practices |
| Context Engineering for AI Agents | https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents |
| Extend Claude with Skills | https://code.claude.com/docs/en/skills |
| Custom Subagents | https://code.claude.com/docs/en/sub-agents |
| Hooks Guide | https://code.claude.com/docs/en/hooks-guide |
| Common Workflows | https://code.claude.com/docs/en/common-workflows |
| CLAUDE.md and Memory | https://code.claude.com/docs/en/memory |

## License

MIT

---

# GSD Orchestrator (`/g`)

Orquestrador inteligente para o [GSD (Get Shit Done)](https://github.com/gsd-build/get-shit-done). Fale naturalmente com o Claude e receba a eficiencia maxima do GSD.

**English** | [Portugues](#gsd-orchestrator-g-1)

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
│ - /gsd-do — Route...   │           │ Dispatch best match  │
│ - /gsd-next — Auto...  │           └──────────────────────┘
│ - /gsd-fast — Triv...  │
│ - (auto-discovered)     │
└─────────────────────────┘
```

**Quando o GSD atualiza** (npx get-shit-done-cc@latest):
- Novos comandos aparecem automaticamente no registry
- Comandos removidos desaparecem
- Argumentos e descricoes refletem a versao atual
- Zero manutencao no orchestrator

## Diferenciais vs `/gsd-do` + `/gsd-next`

| Feature | `/gsd-do` | `/gsd-next` | `/g` |
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

> O GSD evolui rapido. Uma routing table hardcoded diverge silenciosamente — roteia pra comandos que nao existem ou ignora comandos novos. A dynamic discovery elimina esse risco lendo `~/.claude/commands/gsd/*.md` e `~/.claude/skills/gsd-*/SKILL.md` em runtime.

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
