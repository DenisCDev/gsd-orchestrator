<purpose>
Orchestrador inteligente GSD. Recebe linguagem natural e transforma em workflows GSD otimos.
Nao e um dispatcher simples — entende estado, encadeia comandos, aplica best practices, e resolve intencoes compostas.
</purpose>

<required_reading>
Read all files referenced by the invoking prompt's execution_context before starting.
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
**Detectar estado completo do projeto.**

```bash
# Verificar se projeto existe
INIT=$(node "C:/Users/rodri/.claude/get-shit-done/bin/gsd-tools.cjs" init progress 2>/dev/null)
if [[ "$INIT" == @file:* ]]; then INIT=$(cat "${INIT#@file:}"); fi
```

Extrair do JSON:
- `project_exists` — tem `.planning/`?
- `roadmap_exists` — tem ROADMAP.md?
- `state_exists` — tem STATE.md?
- `current_phase` — fase atual
- `next_phase` — proxima fase
- `completed_count` / `phase_count` — progresso
- `paused_at` — trabalho pausado?

Se projeto existe, tambem carregar:
```bash
ROADMAP=$(node "C:/Users/rodri/.claude/get-shit-done/bin/gsd-tools.cjs" roadmap analyze 2>/dev/null)
STATE=$(node "C:/Users/rodri/.claude/get-shit-done/bin/gsd-tools.cjs" state-snapshot 2>/dev/null)
```

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

<step name="classify_intent">
**Classificar a intencao do usuario em categorias.**

Analise o input e classifique em UMA OU MAIS categorias:

**Intencoes Primarias (o que o usuario quer):**

| Categoria | Sinais no texto | Exemplos |
|-----------|----------------|----------|
| `START_PROJECT` | "comecar", "novo projeto", "inicializar", "setup" | "quero comecar o app de delivery" |
| `CONTINUE` | "continuar", "seguir", "onde parei", "proximo passo" | "continua de onde parei" |
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
| `SHIP` | "deploy", "release", "ship", "publica" | "ta pronto, quero fazer deploy" |
| `AUTONOMOUS` | "faz tudo", "roda automatico", "sem parar" | "executa tudo que falta automaticamente" |
| `MAP_CODEBASE` | "analisa o codigo", "mapeia o projeto", "entende a codebase" | "analisa esse repo que clonei" |
| `MANAGE_PHASES` | "adiciona fase", "remove fase", "insere fase" | "adiciona uma fase de testes E2E" |

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
→ /gsd:add-phase "Refatorar: {descricao}" → sugerir /gsd:discuss-phase → /gsd:plan-phase
```

**PLAN:**
```
Estado: NEEDS_DISCUSS + sem FAST → /gsd:discuss-phase {N} primeiro, depois /gsd:plan-phase {N}
Estado: NEEDS_PLAN ou FAST → /gsd:plan-phase {N}
```

**EXECUTE:**
```
Estado: NEEDS_EXECUTE → /gsd:execute-phase {N}
Estado: NEEDS_PLAN → Avisar: "Fase {N} ainda nao tem planos. Quer que eu planeje primeiro?" → /gsd:plan-phase {N} → /gsd:execute-phase {N}
```

**PLAN_AND_EXECUTE:**
```
Sequencia: /gsd:plan-phase {N} → (sugerir /clear) → /gsd:execute-phase {N}
Se NEEDS_DISCUSS: /gsd:discuss-phase {N} → /gsd:plan-phase {N} → /gsd:execute-phase {N}
```

**DISCUSS:**
```
→ /gsd:discuss-phase {N ou current}
```

**REVIEW:**
```
→ /gsd:verify-work {N ou current}
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
Estado: PHASE_COMPLETE → /gsd:complete-milestone
Estado: NEEDS_VERIFY → /gsd:verify-work primeiro, depois sugerir complete
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

Nota: Recomendo /clear entre cada etapa para contexto fresco.

Prossigo com o passo 1?
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

</step>

<step name="guard_rails">
**Aplicar guardas de seguranca.**

1. **Projeto inexistente:** Se o workflow requer `.planning/` e nao existe, redirecione para `/gsd:new-project`.

2. **Fase inexistente:** Se o usuario referencia uma fase que nao existe no ROADMAP, avise e oferca alternativas.

3. **Pular etapas:** Se o usuario quer executar mas nao tem plano, SEMPRE avise. Nao execute sem plano.

4. **Contexto pesado:** Se vai encadear 2+ comandos GSD pesados (plan, execute, discuss), recomende `/clear` entre eles. Nao force — sugira.

5. **Conflito de estado:** Se ha trabalho pausado (continue-here.md) e o usuario pede algo novo, pergunte se quer retomar ou abandonar o trabalho anterior.

6. **Debug ativo:** Se ha sessao de debug ativa e o usuario nao menciona debug, mencione que existe uma sessao ativa.
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

</step>

<step name="post_dispatch">
**Apos cada comando completar, orientar proximo passo.**

Depois que um comando GSD terminar, avalie se o workflow do usuario esta completo:

- Se sim → Finalize com um resumo curto do que foi feito
- Se nao → Sugira o proximo passo natural:

```
Pronto! Fase 3 planejada com 4 planos.

Proximo passo natural: `/gsd:execute-phase 3`
(Recomendo /clear antes para contexto fresco)
```

Nao force — informe e deixe o usuario decidir.
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

1. **Context freshness:** Sempre recomende /clear entre operacoes pesadas (discuss, plan, execute)
2. **Discuss before plan:** Se fase nao tem CONTEXT.md e usuario nao pediu para pular, sugira discuss primeiro
3. **Verify after execute:** Apos executar fase, lembre que /gsd:verify-work existe
4. **Model profile awareness:** Se o usuario menciona "rapido" ou "economiza", sugira /gsd:set-profile budget
5. **Atomic approach:** Para features grandes, prefira add-phase + full cycle sobre quick
6. **Debug for unknowns:** Se o usuario nao sabe a causa de um problema, prefira debug sobre quick fix
7. **State persistence:** Lembre o usuario de /gsd:pause-work antes de sair se ha trabalho em andamento
</best_practices>

<success_criteria>
- [ ] Input capturado e classificado corretamente
- [ ] Estado do projeto detectado automaticamente
- [ ] Workflow correto selecionado baseado em intent + estado
- [ ] Best practices aplicadas (clear entre heavy ops, discuss before plan, etc.)
- [ ] Ambiguidade resolvida com usuario quando necessario
- [ ] Comando(s) GSD invocados com argumentos corretos
- [ ] Proximo passo sugerido apos conclusao
- [ ] Nunca executa trabalho diretamente — sempre delega para comandos GSD
</success_criteria>
