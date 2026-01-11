---
name: impacto
description: Use this skill to evaluate the impact of proposed changes across the Be Growth ecosystem - technology changes, ADR deprecation, person removal, stack modifications. Triggers on phrases like "qual o impacto", "o que afeta", "consequencias de mudar", "quem e afetado", "risco de alterar".
version: 1.0.0
---

# Skill: Analise de Impacto

## Proposito

Avaliar consequencias de uma mudanca proposta no ecossistema do grupo Be Growth.

## Quando e Acionado

- Comando `/roadmap impacto`
- Depreciar/substituir ADR
- Mudanca de tecnologia no stack
- Remocao de pessoa chave

## Tipos de Mudanca

```yaml
tipos_mudanca:
  tecnologia:
    descricao: "Mudar/adicionar/remover tecnologia"
    impactos: ["stack", "adrs", "iniciativas", "pessoas"]
    exemplos:
      - "Migrar de BigQuery para Snowflake"
      - "Adicionar Redis ao stack"
      - "Remover biblioteca legada"

  adr:
    descricao: "Criar/depreciar/substituir ADR"
    impactos: ["iniciativas", "stack", "outras_adrs"]
    exemplos:
      - "Depreciar ADR de autenticacao"
      - "Criar ADR de microservicos"

  pessoa:
    descricao: "Adicionar/remover/realocar pessoa"
    impactos: ["iniciativas", "gaps", "backup"]
    exemplos:
      - "Saida de tech lead"
      - "Transferencia entre empresas"

  iniciativa:
    descricao: "Mudanca significativa em iniciativa"
    impactos: ["dependentes", "sinergias", "pessoas"]
    exemplos:
      - "Cancelar iniciativa"
      - "Mudar escopo significativamente"

  estrutura:
    descricao: "Mudanca organizacional"
    impactos: ["todas_areas"]
    exemplos:
      - "Criar nova empresa"
      - "Fundir equipes"
```

## Niveis de Criticidade

```yaml
criticidade_levels:
  BAIXO:
    descricao: "Poucas dependencias, facil reverter"
    criterios:
      - "Afeta <= 1 empresa"
      - "Afeta <= 2 iniciativas"
      - "Tem alternativa clara"

  MEDIO:
    descricao: "Algumas dependencias, esforco moderado"
    criterios:
      - "Afeta 2-3 empresas"
      - "Afeta 3-5 iniciativas"
      - "Requer planejamento"

  ALTO:
    descricao: "Muitas dependencias, esforco significativo"
    criterios:
      - "Afeta >= 3 empresas"
      - "Afeta >= 5 iniciativas"
      - "Requer migracao"

  CRITICO:
    descricao: "Dependencias criticas, dificil reverter"
    criterios:
      - "Afeta todas empresas"
      - "Afeta iniciativas em producao"
      - "Sem alternativa clara"
```

## Processo de Analise

### Passo 1: Classificar Tipo de Mudanca

```
ANALISAR descricao da mudanca
IDENTIFICAR tipo_mudanca em [tecnologia, adr, pessoa, iniciativa, estrutura]
IDENTIFICAR escopo em [holding, empresa_especifica, todas]
```

### Passo 2: Mapear Dependencias Diretas

```yaml
dependencias:
  empresas: []
  iniciativas: []
  pessoas: []
  adrs: []
  documentos: []

# Para mudanca de TECNOLOGIA:
SE tipo == "tecnologia":
  # Buscar em stack
  LER ./knowledge/holding/stack.md
  EXTRAIR referencias a tecnologia

  # Buscar em iniciativas
  PARA cada empresa:
    LER ./knowledge/[empresa]/iniciativas/_index.md
    BUSCAR iniciativas com tecnologia em skills_necessarios

  # Buscar em pessoas
  PARA cada empresa:
    LER ./knowledge/[empresa]/pessoas/_index.md
    BUSCAR pessoas com tecnologia em skills

  # Buscar em ADRs
  PARA cada empresa:
    LER ./knowledge/[empresa]/adrs/_index.md
    BUSCAR adrs relacionadas

# Para mudanca de ADR:
SE tipo == "adr":
  LER ./knowledge/[escopo]/adrs/[adr].md
  EXTRAIR:
    - iniciativas que referenciam
    - outras ADRs relacionadas
    - stack afetado

# Para mudanca de PESSOA:
SE tipo == "pessoa":
  LER ./knowledge/[empresa]/pessoas/[pessoa].md
  EXTRAIR:
    - iniciativas como owner
    - iniciativas como contributor
    - skills unicos (gap potencial)
```

