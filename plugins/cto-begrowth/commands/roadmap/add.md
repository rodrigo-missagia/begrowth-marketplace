---
command: "roadmap add $empresa"
description: Adiciona nova iniciativa ao backlog de uma empresa. Comando interativo.
args:
  empresa:
    description: "Empresa: utua, resolve, one-control, ou assiny"
    required: false
---

# /roadmap add

Adiciona nova iniciativa ao backlog de uma empresa. Este comando eh interativo e guia o usuario na coleta de informacoes.

**IMPORTANTE:** A pasta `knowledge/` fica na RAIZ DO PROJETO, nao dentro do plugin!

- CORRETO: `./knowledge/[empresa]/iniciativas/` (a partir da raiz do projeto)
- ERRADO: `cto-plugin/knowledge/` ou qualquer caminho dentro do plugin

## Uso

```
/roadmap add [empresa]
```

**Empresas validas:** `utua`, `resolve`, `one-control`, `assiny`

**Nota:** Holding nao tem iniciativas proprias - apenas ADRs e stack compartilhado.

## Fluxo de Execucao

### 1. Validar empresa

```
SE empresa nao informada:
  PERGUNTAR "Qual empresa? (utua, resolve, one-control, assiny)"

SE empresa nao em [utua, resolve, one-control, assiny]:
  ERRO "Empresa invalida. Holding nao tem iniciativas proprias."
```

### 2. Buscar proximo ID

```
LER ./knowledge/[empresa]/iniciativas/_index.md
proximo_id = _index.next_id  # Ex: "UTUA-006"

SE arquivo nao existe:
  ERRO "Iniciativas nao inicializadas. Execute inicializacao primeiro."
```

### 3. Carregar contexto da empresa

```
LER ./knowledge/[empresa]/contexto.md
EXTRAIR:
  - pilares[] (para validacao)
  - metas[] (para contexto)
  - dores[] (para sugestoes)

LER ./knowledge/[empresa]/pessoas/_index.md
EXTRAIR:
  - entities[] (para sugestao de owner)
```

### 4. Coletar dados interativamente

Perguntar ao usuario:

```
1. "Qual o nome da iniciativa?"
   -> nome (obrigatorio)

2. "Qual problema esta iniciativa resolve?"
   -> problema (obrigatorio)

3. "Quais pilares estrategicos ela endereca?"
   MOSTRAR pilares disponiveis de contexto.md
   -> pilares[] (pelo menos 1)

4. "Quais skills sao necessarios para executar?"
   -> skills_necessarios[]

5. "Quem sera o owner? (opcional)"
   MOSTRAR pessoas disponiveis
   -> owner (opcional)
```

### 5. Validacoes

```
# Verificar pilares
PARA cada pilar informado:
  SE pilar nao em contexto.pilares[]:
    ALERTA "Pilar [pilar] nao encontrado em contexto.md. Adicionar mesmo assim?"

# Verificar owner
SE owner informado:
  SE owner nao existe em ./knowledge/[empresa]/pessoas/[owner].md:
    ERRO "Owner [owner] nao encontrado em pessoas da empresa"

# Verificar skills contra vocabulario
LER ${CLAUDE_PLUGIN_ROOT}/schemas/vocabulario.yaml
PARA cada skill em skills_necessarios:
  # Skills sao livres, mas alertar se parecer estranho
```

### 6. Buscar contexto automatico

```
# Iniciativas similares
LER ./knowledge/[empresa]/iniciativas/_index.md
PARA cada entity em entities[]:
  SE keywords ou nome similares:
    INFO "Similar a: [entity.id] - [entity.nome]"

# ADRs relacionadas
LER ./knowledge/holding/adrs/_index.md
LER ./knowledge/[empresa]/adrs/_index.md (se existir)
PARA cada adr:
  SE keywords de tech em skills_necessarios:
    INFO "ADR relacionada: [adr.id] - [adr.titulo]"

# Gaps de skills
LER ./knowledge/[empresa]/pessoas/_index.md
PARA cada skill em skills_necessarios:
  SE skill nao coberto por nenhuma pessoa:
    ALERTA "Gap de skill: [skill]"
```

### 7. Criar arquivo da iniciativa

```
CRIAR ./knowledge/[empresa]/iniciativas/[ID].md

Conteudo:
---
type: iniciativa
id: [ID]
scope: [empresa]
version: 1
created_at: [data_hoje]
updated_at: [data_hoje]

nome: [nome]
status: backlog
owner: [owner ou null]
contributors: []

problema: [problema]
pilares: [pilares[]]

skills_necessarios: [skills[]]

depende_de:
  iniciativas: []
  adrs: [adrs_relacionadas[]]
  pessoas: []

sinergia_potencial: []

inicio: null
previsao_fim: null
progresso: 0
---

# [nome]

## Descricao

[problema]

## Decisoes

- [data] - Iniciativa criada

## Historico

- [data] - Criada como backlog

## Notas

(adicionar notas relevantes aqui)
```

### 8. Atualizar _index.md

```
ATUALIZAR ./knowledge/[empresa]/iniciativas/_index.md:
  - Adicionar em entities[]:
      id: [ID]
      nome: [nome]
      status: backlog
      owner: [owner ou null]
  - Incrementar total
  - Atualizar by_status.backlog++
  - Incrementar next_id
  - SE sem owner: Adicionar em alerts[]
```

### 9. Buscar sinergias

```
# Analisar como outras empresas podem se beneficiar
PARA cada outra_empresa em [utua, resolve, one-control, assiny] - [empresa]:
  LER ./knowledge/[outra_empresa]/contexto.md
  SE pilares ou dores similares:
    INFO "Sinergia potencial com [outra_empresa]: [motivo]"
    ADICIONAR em sinergia_potencial[]
```

## Output Esperado

```
+----------------------------------------------------+
| INICIATIVA CRIADA: [ID]                            |
+----------------------------------------------------+
|                                                    |
| Arquivo: ./knowledge/[empresa]/iniciativas/[ID].md |
|                                                    |
| DETALHES:                                          |
|   * Nome: [nome]                                   |
|   * Status: Backlog                                |
|   * Pilares: [pilares]                             |
|   * Owner: [owner ou "(nao definido)"]             |
|                                                    |
| CONTEXTO IDENTIFICADO:                             |
|   * Similar a: [iniciativas similares]             |
|   * ADR relacionada: [adrs]                        |
|                                                    |
| ALERTAS:                                           |
|   * Sem owner definido                             |
|   * Gap de skill: [skills]                         |
|                                                    |
| SINERGIAS POTENCIAIS:                              |
|   * [empresa]: [motivo]                            |
|                                                    |
+----------------------------------------------------+
```

## Arquivos Lidos

```
./knowledge/[empresa]/iniciativas/_index.md
./knowledge/[empresa]/contexto.md
./knowledge/[empresa]/pessoas/_index.md
./knowledge/holding/adrs/_index.md
./knowledge/[empresa]/adrs/_index.md
${CLAUDE_PLUGIN_ROOT}/schemas/vocabulario.yaml
${CLAUDE_PLUGIN_ROOT}/schemas/iniciativa.schema.yaml
```

## Arquivos Criados/Atualizados

```
./knowledge/[empresa]/iniciativas/[ID].md (criado)
./knowledge/[empresa]/iniciativas/_index.md (atualizado)
```

## Validacoes

- Empresa deve ser valida (nao holding)
- Nome eh obrigatorio
- Problema eh obrigatorio
- Pelo menos um pilar deve ser informado
- Owner (se informado) deve existir
- ID deve ser unico
