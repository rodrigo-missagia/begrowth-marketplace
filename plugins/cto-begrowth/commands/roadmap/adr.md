---
command: "roadmap adr $escopo"
description: Cria nova Architecture Decision Record (ADR). Comando interativo.
args:
  escopo:
    description: "Escopo: holding, utua, resolve, one-control, ou assiny"
    required: false
---

# /roadmap adr

Cria nova Architecture Decision Record (ADR) para documentar decisoes tecnicas.

## Uso

```
/roadmap adr [escopo]
```

**Escopos validos:**
- `holding` - ADR do grupo (BG-ADR-XXX) - decisoes que afetam multiplas empresas
- `utua` | `resolve` | `one-control` | `assiny` - ADR local (EMPRESA-ADR-XXX)

## Fluxo de Execucao

### 1. Validar escopo

```
SE escopo nao informado:
  PERGUNTAR "Qual o escopo da ADR?"
  MOSTRAR opcoes: holding, utua, resolve, one-control, assiny

SE escopo nao em [holding, utua, resolve, one-control, assiny]:
  ERRO "Escopo invalido"

# Determinar path
SE escopo == "holding":
  path_adrs = ./knowledge/holding/adrs/
  prefixo = "BG-ADR"
SENAO:
  path_adrs = ./knowledge/[escopo]/adrs/
  prefixo = upper(escopo) + "-ADR"
```

### 2. Verificar historico de ADRs

```
LER [path_adrs]/_index.md
EXTRAIR:
  - total
  - next_id
  - entities[]

# Listar ADRs existentes
INFO "ADRs existentes ([total]):"
PARA cada adr em entities[]:
  MOSTRAR: [id] - [titulo] ([status])

# Listar propostas pendentes
propostas = filtrar(entities[], status == "proposta")
SE propostas:
  ALERTA "Decisoes pendentes:"
  PARA cada proposta:
    MOSTRAR: [id] - [titulo]
```

### 3. Verificar ADRs similares

```
PERGUNTAR "Qual o titulo da decisao?"
-> titulo

# Buscar por keywords no titulo
keywords = extrair_keywords(titulo)

similares = []
PARA cada adr em entities[]:
  SE keywords_match(keywords, adr.keywords OU adr.titulo):
    similares.append(adr)

SE similares:
  ALERTA "ADRs possivelmente relacionadas:"
  PARA cada similar:
    MOSTRAR: [id] - [titulo]
  PERGUNTAR "Continuar criando nova ADR?"
  SE nao: ABORTAR
```

### 4. Coletar dados da ADR

```
# Titulo ja coletado acima

PERGUNTAR "Qual o contexto? (problema que levou a esta decisao)"
-> contexto (obrigatorio)

PERGUNTAR "Quais alternativas foram consideradas?"
-> alternativas[] (pelo menos 2)
# Formato: nome da alternativa + breve descricao

PERGUNTAR "Qual decisao foi tomada?"
-> decisao (obrigatorio)

PERGUNTAR "Quais as consequencias desta decisao?"
-> consequencias (obrigatorio)

SE escopo == "holding":
  PERGUNTAR "Quais empresas sao afetadas?"
  MOSTRAR opcoes: utua, resolve, one-control, assiny (multi-select)
  -> empresas_afetadas[]
SENAO:
  empresas_afetadas = [escopo]

PERGUNTAR "Esta ADR substitui alguma existente?"
-> substitui (opcional, ID de ADR existente)
```

### 5. Gerar proximo ID

```
LER [path_adrs]/_index.md
next_num = _index.next_id  # Ex: 4

# Formatar ID
proximo_id = prefixo + "-" + pad(next_num, 3)
# Ex: BG-ADR-004 ou UTUA-ADR-001
```

### 6. Se substitui outra ADR

```
SE substitui:
  # Validar que existe
  SE nao existe [path_adrs]/[substitui].md:
    ERRO "ADR [substitui] nao encontrada"

  # Atualizar a antiga
  LER [path_adrs]/[substitui].md
  adr_antiga.status = "substituida"
  adr_antiga.substituida_por = proximo_id
  adr_antiga.updated_at = data_hoje
  SALVAR [path_adrs]/[substitui].md

  # Atualizar _index.md para a antiga
  ATUALIZAR entity correspondente em _index
```

### 7. Criar arquivo da ADR