### Passo 3: Avaliar Criticidade

```
criticidade = calcular_criticidade({
  empresas_afetadas: dependencias.empresas.count,
  iniciativas_afetadas: dependencias.iniciativas.count,
  tem_alternativa: existe_alternativa(),
  reversibilidade: eh_reversivel(),
  custo_de_nao_fazer: avaliar_status_quo()
})

# Logica de calculo
score = 0
SE empresas_afetadas >= 4: score += 3
SE empresas_afetadas >= 2: score += 2
SE empresas_afetadas >= 1: score += 1

SE iniciativas_afetadas >= 5: score += 3
SE iniciativas_afetadas >= 3: score += 2
SE iniciativas_afetadas >= 1: score += 1

SE NOT tem_alternativa: score += 2
SE NOT reversibilidade: score += 2

# Classificar
SE score >= 8: criticidade = "CRITICO"
SE score >= 5: criticidade = "ALTO"
SE score >= 3: criticidade = "MEDIO"
SE score < 3: criticidade = "BAIXO"
```

### Passo 4: Identificar Riscos

```yaml
riscos_tecnicos:
  - trigger: "mudanca afeta integracoes"
    risco: "Quebra de integracoes"
    mitigacao: "Testes de integracao antes de deploy"

  - trigger: "mudanca remove skill"
    risco: "Perda de capacidade"
    mitigacao: "Documentar e treinar substituto"

  - trigger: "mudanca deprecia ferramenta em uso"
    risco: "Sistemas sem suporte"
    mitigacao: "Plano de migracao faseada"

riscos_processo:
  - trigger: "muitas iniciativas afetadas"
    risco: "Retrabalho significativo"
    mitigacao: "Priorizar por criticidade"

  - trigger: "dependencias nao mapeadas"
    risco: "Impactos desconhecidos"
    mitigacao: "Auditoria antes de executar"

riscos_pessoas:
  - trigger: "pessoa e unica com skill"
    risco: "Sem backup"
    mitigacao: "Documentar e treinar antes"

  - trigger: "pessoa e owner de muitas iniciativas"
    risco: "Sobrecarga ou abandono"
    mitigacao: "Redistribuir responsabilidades"
```

### Passo 5: Gerar Recomendacoes

```
recomendacoes = {
  obrigatorias: [],
  sugeridas: [],
  documentos_atualizar: []
}

SE criticidade >= "ALTO":
  recomendacoes.obrigatorias.add("Criar ADR documentando decisao")
  recomendacoes.obrigatorias.add("Comunicar a todos stakeholders")
  recomendacoes.obrigatorias.add("Planejar migracao faseada")

PARA cada risco:
  recomendacoes.sugeridas.add("Mitigacao: " + risco.mitigacao)

PARA cada documento afetado:
  recomendacoes.documentos_atualizar.add({
    arquivo: documento,
    acao: determinar_acao(documento, mudanca)
  })
```

## Output Esperado

```yaml
output:
  mudanca:
    descricao: "[Descricao da mudanca]"
    tipo: "[tecnologia|adr|pessoa|iniciativa|estrutura]"
    escopo: "[holding|empresa|todas]"

  criticidade: "[BAIXO|MEDIO|ALTO|CRITICO]"

  impacto:
    empresas:
      - empresa: "[nome]"
        papel: "[owner|afetada]"
        uso: "[como usa o item]"
        iniciativas_afetadas: "[count]"

    iniciativas:
      - id: "[ID]"
        impacto: "[descricao do impacto]"

    adrs:
      - id: "[ID]"
        acao: "[DEPRECIAR|ATUALIZAR|CRIAR]"

    pessoas:
      - id: "[pessoa-id]"
        papel: "[decisor|afetado|executor]"
        acao: "[o que fazer]"

    documentos:
      - "[lista de arquivos a atualizar]"

  riscos:
    - nivel: "[baixo|medio|alto]"
      descricao: "[descricao do risco]"
      mitigacao: "[como mitigar]"

  recomendacoes:
    obrigatorias:
      - "[acao obrigatoria]"
    sugeridas:
      - "[acao sugerida]"
    documentos_atualizar:
      - arquivo: "[path]"
        acao: "[o que fazer]"
```

## Formato de Resposta

