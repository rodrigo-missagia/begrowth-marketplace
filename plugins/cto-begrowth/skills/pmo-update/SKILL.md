---
name: pmo-update
description: |
  Use this skill when the user provides a batch update document (like UPDATE_INICIATIVAS.md)
  containing status updates, scope changes, decisions, or notes for multiple initiatives
  of a SINGLE company. Parses the document, launches sub-agents in parallel to analyze
  each initiative, then presents each update plan individually for user approval before executing.
  Triggers on phrases like "processar updates", "atualizar iniciativas", "batch update",
  "processe o documento", "update de iniciativas", "pmo update", "status update em massa",
  or when the user provides a file/text with multiple initiative status updates.
---

# PMO Update Orchestrator

Processa documentos de atualizacao em lote e coordena o update abrangente dos arquivos de iniciativa de UMA empresa por vez.

## Quando Usar

Esta skill e ativada quando o usuario:

- Fornece um documento com updates de multiplas iniciativas (ex: UPDATE_INICIATIVAS.md)
- Cola texto com status de varias iniciativas de uma mesma empresa
- Pede para "processar updates", "atualizar iniciativas", "batch update"
- Menciona "pmo update" ou "status update"
- Referencia um arquivo com atualizacoes de iniciativas

**Frases de trigger:**

- "processar updates"
- "atualizar iniciativas"
- "batch update"
- "processe o documento de update"
- "update de iniciativas"
- "pmo update"
- "status update em massa"
- "processe os updates das iniciativas"
- "use agent pmo-update"

## Processo de Execucao

### FASE 1 - Carregar Contexto

```
1. LER o documento de entrada (caminho de arquivo ou texto colado)
2. IDENTIFICAR empresa-alvo pelos prefixos de ID (ASSINY-, UTUA-, RESOLVE-, ONE-CONTROL-)
   - Se multiplas empresas: PERGUNTAR qual processar
   - Se nenhuma empresa identificavel: PERGUNTAR ao usuario
3. LER ./knowledge/[empresa]/iniciativas/_index.md
4. CONSTRUIR mapa: { ID -> { nome, status, progresso, owner, path } }
5. LER ${CLAUDE_PLUGIN_ROOT}/schemas/iniciativa.schema.yaml para referencia
```

### FASE 2 - Parsear Documento

```
1. SEGMENTAR o documento por iniciativa:
   - Procurar padroes de ID: [EMPRESA]-[NNN] (ex: ASSINY-006)
   - Procurar cabecalhos de secao (## ASSINY-006 - Nome)
   - Procurar listas numeradas referenciando iniciativas
2. Para CADA segmento:
   - EXTRAIR texto bruto do update
   - MAPEAR para iniciativa existente no lookup
   - Se nao encontrar: MARCAR como POTENCIAL NOVA INICIATIVA
3. APRESENTAR resultado do parsing ao usuario:
```

Apresentar este resumo:

```
DOCUMENTO PARSEADO
==================
Empresa: [EMPRESA]
Data: [data de hoje]
Fonte: [nome do arquivo ou "texto colado"]

UPDATES IDENTIFICADOS: [N]
  1. [ID] - [nome] (status atual: [status])
  2. [ID] - [nome] (status atual: [status])
  ...

NOVAS INICIATIVAS DETECTADAS: [N]
  1. [descricao breve do que foi mencionado]
  ...

ALERTAS:
  * [IDs mencionados mas nao encontrados]
  * [outras inconsistencias]

Iniciar processamento das [N] iniciativas? (sim/nao)
```

Aguardar confirmacao do usuario antes de prosseguir.

### FASE 3 - Lancar Sub-agentes de Analise (PARALELO)

Para cada iniciativa identificada, lancar um sub-agente `pmo-initiative-updater` **em paralelo**.

Cada sub-agente recebe um prompt detalhado contendo:

1. O ID da iniciativa
2. O nome da empresa
3. O texto bruto do update daquela iniciativa
4. A data de hoje
5. Instrucoes para: ler a iniciativa, ler correlatas, computar mudancas, apresentar plano e pedir aprovacao

**IMPORTANTE:** Lancar sub-agentes usando a ferramenta Agent (tipo `general-purpose`). Lancar TODOS em uma unica mensagem para maximo paralelismo.

Antes de lancar os sub-agentes, LER o arquivo do agente especializado:
`${CLAUDE_PLUGIN_ROOT}/agents/pmo-initiative-updater.md`

Incluir o conteudo COMPLETO desse arquivo como instrucoes no prompt de cada sub-agente, junto com o contexto especifico da iniciativa.

Template do prompt para sub-agente:

```
You are a PMO Initiative Updater sub-agent. Follow the instructions below.

[COLAR AQUI O CONTEUDO COMPLETO de ${CLAUDE_PLUGIN_ROOT}/agents/pmo-initiative-updater.md]

---

Process a comprehensive update for initiative [ID] of company [empresa].

**Today's date:** [YYYY-MM-DD]
**Working directory:** [diretorio de trabalho atual]

**Update text from the status document:**
---
[texto bruto do update desta iniciativa]
---

Execute all steps: read the initiative, read correlates, compute changes, present the update plan to the user via AskUserQuestion, and if approved execute the update.

Remember: ZERO data loss. Preserve all existing content. Restructure to the enhanced template.
```

### FASE 4 - Coletar Resultados

Conforme sub-agentes completam (aprovados+executados ou rejeitados):

- Coletar cada resultado
- Rastrear: quais foram aprovados, rejeitados, o que mudou

