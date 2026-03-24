<purpose>
Orchestrador inteligente GSD. Recebe linguagem natural e transforma em workflows GSD otimos.
Nao e um dispatcher simples — entende estado, encadeia comandos, aplica best practices, e resolve intencoes compostas.

Diferente do `/gsd:do`: encadeia multiplos comandos, detecta estado, aprende preferencias do usuario, e sugere patterns avancados (worktrees, writer/reviewer) quando apropriado.
</purpose>

<required_reading>
Read all files referenced by the invoking prompt's execution_context before starting.
The SKILL.md pre-loads project state via dynamic context injection (`!`command``).
Use the pre-loaded data directly — do NOT re-run the init/roadmap/state bash commands.
</required_reading>

<process>

<step name="capture_input">
**Capturar e normalizar input.**

Se `$ARGUMENTS` vazio, pergunte via AskUserQuestion:

```
O que voce quer fazer? Descreva naturalmente — eu cuido do resto.

Exemplos:
- "quero comecar a trabalhar no projeto X"
- "continua de onde parei"
- "tem um bug no formulario de login"
- "planeja e executa a proxima fase"
- "adiciona autenticacao com Google"
```

Guarde o input original para referencia.
</step>

<step name="detect_state">
**Interpretar estado pre-carregado.**

O SKILL.md ja injetou os dados via `!`command``. Parse diretamente:

- Do `Project init` JSON: `project_exists`, `roadmap_exists`, `state_exists`, `current_phase`, `next_phase`, `completed_count`, `phase_count`
- Do `Roadmap analysis` JSON: fases, status de cada uma, plans/summaries counts
- Do `State snapshot` JSON: `paused_at`, `decisions`, `blockers`
- Do `Paused work`: se contem "HAS_PAUSED_WORK"
- Do `Debug sessions`: se contem paths de arquivos .md

**Montar snapshot de estado:**
- `NO_PROJECT` — sem .planning/
- `FRESH_PROJECT` — tem PROJECT.md mas sem ROADMAP (entre milestones)
- `NEEDS_DISCUSS` — fase atual sem CONTEXT.md
- `NEEDS_PLAN` — fase atual com CONTEXT mas sem PLANs
- `NEEDS_EXECUTE` — fase atual com PLANs nao executados (summaries < plans)
- `NEEDS_VERIFY` — fase completa, sem UAT
- `UAT_GAPS` — UAT com gaps diagnosticados
- `PHASE_COMPLETE` — fase atual toda executada e verificada
- `MILESTONE_COMPLETE` — todas as fases do milestone feitas
- `HAS_PAUSED_WORK` — continue-here.md existe
- `HAS_DEBUG_SESSION` — debug session ativa
</step>

<step name="load_preferences">
**Carregar preferencias aprendidas.**

O SKILL.md tambem injetou o conteudo de `preferences.md`. Parse os valores:
- `discuss_before_plan` — se o usuario costuma pular discuss
- `preferred_bug_approach` — tendencia para debug vs quick
- `preferred_feature_approach` — tendencia para add-phase vs quick
- `context_strategy` — como o usuario gerencia contexto
- Qualquer pattern especifico ja aprendido em "Learned Patterns"

Use esses valores para ajustar o roteamento silenciosamente (sem mencionar ao usuario).
</step>

<step name="classify_intent">
**Classificar a intencao do usuario em categorias.**

Analise o input e classifique em UMA OU MAIS categorias:

**Intencoes Primarias (o que o usuario quer):**