```
+----------------------------------------------------------+
| ANALISE DE IMPACTO                                       |
+----------------------------------------------------------+
| Mudanca: [descricao]                                     |
| Tipo: [tipo]                                             |
| Escopo: [escopo]                                         |
| Criticidade: [BAIXO|MEDIO|ALTO|CRITICO]                 |
+----------------------------------------------------------+

EMPRESAS AFETADAS:
+-----------+----------+------------------------+-----------+
| Empresa   | Papel    | Uso                    | Iniciativ |
+-----------+----------+------------------------+-----------+
| [empresa] | owner    | [uso]                  | 3         |
| [empresa] | afetada  | [uso]                  | 2         |
+-----------+----------+------------------------+-----------+

INICIATIVAS AFETADAS:
+------------+------------------------+------------------------+
| ID         | Nome                   | Impacto                |
+------------+------------------------+------------------------+
| [ID]       | [Nome]                 | [impacto]              |
+------------+------------------------+------------------------+

ADRs:
  * [ADR-ID]: [ACAO] - [descricao]

PESSOAS:
  * [pessoa]: [papel] - [acao necessaria]

RISCOS:
  [ALTO] Retrabalho em X iniciativas
         Mitigacao: Migracao faseada por empresa

  [MEDIO] Curva de aprendizado
          Mitigacao: Treinamento antes de migrar

RECOMENDACOES:
  Obrigatorias:
    1. [acao]
    2. [acao]

  Sugeridas:
    * [acao]
    * [acao]

  Documentos a Atualizar:
    * [arquivo] - [acao]
    * [arquivo] - [acao]
```

## Exemplo de Uso

```
Usuario: /roadmap impacto "Migrar de BigQuery para Snowflake"

Resposta:
+----------------------------------------------------------+
| ANALISE DE IMPACTO                                       |
+----------------------------------------------------------+
| Mudanca: Migrar de BigQuery para Snowflake               |
| Tipo: tecnologia                                         |
| Escopo: holding (afeta todas)                            |
| Criticidade: ALTO                                        |
+----------------------------------------------------------+

EMPRESAS AFETADAS:
+-----------+----------+------------------------+-----------+
| Empresa   | Papel    | Uso                    | Iniciativ |
+-----------+----------+------------------------+-----------+
| holding   | owner    | decisao arquitetural   | -         |
| utua      | afetada  | dashboards             | 2         |
| resolve   | afetada  | ETL                    | 2         |
| one-ctrl  | afetada  | CDP                    | 3         |
| assiny    | afetada  | analytics              | 1         |
+-----------+----------+------------------------+-----------+
Total: 8 iniciativas afetadas

INICIATIVAS AFETADAS:
+---------------+------------------------+------------------------+
| ID            | Nome                   | Impacto                |
+---------------+------------------------+------------------------+
| UTUA-001      | Dashboard Performance  | Refatorar queries      |
| UTUA-002      | Tracking Unificado     | Migrar pipelines       |
| ONE-CTRL-001  | CDP Core               | Migrar data warehouse  |
| RESOLVE-002   | ETL Carteiras          | Reescrever ETL         |
+---------------+------------------------+------------------------+

ADRs:
  * BG-ADR-001: DEPRECIAR - Criar nova ADR para Snowflake

PESSOAS:
  * rodrigo-missagia: decisor original - Comunicar e validar
  * joao-silva: owner UTUA-001 - Replanejar iniciativa
  * maria-santos: owner ONE-CTRL-001 - Estimar retrabalho

RISCOS:
  [ALTO] Retrabalho em 8 iniciativas
         Mitigacao: Migracao faseada por empresa

  [ALTO] Curva de aprendizado
         Mitigacao: Treinamento antes de migrar

  [MEDIO] Custos de migracao
          Mitigacao: Orcamento dedicado

  [MEDIO] Downtime durante migracao
          Mitigacao: Dual-write durante transicao

RECOMENDACOES:
  Obrigatorias:
    1. Criar ADR documentando decisao e justificativa
    2. Comunicar a todos owners de iniciativas
    3. Planejar migracao por empresa

  Sugeridas:
    * Fazer POC antes de decidir
    * Definir timeline de transicao
    * Treinar time antes de migrar

  Documentos a Atualizar:
    * ./knowledge/holding/stack.md - Atualizar status BigQuery
    * ./knowledge/holding/adrs/BG-ADR-001.md - Marcar como substituida
    * Nova ADR - Criar com referencia a anterior
```
