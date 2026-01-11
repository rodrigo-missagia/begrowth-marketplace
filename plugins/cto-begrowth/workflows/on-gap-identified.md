---
name: on-gap-identified
description: Hook quando gap de skill é identificado
triggers:
  - Criação de iniciativa com skill não coberto
  - Remoção de pessoa com skill único
  - /people gap [skill]
  - Análise de sinergias identifica necessidade
events:
  - PostToolUse (after gap detection)
version: 1
---

# Hook: Gap Identificado

## Propósito

Registrar gaps de capacidade, avaliar impacto nas iniciativas e sugerir opções de resolução.

---

## Triggers

Este hook é acionado quando:

| Situação | Trigger |
|----------|---------|
| Criação de iniciativa | Skill em `skills_necessarios` não existe em nenhuma pessoa |
| Remoção de pessoa | Pessoa removida era única com determinado skill |
| Comando explícito | `/people gap [skill]` |
| Análise de sinergias | Sinergia requer skill não disponível |
| Atribuição de pessoa | Skill match < 50% |

---

## Tipos de Gap

```yaml
tipos_gap:
  skill_ausente:
    descricao: "Ninguém no escopo possui o skill"
    urgencia_base: alta
    exemplo: "Nenhuma pessoa com skill 'temporal'"

  skill_sem_backup:
    descricao: "Apenas 1 pessoa possui o skill"
    urgencia_base: media
    exemplo: "Apenas joao-silva conhece BigQuery avançado"

  skill_na_empresa_errada:
    descricao: "Skill existe mas não onde é necessário"
    urgencia_base: baixa
    exemplo: "Skill 'grafana' existe na ASSINY, mas UTUA precisa"

  skill_nivel_insuficiente:
    descricao: "Pessoas têm skill mas em nível menor que necessário"
    urgencia_base: media
    exemplo: "Precisamos senior, temos apenas junior"
```

---

## Fluxo de Execução

### Fase 1: Identificar Gap

```yaml
identificar_gap:
  # Coletar informações do gap
  gap_info:
    skill: [nome do skill]
    escopo: [empresa ou holding]
    origem: [como foi identificado]
    nivel_necessario: [junior | pleno | senior | especialista]

  # Classificar tipo
  classificar:
    # Buscar pessoas com o skill
    pessoas_com_skill = buscar_pessoas_skill(skill, escopo)

    SE pessoas_com_skill.count == 0:
      tipo = "skill_ausente"

    SE pessoas_com_skill.count == 1:
      tipo = "skill_sem_backup"

    SE pessoas_com_skill.count > 0 AND escopo_diferente:
      tipo = "skill_na_empresa_errada"

    SE pessoas_com_skill.max_nivel < nivel_necessario:
      tipo = "skill_nivel_insuficiente"

  # Determinar contexto
  contexto:
    iniciativa_origem: [se veio de criação de iniciativa]
    comando_origem: [se veio de comando /people gap]
    pessoa_removida: [se veio de remoção]
```

### Fase 2: Registrar Gap

```yaml
registrar_gap:
  # Atualizar _index.md de pessoas do escopo afetado
  PARA cada escopo_afetado:
    LER [escopo]/pessoas/_index.md

    # Verificar se já existe
    SE skill em skills_sem_backup:
      # Já registrado, atualizar severidade se necessário
      ATUALIZAR severidade se piorou

    SENAO:
      # Novo gap
      SE tipo == "skill_ausente":
        ADICIONAR skill em gaps[]:
          skill: [skill]
          tipo: "ausente"
          identificado_em: data_atual
          iniciativas_afetadas: []

      SE tipo == "skill_sem_backup":
        ADICIONAR skill em skills_sem_backup

    # Adicionar alerta
    alerts.add("Gap: [skill] ([tipo])")

    # Recalcular health
    health = recalcular_health(alerts)

    # Atualizar timestamp
    updated_at = data_atual

    SALVAR _index.md
```

### Fase 3: Avaliar Impacto

```yaml
avaliar_impacto:
  # Buscar iniciativas que precisam do skill
  iniciativas_afetadas: []

  busca:
    PARA cada empresa:
      PARA cada iniciativa em [empresa]/iniciativas/:
        LER frontmatter (skills_necessarios, status)

        SE skill em skills_necessarios:
          iniciativas_afetadas.add({
            id: iniciativa.id,
            nome: iniciativa.nome,
            empresa: empresa,
            status: iniciativa.status,
            owner: iniciativa.owner,
            outros_gaps: contar_outros_gaps(iniciativa)
          })

  # Classificar urgência baseado no impacto
  classificar_urgencia:
    contagem = iniciativas_afetadas.count
    tem_em_andamento = iniciativas_afetadas.any(status == "em_andamento")
    todas_backlog = iniciativas_afetadas.all(status == "backlog")

    SE tem_em_andamento:
      urgencia = "critica"
      motivo = "Iniciativa em andamento bloqueada"

    SE contagem >= 5:
      urgencia = "critica"
      motivo = "[contagem] iniciativas afetadas"

    SE contagem >= 3:
      urgencia = "alta"
      motivo = "[contagem] iniciativas afetadas"

    SE contagem >= 1 AND NOT todas_backlog:
      urgencia = "alta"
      motivo = "Iniciativas não são apenas backlog"

    SE todas_backlog:
      urgencia = "media"
      motivo = "Apenas iniciativas em backlog"

    SE contagem == 0:
      urgencia = "baixa"
      motivo = "Nenhuma iniciativa afetada atualmente"

  # Calcular custo do gap
  custo_gap:
    iniciativas_bloqueadas: count(status != "backlog")
    valor_potencial: estimar_valor(iniciativas_afetadas)
    tempo_bloqueio: estimar_tempo_resolucao(tipo)
```