| Categoria | Sinais no texto | Exemplos |
|-----------|----------------|----------|
| `START_PROJECT` | "comecar", "novo projeto", "inicializar", "setup" | "quero comecar o app de delivery" |
| `CONTINUE` | "continuar", "seguir", "onde parei", "proximo passo", "vai", "bora" | "continua de onde parei" |
| `BUILD_FEATURE` | "adicionar", "criar", "implementar", "fazer" + funcionalidade especifica | "adiciona login com Google" |
| `FIX_BUG` | "bug", "erro", "quebrou", "nao funciona", "problema" | "o formulario nao salva" |
| `REFACTOR` | "refatorar", "limpar", "reorganizar", "melhorar" + scope amplo | "refatora o sistema de auth" |
| `PLAN` | "planejar", "plan", "pensar em como fazer" | "planeja a fase 3" |
| `EXECUTE` | "executar", "rodar", "build", "implementa" + fase especifica | "executa a fase 2" |
| `PLAN_AND_EXECUTE` | combinacao de plan + execute | "planeja e executa a fase 4" |
| `DISCUSS` | "discutir", "conversar sobre", "como deveria funcionar" | "vamos discutir como a API vai funcionar" |
| `REVIEW` | "revisar", "verificar", "testar", "ta certo?" | "verifica se a fase 2 ta ok" |
| `STATUS` | "status", "progresso", "como ta", "onde estamos" | "como ta o projeto?" |
| `QUICK_TASK` | tarefa pequena, pontual, autocontida | "muda a cor do botao pra azul" |
| `DEBUG` | "debugar", "investigar", "por que X" | "por que o build ta falhando?" |
| `NOTE` | "anota", "lembra", "depois eu", "ideia" | "anota: preciso revisar as rotas" |
| `RESEARCH` | "pesquisa", "como funciona", "qual a melhor forma" | "pesquisa como fazer SSR com streaming" |
| `SHIP` | "deploy", "release", "ship", "publica", "PR", "pull request" | "ta pronto, quero fazer deploy" |
| `AUTONOMOUS` | "faz tudo", "roda automatico", "sem parar" | "executa tudo que falta automaticamente" |
| `MAP_CODEBASE` | "analisa o codigo", "mapeia o projeto", "entende a codebase" | "analisa esse repo que clonei" |
| `MANAGE_PHASES` | "adiciona fase", "remove fase", "insere fase" | "adiciona uma fase de testes E2E" |
| `SIDE_QUESTION` | pergunta rapida sobre estado, nao requer acao | "qual fase eu to?", "quantos planos tem?" |
| `TRIVIAL_FIX` | "muda", "troca", "ajusta" + coisa minima, inline | "muda o titulo pra 'Dashboard'" |
| `FORENSICS` | "por que isso aconteceu", "post-mortem", "o que causou" | "por que o deploy de ontem quebrou?" |
| `NEXT_STEP` | "proximo", "next", "what's next" | "qual o proximo passo?" |

**Modificadores (como o usuario quer):**

| Modificador | Sinais | Efeito |
|-------------|--------|--------|
| `FAST` | "rapido", "simples", "so faz" | Pula discuss, vai direto pro plan/execute |
| `THOROUGH` | "bem feito", "completo", "com calma" | Discuss + research + plan_check + verify |
| `YOLO` | "sem perguntar", "automatico", "confia" | Modo autonomo, menos confirmacoes |
| `SPECIFIC_PHASE` | "fase N", "phase N" | Extrai numero da fase |

</step>

<step name="resolve_workflow">
**Resolver a sequencia de comandos GSD ideal.**

Cruze a intencao com o estado do projeto para determinar o workflow:

---

**SIDE_QUESTION:**
```
Responda diretamente usando os dados pre-carregados do SKILL.md (init, roadmap, state).
Nao invoque nenhum comando GSD. Nao consuma turns desnecessarios.
Exemplos: "qual fase?" → responde da roadmap. "quantos planos?" → responde do init.
```

**START_PROJECT:**
```
Estado: NO_PROJECT → /gsd:new-project
Estado: qualquer outro → Informar que projeto ja existe. Oferecer /gsd:new-milestone ou /gsd:map-codebase
```

**CONTINUE:**
```
Estado: HAS_PAUSED_WORK → /gsd:resume-work
Estado: HAS_DEBUG_SESSION → /gsd:debug (resume)
Estado: NEEDS_EXECUTE → /gsd:execute-phase {current}
Estado: NEEDS_PLAN → /gsd:plan-phase {current}
Estado: NEEDS_DISCUSS → /gsd:discuss-phase {current}
Estado: PHASE_COMPLETE → /gsd:discuss-phase {next} (ou /gsd:plan-phase {next})
Estado: MILESTONE_COMPLETE → /gsd:complete-milestone
Estado: NO_PROJECT → /gsd:new-project
Fallback → /gsd:progress (mostrar situacao)
```

**BUILD_FEATURE (feature grande, multi-arquivo):**
```
Se ja tem fase no roadmap que cobre isso → rotear para a fase existente
Se nao → /gsd:add-phase "{descricao}" → depois sugerir discuss/plan/execute

Com modificador FAST:
→ /gsd:quick "{descricao}"

Com modificador THOROUGH:
→ /gsd:add-phase → /gsd:discuss-phase → /gsd:plan-phase → /gsd:execute-phase
```

**BUILD_FEATURE (feature pequena, pontual):**
```
→ /gsd:quick "{descricao}"
```

**FIX_BUG:**
```
Se parece simples e localizado → /gsd:quick "{descricao}"
Se complexo ou nao sabe a causa → /gsd:debug "{descricao}"
```

