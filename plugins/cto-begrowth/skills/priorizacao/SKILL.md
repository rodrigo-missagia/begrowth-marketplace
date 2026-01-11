---
name: priorizacao
description: Use this skill to prioritize initiatives in the backlog using objective criteria (pillar alignment, critical pain resolution, enabling other initiatives, synergy, viability). Triggers on phrases like "priorizar backlog", "ordenar iniciativas", "o que fazer primeiro", "ranking de projetos", or when user asks about initiative priorities.
version: 1.0.0
---

# Skill: Priorizacao

## Proposito

Ordenar iniciativas do backlog usando criterios objetivos e contexto estrategico.

## Quando e Acionado

- Comando `/roadmap priorize`
- Pode ser chamado internamente por outros comandos

## Inputs Necessarios

```yaml
inputs:
  iniciativas:
    type: array
    required: true
    description: "Lista de iniciativas a priorizar"

  escopo:
    type: string
    required: true
    description: "Empresa ou 'all'"

  contexto:
    type: object
    required: true
    description: "Pilares e dores do contexto.md"
```

## Criterios de Priorizacao

```yaml
criterios:
  alinhamento_pilares:
    peso: 30
    descricao: "Quantos pilares estrategicos endereca"
    calculo: "(pilares_match / total_pilares) * peso"

  resolve_dor_critica:
    peso: 25
    descricao: "Resolve uma dor listada como critica"
    calculo: "dor_critica ? peso : 0"

  habilita_outras:
    peso: 15
    descricao: "Desbloqueia outras iniciativas"
    calculo: "(iniciativas_desbloqueadas.count / 5) * peso"

  sinergia_grupo:
    peso: 15
    descricao: "Beneficia mais de uma empresa"
    calculo: "(empresas_beneficiadas.count - 1) * (peso / 4)"

  viabilidade:
    peso: 15
    descricao: "Temos skills e capacidade para executar"
    calculo: |
      SE todos_skills_cobertos: peso
      SE alguns_gaps: peso * 0.5
      SE gaps_criticos: 0
```

## Processo de Analise

### Passo 1: Coletar Dados de Cada Iniciativa

```
PARA cada iniciativa:
  LER ./knowledge/[empresa]/iniciativas/[id].md

  EXTRAIR:
    - pilares (do frontmatter)
    - problema (mapear para dores do contexto.md)
    - skills_necessarios
    - depende_de
    - sinergia_potencial
```

### Passo 2: Carregar Contexto Estrategico

```
LER ./knowledge/[empresa]/contexto.md

EXTRAIR:
  - pilares (lista completa)
  - dores (com classificacao de criticidade)
  - metas (para validar alinhamento)
```

### Passo 3: Calcular Scores

```
PARA cada iniciativa:
  # Alinhamento com pilares (30 pontos)
  score_pilares = (pilares_match.count / pilares_total.count) * 30

  # Resolve dor critica (25 pontos)
  SE problema in dores_criticas:
    score_dor = 25
  SE NAO:
    score_dor = 0

  # Habilita outras iniciativas (15 pontos)
  iniciativas_dependentes = buscar_dependentes(iniciativa.id)
  score_habilita = min(iniciativas_dependentes.count / 5, 1) * 15

  # Sinergia com grupo (15 pontos)
  empresas_beneficiadas = calcular_sinergia(iniciativa)
  score_sinergia = (empresas_beneficiadas.count - 1) * (15 / 4)

  # Viabilidade (15 pontos)
  gaps = verificar_gaps(iniciativa.skills_necessarios)
  SE gaps.count == 0:
    score_viabilidade = 15
  SE gaps.some(g => g.criticidade == 'baixa'):
    score_viabilidade = 7.5
  SE gaps.some(g => g.criticidade == 'alta'):
    score_viabilidade = 0

  # Score total
  score_total = score_pilares + score_dor + score_habilita + score_sinergia + score_viabilidade
```

### Passo 4: Identificar Agrupamentos

```
# Iniciativas que podem rodar juntas
AGRUPAR iniciativas por:
  - skills_similares
  - owner_comum
  - dependencia_mutua

grupos = []
PARA cada par de iniciativas:
  SE tem_skills_em_comum(i1, i2) > 0.5:
    ADICIONAR ao mesmo grupo
  SE tem_owner_comum(i1, i2):
    ADICIONAR ao mesmo grupo
  SE depende_de(i1, i2) OR depende_de(i2, i1):
    ADICIONAR ao mesmo grupo
```

### Passo 5: Identificar Bloqueios

```
PARA cada iniciativa:
  bloqueios = []

  # Gap de skill
  gaps = verificar_gaps(iniciativa.skills_necessarios)
  PARA cada gap:
    bloqueios.add("Gap: " + gap.skill)

  # Sem owner
  SE iniciativa.owner == null:
    bloqueios.add("Sem owner definido")

  # Dependencia nao concluida
  PARA cada dep em iniciativa.depende_de:
    dep_iniciativa = buscar_iniciativa(dep)
    SE dep_iniciativa.status != "concluido":
      bloqueios.add("Depende de: " + dep)
```

