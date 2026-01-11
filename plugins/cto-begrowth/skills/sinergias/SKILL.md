---
name: sinergias
description: Use this skill to analyze synergy opportunities between Be Growth companies (UTUA, RESOLVE, ONE CONTROL, ASSINY). Triggers on phrases like "analise sinergia", "oportunidade entre empresas", "compartilhar componente", "replicar solucao", or when creating initiatives that could benefit multiple companies.
version: 1.0.0
---

# Skill: Analise de Sinergias

## Proposito

Identificar como uma iniciativa, tecnologia ou componente pode ser aproveitado por multiplas empresas do grupo Be Growth.

## Quando e Acionado

- Criacao de nova iniciativa (`/roadmap add`)
- Comando explicito (`/roadmap sinergia`)
- Avaliacao de tecnologia (`/inventario avaliar`)
- Criacao de ADR (`/roadmap adr`)

## Inputs Necessarios

```yaml
inputs:
  descricao:
    type: string
    required: true
    description: "Descricao da iniciativa/tecnologia"

  empresa_origem:
    type: string
    required: true
    description: "Empresa que esta desenvolvendo"

  keywords:
    type: array
    required: false
    description: "Palavras-chave para busca"

  skills_envolvidos:
    type: array
    required: false
    description: "Skills tecnicos envolvidos"
```

## Tipos de Sinergia

```yaml
tipos_sinergia:
  componente_tecnico:
    descricao: "Pode ser usado como biblioteca/servico"
    exemplo: "SDK de pagamentos, engine de scoring"

  padrao_processo:
    descricao: "Pode ser replicado como padrao"
    exemplo: "Pipeline de CI/CD, processo de deploy"

  dados:
    descricao: "Pode compartilhar dados"
    exemplo: "Base de clientes unificada, data lake"

  conhecimento:
    descricao: "Pode compartilhar aprendizados"
    exemplo: "Playbooks, ADRs, documentacao"

  infra:
    descricao: "Pode compartilhar infraestrutura"
    exemplo: "Kubernetes cluster, CDN, monitoring"
```

## Processo de Analise

### Passo 1: Identificar Natureza do Item

```
ANALISAR descricao do item
CLASSIFICAR em um ou mais tipos_sinergia
IDENTIFICAR keywords e skills tecnicos
```

### Passo 2: Avaliar Aplicabilidade por Empresa

```
PARA cada empresa em [utua, resolve, one-control, assiny] - empresa_origem:

  # Ler contexto da empresa
  LER ./knowledge/[empresa]/contexto.md

  # Verificar alinhamento
  alinhamento = {
    pilares_match: [],      # Quais pilares se beneficiam
    dores_match: [],        # Quais dores resolve
    iniciativas_similares: [], # Ja tem algo parecido?
    skills_disponiveis: [], # Tem pessoas para usar?
    dependencias: []        # O que precisaria antes
  }

  # Classificar potencial
  SE alinhamento.pilares_match.count > 0:
    potencial = "alto"
  SE alinhamento.skills_disponiveis.count == 0:
    potencial = baixar_nivel(potencial)
```

### Passo 3: Definir o que Compartilhar vs Isolar

```yaml
analise_compartilhamento:
  compartilhar:
    - "O que e generico e resolve problema comum"
    - "Infraestrutura e tooling"
    - "Padroes e convencoes"
    - "Bibliotecas e SDKs"

  isolar:
    - "Regras de negocio especificas"
    - "Dados sensiveis"
    - "Customizacoes por contexto"
    - "SLAs diferentes"
```

### Passo 4: Gerar Recomendacao

```yaml
recomendacoes:
  COMPARTILHAR:
    criterio: "Core generico + adaptacoes por empresa"
    quando: "Problema e comum, solucao tecnica e similar"

  REPLICAR:
    criterio: "Padrao bom, mas implementacoes independentes"
    quando: "Problema similar, mas contextos muito diferentes"

  ISOLAR:
    criterio: "Especifico demais para compartilhar"
    quando: "Solucao atende apenas uma empresa"
```

