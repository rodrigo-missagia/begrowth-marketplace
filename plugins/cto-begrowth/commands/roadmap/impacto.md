---
command: "roadmap impacto $descricao"
description: Analisa impacto de uma mudanca proposta no ecossistema. Usa skill de impacto.
args:
  descricao:
    description: "Descricao da mudanca (ex: 'migrar de BigQuery para Snowflake')"
    required: true
---

# /roadmap impacto

Analisa o impacto de uma mudanca proposta no ecossistema do grupo, identificando afetados e riscos.

## Uso

```
/roadmap impacto [descricao]
```

**Exemplos:**
- `/roadmap impacto "migrar de BigQuery para Snowflake"`
- `/roadmap impacto "trocar owner do UTUA-001"`
- `/roadmap impacto "depreciar BG-ADR-001"`
- `/roadmap impacto "contratar especialista em ML"`
- `/roadmap impacto "cancelar RESOLVE-003"`

## Fluxo de Execucao

### 1. Identificar tipo de mudanca

```
tipos = {
  "adr": ["depreciar", "substituir", "nova adr", "ADR"],
  "tecnologia": ["migrar", "trocar", "adotar", "remover", "tech"],
  "pessoa": ["owner", "contratar", "desligar", "transferir"],
  "iniciativa": ["cancelar", "pausar", "priorizar", "UTUA-", "RESOLVE-", "ONE-", "ASSINY-"],
  "processo": ["mudar fluxo", "novo processo", "automatizar"]
}

tipo = identificar_tipo(descricao, tipos)

# Extrair entidade especifica se mencionada
entidade = extrair_entidade(descricao)
# Ex: "BG-ADR-001", "UTUA-001", "joao-silva", "BigQuery"
```

### 2. Coletar dados do ecossistema

```
# Stack tecnologico
LER ./knowledge/holding/stack.md
EXTRAIR: tecnologias[], padroes[]

# ADRs
LER ./knowledge/holding/adrs/_index.md
PARA cada empresa:
  LER ./knowledge/[empresa]/adrs/_index.md (se existir)

# Iniciativas
PARA cada empresa:
  LER ./knowledge/[empresa]/iniciativas/_index.md

# Pessoas
PARA cada empresa:
  LER ./knowledge/[empresa]/pessoas/_index.md
```

### 3. Buscar dependencias e afetados

```
afetados = {
  empresas: [],
  iniciativas: [],
  adrs: [],
  pessoas: [],
  documentos: []
}

# Logica por tipo de mudanca:

SE tipo == "tecnologia":
  # Buscar onde a tech eh usada
  PARA cada empresa:
    LER contexto.md e stack.md
    SE tech mencionada:
      afetados.empresas.append(empresa)

    PARA cada iniciativa:
      SE tech em skills_necessarios OU keywords:
        afetados.iniciativas.append(iniciativa)

  PARA cada adr:
    SE tech em keywords:
      afetados.adrs.append(adr)

SE tipo == "adr":
  # Buscar onde a ADR eh referenciada
  LER arquivo da ADR
  afetados.empresas = adr.empresas_afetadas
  afetados.iniciativas = adr.iniciativas_relacionadas
  afetados.pessoas.append(adr.decisor)

SE tipo == "pessoa":
  # Buscar onde a pessoa eh referenciada
  LER arquivo da pessoa (se existir)
  afetados.iniciativas = pessoa.iniciativas
  afetados.empresas = [pessoa.scope]

  # Buscar iniciativas onde eh contributor
  PARA cada iniciativa:
    SE pessoa em contributors:
      afetados.iniciativas.append(iniciativa)

SE tipo == "iniciativa":
  # Buscar dependentes
  LER arquivo da iniciativa
  afetados.empresas = [iniciativa.scope]
  afetados.pessoas = [iniciativa.owner] + iniciativa.contributors
  afetados.adrs = iniciativa.depende_de.adrs

  # Iniciativas que dependem desta
  PARA cada outra_iniciativa:
    SE iniciativa.id em outra.depende_de.iniciativas:
      afetados.iniciativas.append(outra)
```

### 4. Avaliar nivel de impacto

```
# Calcular score de impacto
score = 0

score += len(afetados.empresas) * 20
score += len(afetados.iniciativas) * 10
score += len(afetados.adrs) * 15
score += len(afetados.pessoas) * 5

SE score >= 80:
  nivel = "ALTO"
  cor = "vermelho"
SENAO SE score >= 40:
  nivel = "MEDIO"
  cor = "amarelo"
SENAO:
  nivel = "BAIXO"
  cor = "verde"
```

### 5. Identificar riscos

