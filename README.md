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

## Diferenciais vs `/gsd:do`

| Feature | `/gsd:do` | `/g` |
|---------|-----------|------|
| Roteia para comando GSD | Single command | Multi-step workflows |
| Detecta estado do projeto | Nao | Sim - analisa fase atual, PLANs, SUMMARYs |
| Encadeia comandos | Nao | Sim - discuss → plan → execute |
| Best practices automaticas | Nao | Sim - sugere /clear, discuss before plan |
| Resolve ambiguidade | Basico | Inteligente - cruza intent + estado |
| Sugere proximo passo | Nao | Sim - apos cada etapa |

## Instalacao

```bash
# Clone
git clone git@github.com:rodrigozan/gsd-orchestrator.git ~/.gsd-orchestrator

# Instala (copia para ~/.claude/)
cd ~/.gsd-orchestrator
bash install.sh
```

Ou manualmente:
```bash
cp commands/g.md ~/.claude/commands/g.md
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
```

## Pre-requisitos

- [Claude Code](https://claude.com/claude-code)
- [GSD](https://github.com/gsd-build/get-shit-done) instalado (`npx get-shit-done-cc@latest`)

## Como funciona

1. **Captura** - Recebe seu texto natural
2. **Detecta estado** - Analisa `.planning/` (fase atual, planos, progresso)
3. **Classifica intent** - Mapeia para categorias (build, fix, plan, continue, etc.)
4. **Resolve workflow** - Cruza intent + estado para sequencia otima de comandos
5. **Aplica guardas** - Verifica pre-condicoes, sugere best practices
6. **Executa** - Invoca os comandos GSD na ordem correta
7. **Orienta** - Sugere proximo passo apos conclusao

## Licenca

MIT