## Perguntas Guia

```yaml
perguntas_guia:
  - "Qual o core que resolve problema comum?"
  - "O que e especifico de cada contexto de negocio?"
  - "Quem deveria desenvolver primeiro e por que?"
  - "Como evitar acoplamento excessivo?"
  - "Qual o custo de NAO compartilhar?"
  - "Qual o custo de compartilhar mal?"
```

## Output Esperado

```yaml
output:
  resumo:
    item: "[Nome do item analisado]"
    tipo: "[componente_tecnico|padrao_processo|dados|conhecimento|infra]"
    recomendacao: "[COMPARTILHAR|REPLICAR|ISOLAR] (detalhes)"

  por_empresa:
    [empresa]:
      papel: "[origem|beneficiaria]"
      potencial: "[alto|medio|baixo]"
      uso: "Descricao do uso potencial"
      compartilha: ["lista do que compartilhar"]
      adapta: ["lista do que adaptar"]
      isola: ["lista do que isolar"]
      depende_de: ["lista de dependencias"]

  compartilhar:
    - "Lista de componentes/padroes a compartilhar"

  isolar:
    - "Lista do que manter isolado por empresa"

  ordem_sugerida:
    1: {empresa: "[nome]", motivo: "[justificativa]"}
    2: {empresa: "[nome]", motivo: "[justificativa]"}
```

## Formato de Resposta

```
+----------------------------------------------------------+
| ANALISE DE SINERGIA: [Nome do Item]                      |
+----------------------------------------------------------+
| Tipo: [tipo]                                             |
| Origem: [empresa]                                        |
| Recomendacao: [COMPARTILHAR|REPLICAR|ISOLAR]            |
+----------------------------------------------------------+

POR EMPRESA:
+-----------+----------+--------------------------------+
| Empresa   | Potencial| Uso                            |
+-----------+----------+--------------------------------+
| [empresa] | [nivel]  | [descricao]                    |
+-----------+----------+--------------------------------+

O QUE COMPARTILHAR:
  * [item 1]
  * [item 2]

O QUE ISOLAR:
  * [item 1]
  * [item 2]

ORDEM SUGERIDA:
  1. [empresa] - [motivo]
  2. [empresa] - [motivo]

ALERTAS:
  * [alertas ou consideracoes importantes]
```

## Exemplo de Uso

```
Usuario: /roadmap sinergia "Sistema de Scoring"

Resposta:
+----------------------------------------------------------+
| ANALISE DE SINERGIA: Sistema de Scoring                  |
+----------------------------------------------------------+
| Tipo: componente_tecnico                                 |
| Origem: RESOLVE                                          |
| Recomendacao: COMPARTILHAR (parcialmente)               |
+----------------------------------------------------------+

POR EMPRESA:
+-----------+----------+--------------------------------+
| Empresa   | Potencial| Uso                            |
+-----------+----------+--------------------------------+
| RESOLVE   | origem   | Scoring de carteiras           |
| ASSINY    | alto     | Antifraude e aprovacao         |
| UTUA      | medio    | Qualificacao de leads          |
| ONE CTRL  | baixo    | Segmentacao por score          |
+-----------+----------+--------------------------------+

O QUE COMPARTILHAR:
  * Engine de ML (infra de treino e serving)
  * Pipeline de features (estrutura)
  * Padroes de monitoramento de modelo

O QUE ISOLAR:
  * Features especificas de cada dominio
  * Regras de negocio (thresholds, acoes)
  * Dados de treino (cada um com seus dados)

ORDEM SUGERIDA:
  1. RESOLVE - desenvolve caso primario
  2. ASSINY - maior sinergia tecnica
  3. UTUA - avaliar apos 1 e 2

ALERTAS:
  * ONE CONTROL: prioridade baixa, nao justifica integracao agora
```