### FASE 5 - Atualizar \_index.md

Apos TODOS os sub-agentes completarem:

```
LER ./knowledge/[empresa]/iniciativas/_index.md

PARA cada iniciativa atualizada:
  ENCONTRAR entrada em entities[]
  ATUALIZAR: status, progresso, owner (se mudou)

PARA cada nova iniciativa criada:
  ADICIONAR entrada em entities[]
  INCREMENTAR total
  ATUALIZAR by_status
  ATUALIZAR last_id e next_id

RECALCULAR:
  - contagens by_status
  - total
  - health e alerts
  - next_id (deve ser > todos os IDs existentes)

ATUALIZAR: version, updated_at

GRAVAR ./knowledge/[empresa]/iniciativas/_index.md
```

Seguir o protocolo definido em `${CLAUDE_PLUGIN_ROOT}/workflows/on-index-update.md`.

### FASE 6 - Gerar Relatorio

Criar arquivo de relatorio estruturado:

**Caminho:** `./knowledge/[empresa]/iniciativas/updates/YYYYMMDD - Status Update - [Empresa].md`

**Conteudo:**

```markdown
---
type: status_update
scope: [empresa]
data: [YYYY-MM-DD]
fonte: "[nome do documento de entrada]"
iniciativas_atualizadas: [N]
iniciativas_criadas: [N]
iniciativas_rejeitadas: [N]
---

# Status Update - [Empresa] - [DD/MM/YYYY]

## Resumo Executivo

- Iniciativas atualizadas: [N]
- Novas iniciativas: [N]
- Updates rejeitados: [N]
- Bloqueios ativos: [N]
- Riscos identificados: [N]

## Mudancas por Iniciativa

### [ID] - [nome]

**Status:** [old] -> [new] | **Progresso:** [old]% -> [new]%

**Resumo do update:**
[Texto organizado e processado - versao limpa e profissional]

**Mudancas aplicadas:**

- [lista de mudancas]

---

(repete para cada iniciativa)

## Alertas

### Bloqueios Ativos

- [ID]: [descricao]

### Riscos Altos

- [ID]: [descricao]

### Dependencias Cruzadas Descobertas

- [ID-A] depende de [ID-B]: [motivo]

## Arquivos Modificados

- [lista de arquivos]
```

### FASE 7 - Apresentar Resumo Final

```
PMO UPDATE COMPLETO
===================
Empresa: [EMPRESA]
Data: [YYYY-MM-DD]

Resultados:
  Atualizadas: [N] iniciativas
  Criadas: [N] novas iniciativas
  Rejeitadas: [N] updates

Report salvo em:
  ./knowledge/[empresa]/iniciativas/updates/YYYYMMDD - Status Update - [Empresa].md

_index.md atualizado:
  ./knowledge/[empresa]/iniciativas/_index.md

Alertas:
  [bloqueios, riscos, sem owner, etc.]
```

## Tratamento de Erros

| Erro                             | Acao                                                                       |
| -------------------------------- | -------------------------------------------------------------------------- |
| Documento vazio                  | ABORTAR: "Documento vazio. Forneca texto ou caminho de arquivo."           |
| Knowledge nao inicializada       | ABORTAR: "Knowledge base nao inicializada. Execute `/cto setup` primeiro." |
| Empresa nao clara                | PERGUNTAR: "Qual empresa? (utua, resolve, one-control, assiny)"            |
| Multiplas empresas               | PERGUNTAR qual processar (uma por vez)                                     |
| ID mencionado mas nao encontrado | AVISAR no resumo de parsing, perguntar se deve criar novo                  |
| Sub-agente falha                 | Reportar erro, continuar com demais iniciativas                            |
| Usuario rejeita update           | Pular, registrar no relatorio como rejeitado                               |
| \_index.md inconsistente         | Auto-corrigir na Fase 5 (recalcular totais, next_id)                       |
| Diretorio updates/ nao existe    | Criar antes de gravar relatorio                                            |

## Comandos Relacionados

Apos usar o pmo-update, sugerir:

- `/roadmap status [empresa]` - Ver status atualizado
- `/roadmap priorize [empresa]` - Repriorizar backlog
- `/people status [empresa]` - Ver alocacoes

## Arquivos Necessarios

Para executar, a skill precisa acessar:

- `${CLAUDE_PLUGIN_ROOT}/schemas/iniciativa.schema.yaml` - Schema de iniciativa
- `${CLAUDE_PLUGIN_ROOT}/schemas/vocabulario.yaml` - Vocabulario controlado
- `${CLAUDE_PLUGIN_ROOT}/workflows/on-index-update.md` - Protocolo de update do index
- `${CLAUDE_PLUGIN_ROOT}/workflows/on-entity-create.md` - Protocolo de criacao de entidade
- `./knowledge/[empresa]/iniciativas/_index.md` - Index de iniciativas
- `./knowledge/[empresa]/iniciativas/[ID].md` - Arquivos de iniciativa
- `./knowledge/[empresa]/contexto.md` - Contexto da empresa

## Agente Associado

Esta skill utiliza o agente `pmo-initiative-updater` localizado em:
`${CLAUDE_PLUGIN_ROOT}/agents/pmo-initiative-updater.md`

O agente contem a logica completa de analise, validacao e update de cada iniciativa.
E lancado como sub-agente `general-purpose` (nao como subagent_type dedicado) para processar cada iniciativa individualmente em paralelo. O conteudo completo do arquivo do agente deve ser incluido no prompt de cada sub-agente.
