<h1 align="center">GSD Orchestrator <code>/g</code></h1>

<p align="center"><b>English</b> · <a href="README.pt-BR.md">Português</a></p>

<p align="center">
  <b>One command that reads GSD and routes your request to the right workflow</b>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/commands-discovered%20at%20runtime-43A48E?labelColor=171310" alt="commands discovered at runtime">
  <img src="https://img.shields.io/badge/routing-installed%20registry-43A48E?labelColor=171310" alt="routing from the installed registry">
  <img src="https://img.shields.io/badge/tested%20with-GSD%201.34.2-D4A24E?labelColor=171310" alt="tested with GSD 1.34.2">
  <img src="https://img.shields.io/badge/license-MIT-D4A24E?labelColor=171310" alt="MIT license">
</p>

<p align="center">
  <img src="assets/mtg-gandalf-shire.jpg" width="640" alt="Gandalf with arms raised in the Shire, fireworks taking the shape of eagles — art by Dmitry Burmak, Tales of Middle-earth (2023)">
</p>

<p align="center">
  <sub><i>"share in an adventure"</i><br>
  — <b>The Hobbit</b>, chapter I · art by Dmitry Burmak for Magic: The Gathering, Tales of Middle-earth (2023)
</p>

GSD has more than 57 commands, and the right choice often depends on the current
project state. `/g` reads the commands installed on your machine, checks that
state and routes a plain-language request to the matching workflow. It can also
chain workflows when the task needs more than one step. Changes in the installed
GSD registry are reflected without maintaining a separate routing table.

## What it solves

| You say | Orchestrator executes |
|---------|----------------------|
| "continue where I left off" | Detects state → resume-work or execute-phase |
| "there's a bug in login" | Evaluates complexity → debug or quick |
| "plan and execute phase 3" | discuss → plan → execute (confirmed sequence) |
| "how's the project going?" | Answers directly from pre-loaded data |
| "do everything automatically" | autonomous |

## Architecture: reading the installed registry

Instead of keeping its own command list, the orchestrator reads the registry
provided by the installed GSD version:

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

**When GSD updates** (`npx get-shit-done-cc@latest`):
- New commands appear automatically in the registry
- Removed commands disappear
- Arguments and descriptions reflect the current version
- The orchestrator does not need a second command list

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