### Fase 4: Sugerir Opções

```yaml
sugerir_opcoes:
  opcoes: []

  # Opção 1: Treinar pessoa existente
  candidatos_treinar:
    # Buscar pessoas com skills próximos
    skills_proximos = buscar_skills_relacionados(skill)

    PARA cada pessoa no escopo:
      pessoa_skills = pessoa.skills[].nome
      match = intersecao(pessoa_skills, skills_proximos)

      SE match.count > 0:
        candidatos.add({
          pessoa: pessoa.id,
          skills_base: match,
          esforco_estimado: calcular_esforco(skill, match),
          disponibilidade: verificar_carga(pessoa)
        })

    SE candidatos.count > 0:
      opcoes.add({
        tipo: "treinar",
        candidatos: ordenar_por_esforco(candidatos),
        pros: ["Mantém conhecimento interno", "Menor custo", "Engaja equipe"],
        contras: ["Tempo para proficiência", "Reduz capacidade durante treino"],
        tempo_estimado: "[baseado em esforço]",
        custo: "baixo"
      })

  # Opção 2: Contratar
  contratar:
    perfil = gerar_perfil(skill)

    opcoes.add({
      tipo: "contratar",
      perfil: {
        skill_principal: skill,
        nivel_minimo: nivel_necessario,
        skills_complementares: skills_relacionados,
        urgencia: urgencia
      },
      pros: ["Expertise imediata", "Capacidade adicional"],
      contras: ["Custo alto", "Tempo de contratação", "Risco de fit"],
      tempo_estimado: "30-60 dias (processo seletivo)",
      custo: "alto"
    })

  # Opção 3: Terceirizar
  terceirizar:
    escopo_terceirizavel = definir_escopo(iniciativas_afetadas)

    opcoes.add({
      tipo: "terceirizar",
      escopo: escopo_terceirizavel,
      pros: ["Velocidade", "Sem compromisso longo prazo"],
      contras: ["Custo por projeto", "Menos controle", "Dependência"],
      tempo_estimado: "7-14 dias (contratar fornecedor)",
      custo: "medio-alto"
    })

  # Opção 4: Realocar de outra empresa
  SE tipo == "skill_na_empresa_errada":
    pessoa_outra_empresa = buscar_pessoa_com_skill_outra_empresa(skill)

    SE pessoa_outra_empresa:
      opcoes.add({
        tipo: "realocar",
        pessoa: pessoa_outra_empresa.id,
        empresa_origem: pessoa_outra_empresa.empresa,
        pros: ["Já conhece grupo", "Transferência de conhecimento"],
        contras: ["Impacto na empresa origem", "Adaptação"],
        tempo_estimado: "imediato",
        custo: "baixo"
      })

  # Opção 5: Despriorizar iniciativas
  SE iniciativas podem esperar:
    iniciativas_despriorizaveis = filtrar_despriorizaveis(iniciativas_afetadas)

    SE iniciativas_despriorizaveis.count > 0:
      opcoes.add({
        tipo: "despriorizar",
        iniciativas: iniciativas_despriorizaveis,
        pros: ["Sem custo imediato", "Foco em outras prioridades"],
        contras: ["Atraso em entrega", "Pode desmotivar"],
        tempo_estimado: "imediato",
        custo: "zero"
      })

  # Ordenar por recomendação
  ordenar_opcoes:
    SE urgencia == "critica":
      priorizar: [terceirizar, contratar, realocar]
    SE urgencia == "alta":
      priorizar: [treinar, contratar, terceirizar]
    SE urgencia == "media":
      priorizar: [treinar, realocar, despriorizar]
    SE urgencia == "baixa":
      priorizar: [treinar, despriorizar]
```

---

## Output do Hook