**REFACTOR:**
```
Scope grande → /gsd:add-phase "Refatorar: {descricao}" → sugerir discuss/plan
Scope pequeno → /gsd:quick "Refatorar: {descricao}"

Se THOROUGH ou scope critico (auth, database, core):
→ Sugerir pattern Writer/Reviewer: "Para refactors criticos, considere usar
   `claude -w reviewer` em paralelo para revisar com contexto fresco enquanto
   a sessao principal implementa."
```

**PLAN:**
```
Estado: NEEDS_DISCUSS + sem FAST + preferences.discuss_before_plan == true:
→ /gsd:discuss-phase {N} primeiro, depois /gsd:plan-phase {N}
Estado: NEEDS_PLAN ou FAST → /gsd:plan-phase {N}
```

**EXECUTE:**
```
Estado: NEEDS_EXECUTE → /gsd:execute-phase {N}
Estado: NEEDS_PLAN → Avisar: "Fase {N} ainda nao tem planos. Quer que eu planeje primeiro?" → /gsd:plan-phase {N} → /gsd:execute-phase {N}
```

**PLAN_AND_EXECUTE:**
```
Sequencia: /gsd:plan-phase {N} → /gsd:execute-phase {N}
Se NEEDS_DISCUSS: /gsd:discuss-phase {N} → /gsd:plan-phase {N} → /gsd:execute-phase {N}
```

**DISCUSS:**
```
→ /gsd:discuss-phase {N ou current}
```

**REVIEW:**
```
→ /gsd:verify-work {N ou current}

Se THOROUGH ou feature critica:
→ Sugerir Writer/Reviewer: "Para revisao imparcial, considere abrir uma sessao
   paralela com `claude -w reviewer` que revisa com contexto fresco."
```

**STATUS:**
```
→ /gsd:progress
```

**QUICK_TASK:**
```
→ /gsd:quick "{descricao}"
```

**DEBUG:**
```
→ /gsd:debug "{descricao}"
```

**NOTE:**
```
Se e uma ideia/anotacao → /gsd:note "{texto}"
Se e uma tarefa futura → /gsd:add-todo "{texto}"
```

**RESEARCH:**
```
→ /gsd:research-phase {N} ou pesquisa generica se nao tem fase
```

**SHIP:**
```
Se usuario menciona "PR" ou "pull request" → /gsd:ship {N}
Se usuario menciona "deploy" ou "release":
  Estado: PHASE_COMPLETE → /gsd:ship {current} (cria PR primeiro)
  Estado: MILESTONE_COMPLETE → /gsd:complete-milestone (archiva + tag)
  Estado: NEEDS_VERIFY → /gsd:verify-work primeiro, depois sugerir ship
```

**TRIVIAL_FIX:**
```
→ /gsd:fast "{descricao}"
(Sem subagents, inline, para coisas de 1 linha)
```

**FORENSICS:**
```
→ /gsd:forensics "{descricao}"
(Post-mortem investigativo — diferente de debug que e para bug ativo)
```

**NEXT_STEP:**
```
→ /gsd:next
(Auto-detecta estado e invoca o proximo comando correto)
```

**AUTONOMOUS:**
```
→ /gsd:autonomous [--from {N} se especificado]
```

**MAP_CODEBASE:**
```
→ /gsd:map-codebase
```

**MANAGE_PHASES:**
```
"adiciona" → /gsd:add-phase "{descricao}"
"insere entre X e Y" → /gsd:insert-phase {X} "{descricao}"
"remove" → /gsd:remove-phase {N}
```

---

**Regra de ouro para workflows encadeados:**
Se o workflow resolve em MAIS de um comando GSD sequencial, informe o usuario do plano completo antes de executar. Exemplo:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 GSD ► ORCHESTRATOR
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Entendi: "planeja e executa a fase 3"

Workflow:
 1. /gsd:discuss-phase 3  — capturar contexto (fase ainda nao discutida)
 2. /gsd:plan-phase 3     — criar planos de execucao
 3. /gsd:execute-phase 3  — implementar

Prossigo com o passo 1?
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

</step>

<step name="guard_rails">
**Aplicar guardas de seguranca.**

1. **Projeto inexistente:** Se o workflow requer `.planning/` e nao existe, redirecione para `/gsd:new-project`.

2. **Fase inexistente:** Se o usuario referencia uma fase que nao existe no ROADMAP, avise e oferca alternativas.

3. **Pular etapas:** Se o usuario quer executar mas nao tem plano, SEMPRE avise. Nao execute sem plano.

