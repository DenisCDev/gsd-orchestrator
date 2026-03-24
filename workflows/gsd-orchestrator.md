<purpose>
Smart GSD orchestrator. Matches natural language to GSD commands using a dynamically discovered command registry.

CRITICAL: Never hardcode GSD command names in routing logic. The command registry gathered in gather_context IS the source of truth. If GSD adds new commands, they appear automatically. If GSD removes commands, they disappear. Trust the registry.
</purpose>

<process>

<step name="gather_context">
**Gather GSD environment state. All commands run as visible Bash tool calls so the user sees what's happening.**

**Wave 1 — run these 4 commands in parallel:**

1. GSD installation check:
```bash
[ -f "$HOME/.claude/get-shit-done/bin/gsd-tools.cjs" ] && echo "INSTALLED" || echo "NOT_INSTALLED"
```

2. GSD version:
```bash
cat "$HOME/.claude/get-shit-done/VERSION" 2>/dev/null || echo "unknown"
```

3. Project state:
```bash
node "$HOME/.claude/get-shit-done/bin/gsd-tools.cjs" init progress 2>/dev/null || echo '{"project_exists":false}'
```

4. Available GSD commands:
```bash
result=$(for f in "$HOME/.claude/commands/gsd/"*.md "$HOME/.claude/skills/gsd-*/SKILL.md"; do [ -f "$f" ] && name=$(sed -n 's/^name: *//p' "$f" | head -1) && desc=$(sed -n 's/^description: *//p' "$f" | head -1 | tr -d '"') && hint=$(sed -n 's/^argument-hint: *//p' "$f" | head -1 | tr -d '"') && [ -n "$name" ] && echo "- /$name $hint — $desc"; done 2>/dev/null | sort -u); [ -n "$result" ] && echo "$result" || echo "NO_GSD_COMMANDS"
```

Store results as: `$GSD_STATUS`, `$GSD_VERSION`, `$INIT_STATE` (JSON), `$COMMAND_REGISTRY`.

**Wave 2 — only if `project_exists` is true in $INIT_STATE, run these 5 commands in parallel:**

5. Roadmap analysis:
```bash
node "$HOME/.claude/get-shit-done/bin/gsd-tools.cjs" roadmap analyze 2>/dev/null || echo '{}'
```

6. State snapshot:
```bash
node "$HOME/.claude/get-shit-done/bin/gsd-tools.cjs" state-snapshot 2>/dev/null || echo '{}'
```

7. Pause check:
```bash
ls .planning/continue-here.md 2>/dev/null && echo "PAUSED" || echo "NOT_PAUSED"
```

8. Debug sessions:
```bash
ls .planning/debug/*.md 2>/dev/null | grep -v resolved | head -3 || echo "NONE"
```

9. GSD config:
```bash
cat .planning/config.json 2>/dev/null || echo "NO_CONFIG"
```

If `project_exists` is false, skip Wave 2 — set defaults: roadmap={}, state={}, paused=NOT_PAUSED, debug=NONE, config=NO_CONFIG.
</step>

<step name="validate">
**Check prerequisites using data from gather_context.**

If $GSD_STATUS is "NOT_INSTALLED" OR $COMMAND_REGISTRY is "NO_GSD_COMMANDS":
→ Ask via AskUserQuestion:
  header: "GSD não instalado"
  question: "GSD não foi encontrado. Instalar agora?"
  options: ["Sim, instalar", "Não"]

→ If user confirms:
  1. Run: `npx get-shit-done-cc@latest`
  2. Verify: `[ -f "$HOME/.claude/get-shit-done/bin/gsd-tools.cjs" ] && echo "OK" || echo "FAIL"`
  3. If OK → re-run gather_context to load fresh GSD data, then continue to parse_state.
  4. If FAIL → "Instalação falhou. Tente manualmente: `npx get-shit-done-cc@latest`" → Stop.
→ If user declines → Stop.

If $ARGUMENTS is empty:
→ If project_exists is false → present the first-contact menu below, then Stop:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 GSD ► Primeiro contato
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Este repo não tem GSD configurado.

1. Tarefa rápida — resolver algo agora, sem cerimônia
   /g fix the pagination bug
   /g implementar login com OAuth

2. Projeto estruturado — roadmap, fases, pesquisa
   /gsd:new-project

3. Explorar comandos
   /gsd:help
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Use AskUserQuestion to ask which option (or let the user describe a task). Route: task description → quick, project setup → new-project, explore → help.

→ Otherwise (project exists), use state-aware defaults from match_and_route directly — the current state already determines the next action, no need to ask.
</step>

<step name="parse_state">
**Determine project state from gather_context data.**

| State | Condition |
|-------|-----------|
| `NO_PROJECT` | project_exists is false |
| `BETWEEN_MILESTONES` | PROJECT.md exists but no ROADMAP.md |
| `PAUSED` | continue-here.md exists |
| `HAS_DEBUG` | active debug sessions found |
| `NEEDS_DISCUSS` | current phase directory has no CONTEXT.md |
| `NEEDS_PLAN` | current phase has CONTEXT but no PLAN files |
| `NEEDS_EXECUTE` | plans exist without matching summaries |
| `PHASE_COMPLETE` | all plans have summaries |
| `MILESTONE_COMPLETE` | all phases in roadmap done |