```yaml
hook_output:
  status: "gap_registered"

  gap:
    skill: "temporal"
    tipo: "skill_ausente"
    urgencia: "alta"
    escopo: "assiny"
    identificado_em: "2025-01-10"
    origem: "Criação de ASSINY-003"

  impacto:
    iniciativas_afetadas:
      - id: "ASSINY-003"
        nome: "Orquestração de Pagamentos"
        status: "backlog"
        bloqueada: true
      - id: "ONE-CONTROL-002"
        nome: "Workflows de Engajamento"
        status: "backlog"
        bloqueada: true
      - id: "ASSINY-005"
        nome: "Retry de Transações"
        status: "backlog"
        bloqueada: true

    total_afetadas: 3
    em_andamento_bloqueadas: 0
    custo_estimado: "3 iniciativas atrasadas"

  registros_atualizados:
    - "knowledge/assiny/pessoas/_index.md"
    - "knowledge/one-control/pessoas/_index.md"

  opcoes_sugeridas:
    - tipo: "treinar"
      candidato: "joao-silva"
      base: "Conhece orquestração com Airflow"
      esforco: "2-3 semanas de estudo"
      recomendado: true

    - tipo: "contratar"
      perfil: "Dev Sr com Temporal.io"
      urgencia: "alta"
      tempo: "30-60 dias"

    - tipo: "terceirizar"
      escopo: "Implementação inicial ASSINY-003"
      tempo: "14 dias"

  recomendacao:
    opcao: "treinar"
    motivo: "Custo-benefício para urgência alta (não crítica)"
    candidato: "joao-silva"
    plano: "Curso oficial Temporal + PoC em ASSINY-003"
```

---

## Exemplo de Execução

```
TRIGGER: Criação de ASSINY-003
  skills_necessarios: [python, temporal, bigquery]

FASE 1 - IDENTIFICAÇÃO:
  🔍 Verificando skills...
  ✓ python: coberto (3 pessoas)
  ✓ bigquery: coberto (2 pessoas)
  ✗ temporal: NÃO COBERTO

  Gap identificado:
    skill: temporal
    tipo: skill_ausente
    escopo: assiny

FASE 2 - REGISTRO:
  ✓ Adicionado em assiny/pessoas/_index.md:
    - gaps[]: temporal (ausente)
    - alerts[]: "Gap: temporal"
    - health: atencao

  ✓ Verificando one-control (também usa temporal)...
  ✓ Adicionado em one-control/pessoas/_index.md

FASE 3 - IMPACTO:
  📊 Iniciativas afetadas: 3
    - ASSINY-003: Orquestração de Pagamentos
    - ONE-CONTROL-002: Workflows de Engajamento
    - ASSINY-005: Retry de Transações

  ⚠️ Urgência: ALTA
     Motivo: 3 iniciativas afetadas

FASE 4 - OPÇÕES:
  1️⃣ TREINAR (Recomendado)
     Candidato: joao-silva
     Base: Conhece Airflow (orquestração similar)
     Esforço: 2-3 semanas
     Custo: Baixo

  2️⃣ CONTRATAR
     Perfil: Dev Sr Temporal.io
     Tempo: 30-60 dias
     Custo: Alto

  3️⃣ TERCEIRIZAR
     Escopo: Implementação ASSINY-003
     Tempo: 14 dias
     Custo: Médio-Alto

OUTPUT:
  status: gap_registered
  recomendacao: Treinar joao-silva
  proximos_passos:
    - Alinhar com joao-silva sobre interesse
    - Definir plano de estudo
    - Iniciar PoC em paralelo
```

---

## Skills Relacionados (para busca de candidatos)

```yaml
skills_relacionados:
  # Orquestração
  temporal:
    relacionados: [airflow, dagster, prefect, step_functions, conductor]
    base_necessaria: [python, async, distributed_systems]

  # Dados
  bigquery:
    relacionados: [sql, snowflake, redshift, databricks]
    base_necessaria: [sql, analytics]

  # ML/AI
  langchain:
    relacionados: [python, openai, embeddings, rag]
    base_necessaria: [python, ml_basics]

  # Frontend
  react:
    relacionados: [vue, angular, svelte, nextjs]
    base_necessaria: [javascript, html, css]
```

---

## Integração com Outros Hooks

| Hook | Quando aciona |
|------|---------------|
| `on-entity-create` | Cria iniciativa com skill não coberto |
| `on-pessoa-assign` | Skill match < 50% |
| `on-index-update` | Após registrar gap |

---

## Relatório de Gaps (agregado)

O hook também pode gerar relatório consolidado:

```yaml
relatorio_gaps:
  comando: /people gap all

  output:
    total_gaps: 4
    por_tipo:
      skill_ausente: 2
      skill_sem_backup: 2

    gaps:
      - skill: temporal
        tipo: ausente
        escopo: [assiny, one-control]
        iniciativas: 3
        urgencia: alta

      - skill: bigquery
        tipo: sem_backup
        escopo: holding
        pessoa_unica: rodrigo-missagia
        urgencia: critica

    recomendacoes_priorizadas:
      1: "Contratar Data Engineer (bigquery sem backup é crítico)"
      2: "Treinar joao-silva em Temporal"
```
