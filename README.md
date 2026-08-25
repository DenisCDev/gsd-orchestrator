<h1 align="center">GSD Orchestrator <code>/g</code></h1>

<p align="center">
  <b>Natural-language orchestrator for GSD: say what you want; it finds and chains the right commands</b><br>
  <sub><i>one wizard in front of 57 commands</i></sub>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/commands-discovered%20at%20runtime-43A48E?labelColor=171310" alt="commands discovered at runtime">
  <img src="https://img.shields.io/badge/routing-zero%20drift-43A48E?labelColor=171310" alt="zero drift routing">
  <img src="https://img.shields.io/badge/tested%20with-GSD%201.34.2-D4A24E?labelColor=171310" alt="tested with GSD 1.34.2">
  <img src="https://img.shields.io/badge/license-MIT-D4A24E?labelColor=171310" alt="MIT license">
</p>

<p align="center">
  <img src="assets/mtg-gandalf-shire.jpg" width="640" alt="Gandalf with arms raised in the Shire, fireworks taking the shape of eagles — art by Dmitry Burmak, Tales of Middle-earth (2023)">
</p>

> *"Gandalf, Friend of the Shire"*, printed in Brazil as **"Gandalf, Amigo do Condado"**. Art by Dmitry Burmak for **Magic: The Gathering**,
> Tales of Middle-earth (2023). You name the piece; the wizard cues the sections.
> Nobody in the audience needs to know which instrument comes in when.

> **[Leia em Português](#portugues)**

**GSD ships 57+ commands, and the right one depends on project state you would
have to check by hand.** `/g` reads the installed command registry and the
project state at runtime, matches what you said against the real command
descriptions, and dispatches — one entry point in front of the whole toolbox.
When GSD updates, new commands appear and removed ones vanish, with zero
orchestrator maintenance.

## What it solves

| You say | Orchestrator executes |
|---------|----------------------|
| "continue where I left off" | Detects state → resume-work or execute-phase |
| "there's a bug in login" | Evaluates complexity → debug or quick |
| "plan and execute phase 3" | discuss → plan → execute (confirmed sequence) |
| "how's the project going?" | Answers directly from pre-loaded data |
| "do everything automatically" | autonomous |

## Architecture: dynamic discovery (zero drift)

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

## What it adds over `/gsd-do` + `/gsd-next`

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

<a id="portugues"></a>

# GSD Orchestrator (`/g`) — PT-BR

**O GSD traz 57+ comandos, e o certo depende de um estado de projeto que você
teria que checar na mão.** O `/g` lê o registro de comandos instalado e o estado
do projeto em runtime, compara o que você falou com as descrições reais dos
comandos e despacha — uma porta de entrada na frente da caixa de ferramentas
inteira. Quando o GSD atualiza, comandos novos aparecem e removidos somem, com
zero manutenção no orchestrator.

## O que resolve

Em vez de decorar 57+ comandos GSD e saber a ordem correta, você só fala o que quer:

| Você fala | Orchestrator executa |
|-----------|---------------------|
| "continua de onde parei" | Detecta estado → resume-work ou execute-phase |
| "tem um bug no login" | Avalia complexidade → debug ou quick |
| "planeja e executa a fase 3" | discuss → plan → execute (sequência confirmada) |
| "como tá o projeto?" | Responde direto dos dados pré-carregados |
| "faz tudo automático" | autonomous |

## Arquitetura: dynamic discovery (zero drift)

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
- Comandos novos aparecem automaticamente no registro
- Comandos removidos desaparecem
- Argumentos e descrições refletem a versão atual
- Zero manutenção no orchestrator

## O que ele soma sobre `/gsd-do` + `/gsd-next`

| Feature | `/gsd-do` | `/gsd-next` | `/g` |
|---------|-----------|-------------|------|
| Texto livre → comando | Sim | Não | Sim |
| Auto-detecta estado | Não | Sim | Sim |
| Pré-carrega estado (0 turns) | Não | Não | Sim |
| Encadeia multi-step | Não | Não | Sim |
| Lê o config.json do GSD | Via workflow | Via workflow | Pré-carregado |
| Perguntas paralelas sem comando | Não | Não | Sim |
| Sugere verificação | Não | Não | Sim |
| Sugere worktrees/screenshots | Não | Não | Sim |

## Instalação

```bash
git clone https://github.com/DenisCDev/gsd-orchestrator.git ~/.gsd-orchestrator
cd ~/.gsd-orchestrator
bash install.sh
```

## Uso

```
/g quero começar o app de delivery
/g continua
/g tem um bug no formulário
/g planeja e executa a fase 4
/g em qual fase eu tô?
```

## Atualização

```bash
cd ~/.gsd-orchestrator
git pull
bash install.sh
```

O install.sh é idempotente: remove artefatos legados e sobrescreve com a versão atual.

## Pré-requisitos

- [Claude Code](https://claude.com/claude-code)
- [GSD](https://github.com/gsd-build/get-shit-done) instalado (`npx get-shit-done-cc@latest`)

## Decisões de arquitetura

### Por que dynamic discovery?

> O GSD evolui rápido. Uma routing table hardcoded diverge silenciosamente — roteia pra comandos que não existem ou ignora comandos novos. A dynamic discovery elimina esse risco lendo `~/.claude/commands/gsd/*.md` e `~/.claude/skills/gsd-*/SKILL.md` em runtime.

### Por que sem arquivo de preferências separado?

> O GSD já tem o `.planning/config.json` com settings reais (`skip_discuss`, `auto_advance`, `model_profile`). Manter um `preferences.md` separado cria duas fontes de verdade que podem divergir. O orchestrator lê o config.json do GSD diretamente.

### Por que routing semântico em vez de keywords?

> Claude é um LLM. Ele entende "fix the auth bug" e "tem um bug no login" igualmente bem. Dar a ele a lista de comandos com descrições e deixar que faça o matching semântico funciona em qualquer idioma, sem tabela de keywords.

### Estratégia de contexto (1M tokens)

> *"Most best practices are based on one constraint: Claude's context window fills up fast."* Com 1M de contexto, a única recomendação é chat novo para uma feature pesada completamente diferente. Sem /clear, sem /compact.
>
> — [Claude Code Best Practices](https://code.claude.com/docs/en/best-practices)

### Verificação como prática nº 1

> *"Include tests, screenshots, or expected outputs so Claude can check itself. This is the single highest-leverage thing you can do."*
>
> — [Claude Code Best Practices](https://code.claude.com/docs/en/best-practices)

### Injeção dinâmica de contexto

> Skills usam `!`command`` para executar comandos de shell antes de o conteúdo chegar ao Claude.
>
> — [Extend Claude with Skills](https://code.claude.com/docs/en/skills)

### Writer/Reviewer com worktrees

> *Uma sessão escreve, outra revisa com contexto fresco.*
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

## Licença

MIT
