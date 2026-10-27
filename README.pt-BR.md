<h1 align="center">GSD Orchestrator <code>/g</code></h1>

<p align="center"><a href="README.md">English</a> · <b>Português</b></p>

<p align="center">
  <b>Um comando que lê o GSD e encaminha o seu pedido para o fluxo certo</b>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/commands-discovered%20at%20runtime-43A48E?labelColor=171310" alt="comandos descobertos em tempo de execução">
  <img src="https://img.shields.io/badge/routing-installed%20registry-43A48E?labelColor=171310" alt="roteamento a partir do registro instalado">
  <img src="https://img.shields.io/badge/tested%20with-GSD%201.34.2-D4A24E?labelColor=171310" alt="testado com o GSD 1.34.2">
  <img src="https://img.shields.io/badge/license-MIT-D4A24E?labelColor=171310" alt="licença MIT">
</p>

<p align="center">
  <img src="assets/mtg-gandalf-shire.jpg" width="640" alt="Gandalf de braços erguidos no Condado, fogos de artifício tomando a forma de águias — arte de Dmitry Burmak, Tales of Middle-earth (2023)">
</p>

<p align="center">
  <sub><i>"share in an adventure"</i><br>
  — <b>O Hobbit</b>, capítulo I · arte de Dmitry Burmak para Magic: The Gathering, Tales of Middle-earth (2023)
</p>

O GSD tem mais de 57 comandos, e a escolha certa costuma depender do estado
atual do projeto. O `/g` lê os comandos instalados na sua máquina, verifica esse
estado e encaminha um pedido em linguagem natural para o fluxo correspondente.
Ele também pode encadear fluxos quando a tarefa precisa de mais de uma etapa.
As mudanças no registro instalado do GSD aparecem sem que seja preciso manter
uma tabela de roteamento separada.

## O que resolve

| Você diz | O orquestrador executa |
|----------|------------------------|
| "continua de onde parei" | Detecta o estado → resume-work ou execute-phase |
| "tem um bug no login" | Avalia a complexidade → debug ou quick |
| "planeja e executa a fase 3" | discuss → plan → execute (sequência confirmada) |
| "como está o projeto?" | Responde direto dos dados pré-carregados |
| "faz tudo automaticamente" | autonomous |

## Arquitetura: leitura do registro instalado

Em vez de manter uma lista própria de comandos, o orquestrador lê o registro
fornecido pela versão instalada do GSD:

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

**Quando o GSD é atualizado** (`npx get-shit-done-cc@latest`):
- Comandos novos aparecem automaticamente no registro
- Comandos removidos desaparecem
- Argumentos e descrições refletem a versão atual
- O orquestrador não precisa de uma segunda lista de comandos

## O que ele acrescenta em relação a `/gsd-do` + `/gsd-next`

| Recurso | `/gsd-do` | `/gsd-next` | `/g` |
|---------|-----------|-------------|------|
| Texto livre → comando | Sim | Não | Sim |
| Detecta o estado sozinho | Não | Sim | Sim |
| Pré-carrega o estado (0 turnos) | Não | Não | Sim |
| Encadeia várias etapas | Não | Não | Sim |
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
/g em que fase eu estou?
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

## Compatibilidade

Testado com o **GSD 1.34.2** (nomes baseados em skills: `/gsd-<command>`).

O GSD ≥1.30 moveu os comandos de `~/.claude/commands/gsd/*.md` (prefixo com dois-pontos, `/gsd:do`) para `~/.claude/skills/gsd-*/SKILL.md` (prefixo com hífen, `/gsd-do`). O orquestrador lê os dois locais, então versões mais antigas continuam funcionando, mas o despacho usa os nomes de skill com hífen ao invocar pela ferramenta Skill.

Se aparecerem erros de roteamento depois de atualizar o GSD, fixe a última versão que sabidamente funciona:

```bash
npx get-shit-done-cc@1.34.2
```

Depois, rode `bash install.sh` de novo a partir deste repositório para atualizar o orquestrador.

## Decisões de arquitetura

### Por que descoberta dinâmica?

> O GSD evolui rápido. Uma tabela de roteamento fixa no código diverge sem aviso — encaminha para comandos que não existem ou ignora os novos. A descoberta dinâmica elimina esse risco ao ler `~/.claude/commands/gsd/*.md` e `~/.claude/skills/gsd-*/SKILL.md` em tempo de execução.

### Por que não há um arquivo de preferências separado?

> O GSD já tem o `.planning/config.json` com as configurações reais (`skip_discuss`, `auto_advance`, `model_profile`). Manter um `preferences.md` separado cria duas fontes de verdade que podem divergir. O orquestrador lê o config.json do GSD diretamente.

### Por que roteamento semântico em vez de palavras-chave?

> O Claude é um LLM. Ele entende "fix the auth bug" e "there's a bug in login" igualmente bem. Entregar a ele a lista de comandos com as descrições e deixá-lo fazer a correspondência semântica funciona em qualquer idioma, sem tabela de palavras-chave.

### Estratégia de contexto (1M tokens)

> *"Most best practices are based on one constraint: Claude's context window fills up fast."* Com 1M de contexto, a única recomendação é abrir um chat novo para uma feature pesada completamente diferente. Sem /clear, sem /compact.
>
> — [Claude Code Best Practices](https://code.claude.com/docs/en/best-practices)

### Verificação como prática nº 1

> *"Include tests, screenshots, or expected outputs so Claude can check itself. This is the single highest-leverage thing you can do."*
>
> — [Claude Code Best Practices](https://code.claude.com/docs/en/best-practices)

### Injeção dinâmica de contexto

> As skills usam `!`command`` para executar comandos de shell antes de o conteúdo chegar ao Claude.
>
> — [Extend Claude with Skills](https://code.claude.com/docs/en/skills)

### Writer/Reviewer com worktrees

> *Uma sessão escreve, outra revisa com contexto limpo.*
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