4. **Feature pesada diferente:** Se o usuario esta mudando de feature/dominio completamente diferente (ex: estava em auth e agora quer mexer em payments), sugira abrir novo chat:
   "Voce ta mudando de contexto (auth → payments). Com 1M de contexto da pra continuar aqui, mas pra feature pesada diferente um novo chat garante foco maximo. Quer continuar aqui ou abrir novo?"
   IMPORTANTE: Nao recomende /clear nem /compact — com 1M de contexto, o modelo gerencia bem. A unica recomendacao e novo chat para feature completamente diferente.

5. **Conflito de estado:** Se ha trabalho pausado (continue-here.md) e o usuario pede algo novo, pergunte se quer retomar ou abandonar o trabalho anterior.

6. **Debug ativo:** Se ha sessao de debug ativa e o usuario nao menciona debug, mencione que existe uma sessao ativa.

7. **Verificacao apos execucao:** Sempre sugira verificacao depois de executar. A Anthropic considera isso a pratica de maior impacto:
   > "Include tests, screenshots, or expected outputs so Claude can check itself. This is the single highest-leverage thing you can do."
   Sugira /gsd:verify-work ou /gsd:add-tests conforme o caso.
</step>

<step name="present_and_dispatch">
**Apresentar decisao e executar.**

**Para workflow de comando unico:**

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 GSD ► ORCHESTRATOR
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

**Input:** {resumo do que usuario pediu}
**Estado:** Fase {N}/{total} — {status}
**Acao:** /gsd:{comando} {args}
**Razao:** {explicacao curta}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Invoke the command via Skill tool: `skill: "gsd:{command}", args: "{arguments}"`

**Para workflow multi-step:**

Apresente o plano completo (como no exemplo do step anterior).
Pergunte confirmacao via AskUserQuestion.
Execute passo a passo, invocando cada skill sequencialmente.

**Para intencoes ambiguas:**

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 GSD ► ORCHESTRATOR
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

"{input do usuario}" pode ser:

1. /gsd:add-phase — Ciclo completo (recomendado para escopo grande)
2. /gsd:quick — Execucao rapida (se escopo e pequeno)
3. /gsd:debug — Investigacao (se e um problema)

Qual se encaixa melhor?
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Para SIDE_QUESTION:**

Responda diretamente, sem header nem invocacao de comando. Curto e direto.

</step>

<step name="post_dispatch">
**Apos cada comando completar, orientar proximo passo.**

Depois que um comando GSD terminar, avalie se o workflow do usuario esta completo:

- Se sim → Finalize com um resumo curto do que foi feito
- Se nao → Sugira o proximo passo natural:

```
Fase 3 planejada com 4 planos.

Proximo passo: `/gsd:execute-phase 3` ou `/g executa fase 3`
```

**Sempre sugerir verificacao quando apropriado:**
- Apos execute-phase → sugira `/gsd:verify-work` ou `/gsd:add-tests`
- Apos refactor grande → sugira Writer/Reviewer pattern com worktree
- Apos milestone completo → sugira `/gsd:audit-milestone`

**Para worktree suggestions (features complexas):**
Quando a feature e critica ou complexa, sugira o pattern de worktree:
```
Dica: para mudancas criticas, considere `claude -w review-auth`
em paralelo para revisao imparcial com contexto fresco.
```

Nao force — informe e deixe o usuario decidir.
</step>

<step name="learn_preferences">
**Aprender preferencias do usuario (silencioso).**

Apos cada interacao bem-sucedida, avalie se houve um pattern novo:

- Usuario SEMPRE pula discuss? → Atualizar preferences: `discuss_before_plan: false`
- Usuario prefere quick para bugs? → Atualizar preferences: `preferred_bug_approach: quick`
- Usuario escolheu add-phase 3x seguidas para features? → Atualizar preferences: `preferred_feature_approach: add-phase`
- Usuario pediu worktree? → Anotar que usa worktrees

**Para atualizar:** Use Edit tool no arquivo de preferences (localizado no mesmo diretorio do SKILL.md, tipicamente `~/.claude/skills/g/preferences.md`):
- Adicione o pattern em "Learned Patterns" com data
- Atualize o valor em "Defaults" se aplicavel

**IMPORTANTE:** So atualize quando houver evidencia clara (2+ interacoes com mesmo pattern). Nunca atualize baseado em uma unica interacao. Nunca mencione ao usuario que esta aprendendo — faca silenciosamente.
</step>

</process>

<decision_matrix>
## Matriz de Decisao Rapida

Quando o input e vago e o projeto existe, use o estado para decidir:

| Estado do Projeto | Input Vago ("continua", "vai") | Acao |
|---|---|---|
| Trabalho pausado | Resume | `/gsd:resume-work` |
| Fase com plans pendentes | Executa | `/gsd:execute-phase {current}` |
| Fase sem plans | Planeja | `/gsd:plan-phase {current}` |
| Fase sem contexto | Discute | `/gsd:discuss-phase {current}` |
| UAT com gaps | Fix gaps | `/gsd:plan-phase {current} --gaps` |
| Fase completa | Proxima fase | `/gsd:discuss-phase {next}` |
| Milestone completo | Finaliza | `/gsd:complete-milestone` |
| Tudo feito | Novo milestone | `/gsd:new-milestone` |

Quando o input e vago e NAO tem projeto:
→ `/gsd:new-project`

</decision_matrix>

<best_practices>
## Best Practices Aplicadas Automaticamente

1. **Contexto com 1M tokens:** Nao recomende /clear nem /compact. Com 1M de contexto, continue trabalhando normalmente. A UNICA recomendacao e abrir novo chat quando mudar para uma feature pesada completamente diferente.

2. **Verificacao e a pratica #1:** Sempre sugira verificacao apos execucao. Testes, screenshots, outputs esperados. Isso e o que a Anthropic considera o maior leverage.

3. **Discuss before plan:** Se fase nao tem CONTEXT.md e preferences nao indicam skip, sugira discuss primeiro. Mas respeite o modificador FAST.

4. **Writer/Reviewer para mudancas criticas:** Para refactors grandes, features de auth/payment/database, sugira usar `claude -w <name>` em paralelo para revisao imparcial.

5. **Subagents para investigacao:** Para pesquisa ampla ou exploracao de codebase, prefira delegar para subagents (Explore) ao inves de poluir o contexto principal.

6. **Model profile awareness:** Se o usuario menciona "rapido" ou "economiza", sugira /gsd:set-profile budget. Se menciona "capricha" ou "importante", sugira quality.

7. **Atomic approach:** Para features grandes, prefira add-phase + full cycle sobre quick. Quick e para coisas pontuais.

8. **Debug for unknowns:** Se o usuario nao sabe a causa, prefira debug sobre quick fix. Debug usa metodo cientifico e persiste entre sessoes.

9. **Hooks sugeridos na primeira interacao:** Se o usuario nunca configurou hooks, mencione uma vez:
   "Dica: hooks automatizam tarefas repetitivas — auto-format apos edits, notificacoes desktop, protecao de arquivos sensiveis. Configure com `/gsd:settings` ou edite `.claude/settings.json`."
   So mencione isso UMA VEZ. Anote em preferences que ja sugeriu.

10. **Screenshots para trabalho de UI:** Quando o intent envolve UI (frontend, design, layout, componentes visuais), lembre o usuario:
    "Cole um screenshot (Ctrl+V) ou arraste a imagem pra ca — isso ajuda o Claude a entender exatamente o que precisa mudar."
    So sugira quando o contexto for visual e o usuario nao tiver enviado imagem.

11. **Plan Mode para exploracao:** Quando o intent e RESEARCH ou o usuario quer entender o codigo antes de mudar, sugira:
    "Use Shift+Tab pra entrar em Plan Mode — Claude explora o codigo sem modificar nada."
    Util para discuss-phase e research-phase onde exploracao read-only e o objetivo.

12. **Trivial vs Quick vs Phase:** Calibre a ferramenta ao tamanho da tarefa:
    - 1 linha / rename / config → `/gsd:fast` (sem subagents, inline)
    - Tarefa pontual ate ~50 linhas → `/gsd:quick` (1 executor)
    - Feature multi-arquivo → `/gsd:add-phase` + full cycle
</best_practices>

<success_criteria>
- [ ] Input capturado e classificado corretamente
- [ ] Estado do projeto detectado via dados pre-carregados (sem bash commands extras)
- [ ] Preferences do usuario consultadas para ajustar roteamento
- [ ] Workflow correto selecionado baseado em intent + estado + preferences
- [ ] Best practices aplicadas (verificacao, worktrees, subagents)
- [ ] Nenhuma recomendacao de /clear ou /compact (1M context)
- [ ] Ambiguidade resolvida com usuario quando necessario
- [ ] Comando(s) GSD invocados com argumentos corretos
- [ ] Proximo passo sugerido apos conclusao (com enfase em verificacao)
- [ ] Preferences atualizadas silenciosamente quando pattern detectado
- [ ] Nunca executa trabalho diretamente — sempre delega para comandos GSD
</success_criteria>