```
CRIAR [path_adrs]/[proximo_id].md

Conteudo:
---
type: adr
id: [proximo_id]
scope: [escopo]
version: 1
created_at: [data_hoje]
updated_at: [data_hoje]

titulo: [titulo]
status: proposta

data_decisao: [data_hoje]
decisor: [usuario ou "a definir"]
revisao_prevista: [data_hoje + 6 meses]

substitui: [substitui ou null]
substituida_por: null

empresas_afetadas:
  - [empresas]

iniciativas_relacionadas: []

keywords:
  - [keywords extraidas do titulo e contexto]
---

# [titulo]

## Status

**Proposta** - Aguardando revisao e aceite.

## Contexto

[contexto]

## Decisao

[decisao]

## Alternativas Consideradas

### 1. [alternativa 1]
[descricao]

### 2. [alternativa 2]
[descricao]

[... mais alternativas ...]

## Consequencias

### Positivas
- [consequencias positivas]

### Negativas
- [consequencias negativas]

### Neutras
- [consequencias neutras/trade-offs]

## Notas

- [data] - ADR criada como proposta

```

### 8. Atualizar _index.md

```
ATUALIZAR [path_adrs]/_index.md:
  - Adicionar em entities[]:
      id: [proximo_id]
      titulo: [titulo]
      status: proposta
      data_decisao: [data_hoje]
      decisor: [usuario]
  - Incrementar total
  - Incrementar next_id
```

### 9. Identificar impactos

```
# Buscar iniciativas que podem ser afetadas
afetadas = []

PARA cada empresa em empresas_afetadas:
  LER ./knowledge/[empresa]/iniciativas/_index.md
  PARA cada iniciativa:
    SE keywords_match(adr.keywords, iniciativa):
      afetadas.append(iniciativa)

SE afetadas:
  INFO "Iniciativas potencialmente afetadas:"
  PARA cada ini:
    MOSTRAR: [id] - [nome]
  PERGUNTAR "Adicionar referencia nestas iniciativas?"
  SE sim:
    PARA cada ini:
      ATUALIZAR ini.depende_de.adrs += [proximo_id]
```

### 10. Atualizar stack (se tecnologia)

```
# Verificar se ADR eh sobre tecnologia
SE keywords incluem tech conhecidas:
  PERGUNTAR "Atualizar [escopo]/stack.md?"
  SE sim:
    # Adicionar ou atualizar entrada no stack
    LER ./knowledge/[escopo]/stack.md (ou holding se for holding)
    ADICIONAR referencia a ADR
    SALVAR
```

## Output Esperado

```
+----------------------------------------------------+
| ADR CRIADA: [proximo_id]                           |
+----------------------------------------------------+
|                                                    |
| Arquivo: [path_adrs]/[proximo_id].md               |
|                                                    |
| DETALHES:                                          |
|   * Titulo: [titulo]                               |
|   * Status: proposta                               |
|   * Escopo: [escopo]                               |
|   * Empresas afetadas: [empresas]                  |
|                                                    |
| VERIFICACOES:                                      |
|   * ADRs similares: [nenhuma ou lista]             |
|   * Substitui: [nenhuma ou id]                     |
|                                                    |
| IMPACTO IDENTIFICADO:                              |
|   * Iniciativas: [lista ou "nenhuma identificada"] |
|                                                    |
| PROXIMOS PASSOS:                                   |
|   1. Revisar com stakeholders                      |
|   2. Atualizar status para "aceita" quando decidir |
|   3. Atualizar stack.md se aprovada (se tech)      |
|   4. Comunicar empresas afetadas                   |
|                                                    |
+----------------------------------------------------+
```

## Ciclo de Vida da ADR

```
proposta -> aceita -> (depreciada | substituida)
```

- **proposta**: Decisao em discussao, nao implementada
- **aceita**: Decisao tomada e em vigor
- **depreciada**: Decisao nao mais recomendada (mas nao substituida)
- **substituida**: Decisao substituida por outra ADR

## Arquivos Lidos

```
[path_adrs]/_index.md
[path_adrs]/[adr_existente].md (para verificar similares e substituicao)
./knowledge/[empresa]/iniciativas/_index.md (para impacto)
./knowledge/[escopo]/stack.md (se tecnologia)
```

## Arquivos Criados/Atualizados

```
[path_adrs]/[proximo_id].md (criado)
[path_adrs]/_index.md (atualizado)
[path_adrs]/[substitui].md (atualizado se substitui outra)
./knowledge/[empresa]/iniciativas/[id].md (se adicionar referencia)
./knowledge/[escopo]/stack.md (se atualizar stack)
```

## Validacoes

- Escopo deve ser valido
- Titulo eh obrigatorio
- Contexto eh obrigatorio
- Decisao eh obrigatoria
- Pelo menos 2 alternativas devem ser informadas
- Se substitui, a ADR antiga deve existir
- ID deve ser unico