## Output Esperado

```yaml
output:
  ranking:
    - posicao: 1
      id: "[ID]"
      nome: "[Nome]"
      score: 92
      breakdown:
        pilares: "25/30 (pilares matched)"
        dor_critica: "25/25 (dor resolvida)"
        habilita: "10/15 (iniciativas desbloqueadas)"
        sinergia: "15/15 (empresas beneficiadas)"
        viabilidade: "17/15 (status de skills)"
      bloqueios: []
      recomendacao: "[Prioridade maxima|Resolver gap antes|etc]"

  agrupamentos:
    - grupo: "[Nome do grupo]"
      iniciativas: ["ID1", "ID2"]
      motivo: "[Justificativa do agrupamento]"

  alertas:
    - "[Alerta 1]"
    - "[Alerta 2]"

  resumo:
    prontas_para_iniciar: 3
    bloqueadas: 2
    gaps_criticos: ["lista de skills"]
```

## Formato de Resposta

```
+----------------------------------------------------------+
| PRIORIZACAO DE INICIATIVAS - [ESCOPO]                    |
+----------------------------------------------------------+

RANKING:
+-----+------------+------------------------+-------+----------+
| #   | ID         | Nome                   | Score | Status   |
+-----+------------+------------------------+-------+----------+
| 1   | [ID]       | [Nome]                 | 92    | PRONTA   |
| 2   | [ID]       | [Nome]                 | 78    | GAP      |
| 3   | [ID]       | [Nome]                 | 65    | BLOCKED  |
+-----+------------+------------------------+-------+----------+

BREAKDOWN TOP 3:
1. [ID] - [Nome] (Score: 92)
   Pilares: 25/30 | Dor: 25/25 | Habilita: 10/15 | Sinergia: 15/15 | Viabilidade: 17/15
   Recomendacao: Prioridade maxima

2. [ID] - [Nome] (Score: 78)
   Pilares: 15/30 | Dor: 25/25 | Habilita: 0/15 | Sinergia: 8/15 | Viabilidade: 30/15
   Bloqueio: Gap data_engineering
   Recomendacao: Resolver gap antes

AGRUPAMENTOS:
  * Grupo "Automacao": [ID1, ID2] - Skills similares, podem rodar juntas
  * Grupo "Bloqueadas": [ID3, ID4] - Dependem de data_engineering

RESUMO:
  * Prontas para iniciar: 3
  * Bloqueadas: 2
  * Gaps criticos: [data_engineering]

ALERTAS:
  * [ID] sem owner definido
  * 2 iniciativas bloqueadas por mesmo gap
```

## Exemplo de Uso

```
Usuario: /roadmap priorize utua

Resposta:
+----------------------------------------------------------+
| PRIORIZACAO DE INICIATIVAS - UTUA                        |
+----------------------------------------------------------+

RANKING:
+-----+------------+------------------------+-------+----------+
| #   | ID         | Nome                   | Score | Status   |
+-----+------------+------------------------+-------+----------+
| 1   | UTUA-004   | Automacao de Bids      | 92    | PRONTA   |
| 2   | UTUA-002   | Tracking Unificado     | 78    | GAP      |
| 3   | UTUA-001   | Dashboard Perf         | 65    | PRONTA   |
+-----+------------+------------------------+-------+----------+

BREAKDOWN TOP 3:
1. UTUA-004 - Automacao de Bids (Score: 92)
   Pilares: 25/30 (automacao, qualidade)
   Dor: 25/25 (bids manuais)
   Habilita: 10/15 (UTUA-005)
   Sinergia: 15/15 (ONE CONTROL)
   Viabilidade: 17/15 (todos skills ok)
   Recomendacao: Prioridade maxima

2. UTUA-002 - Tracking Unificado (Score: 78)
   Pilares: 15/30 (qualidade)
   Dor: 25/25 (atribuicao)
   Habilita: 0/15
   Sinergia: 8/15 (ASSINY)
   Viabilidade: 30/15 (gap data_eng)
   Bloqueio: Gap data_engineering
   Recomendacao: Resolver gap antes

AGRUPAMENTOS:
  * Grupo "Automacao": [UTUA-004, UTUA-005] - Skills similares
  * Grupo "Bloqueadas por gap": [UTUA-002, RESOLVE-003] - Dependem de data_eng

RESUMO:
  * Prontas para iniciar: 3
  * Bloqueadas: 2
  * Gaps criticos: [data_engineering]

ALERTAS:
  * UTUA-004: Sem owner definido
  * UTUA-002: Gap de skill critico
  * 2 iniciativas bloqueadas por mesmo gap
```