```
riscos = []

# Riscos por tipo
SE tipo == "tecnologia":
  riscos.append({
    nivel: "alto",
    descricao: "Retrabalho em [n] iniciativas",
    mitigacao: "Planejar migracao gradual"
  })
  riscos.append({
    nivel: "alto",
    descricao: "Curva de aprendizado do time",
    mitigacao: "Investir em capacitacao"
  })
  riscos.append({
    nivel: "medio",
    descricao: "Custos de migracao",
    mitigacao: "Estimar custos antes de decidir"
  })

SE tipo == "pessoa":
  SE mudanca == "desligar" OU mudanca == "transferir":
    riscos.append({
      nivel: "alto",
      descricao: "Iniciativas sem owner",
      mitigacao: "Definir sucessor antes"
    })
    riscos.append({
      nivel: "medio",
      descricao: "Perda de conhecimento",
      mitigacao: "Documentar e fazer handoff"
    })

SE tipo == "iniciativa" E mudanca == "cancelar":
  riscos.append({
    nivel: "medio",
    descricao: "[n] iniciativas dependentes bloqueadas",
    mitigacao: "Avaliar alternativas ou cancelar dependentes"
  })
```

### 6. Listar documentos a atualizar

```
documentos = []

SE tipo == "tecnologia":
  documentos.append("./knowledge/holding/stack.md")
  SE adr_relacionada:
    documentos.append("ADR: depreciar ou substituir")
    documentos.append("Nova ADR para nova tech")
  PARA cada iniciativa afetada:
    documentos.append("./knowledge/[empresa]/iniciativas/[id].md")

SE tipo == "adr":
  documentos.append(adr_path)
  SE substitui_outra:
    documentos.append(adr_antiga_path)

SE tipo == "pessoa":
  documentos.append("./knowledge/[empresa]/pessoas/[pessoa].md")
  PARA cada iniciativa:
    documentos.append(iniciativa_path)
```

### 7. Gerar recomendacoes

```
recomendacoes = []

SE nivel == "ALTO":
  recomendacoes.append("Criar ADR documentando a decisao")
  recomendacoes.append("Planejar migracao por empresa")
  recomendacoes.append("Definir timeline de transicao")
  recomendacoes.append("Comunicar a todos stakeholders")
  recomendacoes.append("Revisar com CTOs das empresas afetadas")

SE nivel == "MEDIO":
  recomendacoes.append("Documentar decisao")
  recomendacoes.append("Comunicar afetados")
  recomendacoes.append("Definir plano de acao")

SE nivel == "BAIXO":
  recomendacoes.append("Prosseguir com a mudanca")
  recomendacoes.append("Atualizar documentos relacionados")
```

## Output Esperado

```
+----------------------------------------------------+
| ANALISE DE IMPACTO                                 |
| Mudanca: [descricao]                               |
+----------------------------------------------------+
|                                                    |
| [nivel_icon] IMPACTO: [ALTO/MEDIO/BAIXO]           |
|                                                    |
| EMPRESAS AFETADAS ([n])                            |
|   * holding - [motivo]                             |
|   * utua - [motivo]                                |
|   * resolve - [motivo]                             |
|   * [...]                                          |
|                                                    |
| INICIATIVAS AFETADAS ([n])                         |
|   * [ID]: [nome]                                   |
|   * [ID]: [nome]                                   |
|   * [...]                                          |
|                                                    |
| ADRs RELACIONADAS                                  |
|   * [ID]: [titulo]                                 |
|     -> [acao necessaria]                           |
|                                                    |
| PESSOAS QUE PRECISAM SABER                         |
|   * [pessoa] ([motivo])                            |
|   * [pessoa] ([motivo])                            |
|                                                    |
| DOCUMENTOS A ATUALIZAR                             |
|   * [caminho]                                      |
|   * [caminho]                                      |
|                                                    |
+----------------------------------------------------+
| RISCOS                                             |
|   [alto]  [descricao]                              |
|   [alto]  [descricao]                              |
|   [medio] [descricao]                              |
|   [baixo] [descricao]                              |
|                                                    |
+----------------------------------------------------+
| RECOMENDACAO                                       |
|                                                    |
| Antes de prosseguir:                               |
|   1. [acao]                                        |
|   2. [acao]                                        |
|   3. [acao]                                        |
|   4. [acao]                                        |
|                                                    |
+----------------------------------------------------+
```

## Perguntas Interativas (se necessario)

```
SE tipo nao identificado claramente:
  PERGUNTAR "Qual tipo de mudanca?"
  Opcoes: tecnologia, adr, pessoa, iniciativa, processo

SE entidade nao encontrada:
  PERGUNTAR "Especifique a entidade afetada:"
  Ex: ID da iniciativa, nome da tech, ID da pessoa

SE impacto alto:
  PERGUNTAR "Deseja criar ADR para documentar esta decisao? (/roadmap adr)"
```

## Arquivos Lidos

```
./knowledge/holding/stack.md
./knowledge/holding/adrs/_index.md
./knowledge/holding/adrs/[adr].md
./knowledge/[empresa]/contexto.md
./knowledge/[empresa]/iniciativas/_index.md
./knowledge/[empresa]/iniciativas/[id].md
./knowledge/[empresa]/pessoas/_index.md
./knowledge/[empresa]/pessoas/[id].md
./knowledge/[empresa]/adrs/_index.md
```

## Validacoes

- Descricao da mudanca deve ser informada
- Se mencionar entidade especifica, deve existir