From GSD Config (if exists), note relevant settings:
- `workflow.skip_discuss` — user configured to skip discuss
- `workflow.interactive` — true (interactive) or false (yolo)
- `workflow.auto_advance` — auto-advance between steps
- `model_profile` — quality/balanced/budget/inherit
- `git.branching_strategy` — none/phase/milestone
</step>

<step name="match_and_route">
**Match user intent to command(s) from the dynamic registry.**

Read $COMMAND_REGISTRY. Each entry has: `/command-name [args] — description`.
Match the user's input SEMANTICALLY against these descriptions. Claude's language understanding does the routing — no keyword tables needed. IMPORTANT: Always prefer specific action commands over meta-commands (/gsd:do, /gsd:next, /gsd:progress, /gsd:autonomous, /gsd:manager). This orchestrator IS the meta-layer — never delegate to another meta-layer.

**Routing rules:**

1. **Single command match** → dispatch directly
2. **Multi-step sequence** (e.g., "plan and execute") → present sequence, confirm, execute
3. **Ambiguous** (2-3 possible matches) → ask user to choose
4. **Side question** (answerable from gathered state) → answer directly, no command needed
5. **Vague input** ("continua", "vai", "next", "bora") → use state-aware defaults below

**State-aware defaults for vague inputs:**

| State | Action |
|-------|--------|
| PAUSED | Route to resume-work command |
| HAS_DEBUG | Route to debug command (resume) |
| NEEDS_EXECUTE | Route to execute-phase {current} |
| NEEDS_PLAN | Route to plan-phase {current} |
| NEEDS_DISCUSS | Route to discuss-phase {current} |
| PHASE_COMPLETE | Route to discuss or plan for next phase |
| MILESTONE_COMPLETE | Route to complete-milestone |
| BETWEEN_MILESTONES | Route to new-milestone |
| NO_PROJECT | Classify intent: specific task/action → quick (auto-bootstraps .planning/). Project setup → new-project. Exploration/help → help. Unclear → present first-contact menu. |
| Fallback | Route to progress |

**For multi-step sequences, respect GSD config:**
- If `skip_discuss` is true → omit discuss from sequences
- If `interactive` is false → reduce confirmations
- If `auto_advance` is true → proceed without asking between steps
</step>

<step name="guard_rails">
**Check before dispatching.**

1. **No project:** If command requires .planning/ and state is NO_PROJECT → suggest new-project first.
   Exception: these commands work WITHOUT .planning/: quick (auto-bootstraps), help, new-project, settings, set-profile, join-discord, update, profile-user, stats.
2. **No plan:** If executing but no plans exist → warn, suggest planning first
3. **Invalid phase:** If user references a specific phase number, verify it exists in the gathered Roadmap data. If not → "Fase {N} nao existe no roadmap. Fases disponiveis: {list}."
4. **Context switch:** If user is switching to a completely different feature domain → suggest new chat (NOT /clear — with 1M context, new chat is the only recommendation)
5. **Paused work conflict:** If PAUSED and user asks something unrelated → ask: resume or start fresh?
6. **Active debug:** If HAS_DEBUG and user doesn't mention debugging → mention the active session
7. **Verification after execution:** Handled in post_dispatch step — always suggest verify-work or add-tests after execution commands.
</step>

<step name="dispatch">
**Present and execute.**

**Single command:**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 GSD ► ORCHESTRATOR
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Input: {summary}
State: Phase {N}/{total} — {status}
Action: /{command} {args}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Invoke via Skill tool: `skill: "gsd:{command}", args: "{arguments}"`

**Multi-step:** Present full plan → confirm → execute sequentially.
**Side question:** Answer directly, no header.
**Ambiguous:** Present options, ask user.
</step>

<step name="post_dispatch">
**After command completes.**

Suggest the natural next step based on what just happened:
- After planning → suggest execute
- After execution → suggest verification (verify-work or add-tests)
- After phase complete → suggest next phase or milestone completion
- After milestone complete → suggest audit or new milestone

**Quality-of-life suggestions (when contextually appropriate):**
- UI work → "Cole um screenshot (Ctrl+V) — ajuda o Claude a entender o visual"
- Exploration → "Use Shift+Tab pra Plan Mode (read-only)"
- Critical changes (auth, payments, DB) → "Considere `claude -w reviewer` pra revisao paralela"

**Context strategy:** Never recommend /clear or /compact. Only suggest new chat for completely different heavy feature.
</step>

</process>

<important>
## Anti-drift guarantees

1. The command registry is discovered at runtime from BOTH `~/.claude/commands/gsd/*.md` AND `~/.claude/skills/gsd-*/SKILL.md`. Covers current and future GSD formats. When GSD updates, new commands appear automatically.
2. Preferences come from `.planning/config.json` (GSD's own config). No separate preferences file.
3. Routing is semantic (Claude matches intent to description), not keyword-based. Works in any language.
4. If a command exists in the registry that the workflow doesn't explicitly mention, Claude can still route to it based on description match. The registry is ALWAYS authoritative over this workflow.
</important>
