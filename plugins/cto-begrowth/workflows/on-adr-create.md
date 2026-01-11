---
name: on-adr-create
description: Hook específico para criação de ADR (Architecture Decision Record)
triggers:
  - /roadmap adr
events:
  - PreToolUse (before write)
  - PostToolUse (after write)
version: 1
---

# Hook: Criação de ADR

## Propósito

Verificar histórico de decisões, evitar conflitos com ADRs existentes, e identificar impactos em iniciativas e pessoas.

---

## Trigger

Este hook é acionado quando:
- `/roadmap adr [escopo]` é executado
- Arquivo de ADR é criado manualmente

**Nota:** Este hook trabalha em conjunto com `on-entity-create` para ADRs.

---

## Fluxo de Execução

### Fase 1: Verificar Histórico

```yaml
verificar_historico:
  # Buscar ADRs com keywords similares
  adrs_similares: []

  busca_por_keywords:
    PARA cada adr em [escopo]/adrs/:
      LER frontmatter (keywords, titulo, status)

      # Calcular similaridade
      similaridade = calcular_similaridade(
        nova_adr.keywords,
        adr.keywords
      )

      SE similaridade > 50%:
        adrs_similares.add({
          id: adr.id,
          titulo: adr.titulo,
          status: adr.status,
          similaridade: similaridade
        })

  # Alertar sobre similares
  SE adrs_similares.count > 0:
    PARA cada similar:
      SE similar.status == "aceita":
        ALERTA "⚠️ ADR similar ACEITA encontrada: [id]"
        INFO "Título: [titulo]"
        INFO "Similaridade: [percent]%"
        PERGUNTAR "Esta nova ADR substitui a anterior?"

      SE similar.status == "proposta":
        ALERTA "📋 ADR similar em PROPOSTA: [id]"
        INFO "Título: [titulo]"
        PERGUNTAR "Deve consolidar com a existente?"

  # Verificar substituição
  verificar_substituicao:
    SE nova_adr.substitui informado:
      LER adr_antiga = [escopo]/adrs/[substitui].md

      SE adr_antiga não existe:
        ERRO "ADR [substitui] não encontrada"
        BLOQUEAR

      SE adr_antiga.status != "aceita":
        ERRO "ADR [substitui] não está aceita (status: [status])"
        BLOQUEAR

      SE adr_antiga.status == "substituida":
        ALERTA "ADR [substitui] já foi substituída por [substituida_por]"
        PERGUNTAR "Confirma substituir mesmo assim?"

  # Listar decisões pendentes
  listar_pendentes:
    pendentes = []
    PARA cada adr em [escopo]/adrs/:
      SE adr.status == "proposta":
        pendentes.add(adr)

    SE pendentes.count > 0:
      INFO "📋 Decisões pendentes no momento:"
      PARA cada pendente:
        INFO "  - [id]: [titulo] (deadline: [deadline])"
```

### Fase 2: Verificar Conflitos

```yaml
verificar_conflitos:
  # Buscar possíveis conflitos com ADRs aceitas
  conflitos: []

  analise:
    PARA cada adr aceita em [escopo]/adrs/:
      SE areas_sobrepostas(nova_adr, adr):
        conflito = {
          id: adr.id,
          titulo: adr.titulo,
          area: [area de sobreposição],
          tipo: [compativel | incompativel | substitui]
        }
        conflitos.add(conflito)

  # Tipos de sobreposição
  areas_sobrepostas:
    - Mesma tecnologia (ex: dois DB diferentes)
    - Mesmo domínio técnico (ex: duas formas de autenticação)
    - Mesmas empresas afetadas com decisões opostas

  # Alertar sobre conflitos
  SE conflitos.count > 0:
    PARA cada conflito:
      SE conflito.tipo == "incompativel":
        ALERTA "🔴 CONFLITO com [id]: [titulo]"
        INFO "Área: [area]"
        ERRO "Decisões incompatíveis - resolver antes de prosseguir"
        BLOQUEAR

      SE conflito.tipo == "substitui":
        ALERTA "🟡 Nova decisão substitui [id]"
        INFO "Área: [area]"
        PERGUNTAR "Confirma que [id] será substituída?"
        SE confirma:
          nova_adr.substitui = conflito.id

      SE conflito.tipo == "compativel":
        INFO "ℹ️ Relacionada com [id]: [titulo]"
        INFO "Área: [area]"
        SUGERIR "Referenciar no campo 'relacionadas'"
```

### Fase 3: Identificar Impactos

```yaml
identificar_impactos:
  # Iniciativas afetadas
  iniciativas_afetadas: []

  busca_iniciativas:
    PARA cada empresa em empresas_afetadas:
      PARA cada iniciativa em [empresa]/iniciativas/:
        LER frontmatter (keywords, skills_necessarios, depende_de)

        SE keywords_match(iniciativa, nova_adr):
          iniciativas_afetadas.add({
            id: iniciativa.id,
            nome: iniciativa.nome,
            empresa: empresa,
            status: iniciativa.status,
            match_tipo: "keywords"
          })

        SE skill_match(iniciativa.skills, nova_adr.keywords):
          iniciativas_afetadas.add({
            id: iniciativa.id,
            nome: iniciativa.nome,
            empresa: empresa,
            status: iniciativa.status,
            match_tipo: "skills"
          })

  # Stack afetado
  stack_afetado:
    SE nova_adr envolve tecnologia:
      LER holding/stack.md
      LISTAR tecnologias relacionadas

      SE nova_adr.status == "proposta":
        SUGERIR "Adicionar à seção 'Em Avaliação' do stack.md"

      SE nova_adr.status == "aceita":
        SUGERIR "Atualizar stack.md com nova tecnologia"

  # Pessoas a comunicar
  pessoas_comunicar: []

  identificar_pessoas:
    # Owners de iniciativas afetadas
    PARA cada iniciativa em iniciativas_afetadas:
      SE iniciativa.owner:
        pessoas_comunicar.add({
          id: iniciativa.owner,
          motivo: "Owner de [iniciativa.id]"
        })

    # Decisores de ADRs anteriores na mesma área
    PARA cada adr_anterior com area similar:
      pessoas_comunicar.add({
        id: adr_anterior.decisor,
        motivo: "Decisor de [adr_anterior.id]"
      })

    # Especialistas no skill/tecnologia
    PARA cada pessoa com skill relevante:
      pessoas_comunicar.add({
        id: pessoa.id,
        motivo: "Especialista em [skill]"
      })
```

### Fase 4: Atualizar ADR Substituída

```yaml
atualizar_substituida:
  SE nova_adr.substitui informado:
    # Abrir ADR antiga
    LER adr_antiga = [escopo]/adrs/[substitui].md

    # Atualizar frontmatter
    adr_antiga.status = "substituida"
    adr_antiga.substituida_por = nova_adr.id
    adr_antiga.updated_at = data_atual

    # Adicionar nota no conteúdo
    adr_antiga.conteudo += |
      ---
      ## Substituição

      **Data:** [data_atual]
      **Substituída por:** [nova_adr.id] - [nova_adr.titulo]
      **Motivo:** [motivo da substituição]

    # Salvar
    SALVAR adr_antiga

    # Atualizar _index.md
    ATUALIZAR _index.md:
      entities[substitui].status = "substituida"
      by_status.aceita -= 1
      by_status.substituida += 1

  # Notificar sobre substituição
  SE substituicao realizada:
    ALERTA "ADR [substitui] marcada como substituída"
    INFO "Iniciativas que referenciavam: [lista]"
    SUGERIR "Atualizar referências nas iniciativas"
```

### Fase 5: Sugestões

```yaml
sugestoes:
  # Stack
  SE nova_adr envolve tecnologia:
    SE nova_adr.status == "aceita":
      SUGERIR "📦 Atualizar holding/stack.md"
      INFO "Adicionar [tecnologia] como homologada"

    SE nova_adr.status == "proposta":
      SUGERIR "📋 Adicionar a 'Em Avaliação' no stack.md"
      INFO "Definir deadline para decisão"

  # Comunicação
  SE pessoas_comunicar.count > 0:
    SUGERIR "📣 Comunicar decisão para:"
    PARA cada pessoa em pessoas_comunicar:
      INFO "  - [pessoa.id]: [pessoa.motivo]"

  # Revisão
  SE nova_adr.revisao_prevista não informada:
    SUGERIR "📅 Definir data de revisão"
    INFO "Recomendado: 6 meses para tecnologias"
    INFO "Recomendado: 12 meses para arquitetura"

  # Documentação
  SE nova_adr.alternativas.count < 2:
    SUGERIR "📝 Documentar mais alternativas consideradas"
    INFO "ADRs devem ter pelo menos 2-3 alternativas"

  # Iniciativas
  SE iniciativas_afetadas.count > 0:
    SUGERIR "🔗 Atualizar iniciativas afetadas:"
    PARA cada iniciativa:
      INFO "  - [id]: adicionar ADR em depende_de.adrs"
```

---

## Output do Hook

```yaml
hook_output:
  status: "success" | "blocked" | "warning"

  adr_criada:
    id: "BG-ADR-004"
    titulo: "Vector DB para RAG"
    status: "proposta"
    escopo: "holding"
    file: "knowledge/holding/adrs/BG-ADR-004.md"

  verificacoes:
    similares:
      - id: "BG-ADR-001"
        titulo: "BigQuery como Warehouse"
        similaridade: 35
        acao: "Referenciar"
    conflitos: []
    substituida:
      id: null
      acao: null

  impactos:
    iniciativas_afetadas:
      - id: "UTUA-003"
        nome: "Chatbot de Atendimento"
        empresa: "utua"
        match: "keywords"
      - id: "ONE-CONTROL-002"
        nome: "Segmentação por Comportamento"
        empresa: "one-control"
        match: "skills"

    stack:
      atualizar: true
      secao: "Em Avaliação"
      tecnologia: "Pinecone"

    pessoas_comunicar:
      - id: "rodrigo-missagia"
        motivo: "CTO - decisor principal"
      - id: "joao-silva"
        motivo: "Owner de UTUA-003"

  sugestoes:
    - "Definir deadline para decisão (recomendado: 30 dias)"
    - "Comunicar owners das iniciativas afetadas"
    - "Avaliar alternativas: Pinecone, Weaviate, Qdrant"
    - "Agendar PoC antes de aceitar"

  arquivos_atualizados:
    - "knowledge/holding/adrs/BG-ADR-004.md"
    - "knowledge/holding/adrs/_index.md"
```

---

## Exemplo de Execução

```
ENTRADA: /roadmap adr holding
  titulo: "Vector DB para RAG"
  contexto: "Precisamos de banco vetorial para embeddings"
  alternativas: [Pinecone, Weaviate, Qdrant]
  decisao: "Proposta: Pinecone"
  keywords: [vector, embeddings, rag, ai, pinecone]

FASE 1 - HISTÓRICO:
  🔍 Buscando ADRs similares...
  ℹ️ ADR relacionada: BG-ADR-001 (BigQuery) - 25% similar
     → Área: dados, mas propósito diferente

  📋 Decisões pendentes:
     → BG-ADR-003: Definição de CDN (deadline: 2025-01-31)

FASE 2 - CONFLITOS:
  ✓ Nenhum conflito identificado
  ℹ️ Nova área de decisão (vector databases)

FASE 3 - IMPACTOS:
  📊 Iniciativas afetadas:
     - UTUA-003: Chatbot de Atendimento (keywords: ai, rag)
     - ONE-CONTROL-002: Segmentação (keywords: embeddings)
     - RESOLVE-003: Análise de Documentos (keywords: rag)

  👥 Pessoas a comunicar:
     - rodrigo-missagia (CTO)
     - joao-silva (Owner UTUA-003)
     - carlos-tech (Owner ONE-CONTROL-002)

FASE 4 - SUBSTITUIÇÃO:
  → Não substitui ADR anterior (nova área)

FASE 5 - SUGESTÕES:
  📦 Adicionar Pinecone a "Em Avaliação" no stack.md
  📅 Definir deadline: sugestão 2025-02-15
  📣 Agendar reunião com stakeholders
  🧪 Realizar PoC antes de aceitar

OUTPUT:
  status: success
  adr_criada:
    id: BG-ADR-004
    status: proposta
  proximos_passos:
    - Adicionar ao stack.md
    - Comunicar stakeholders
    - Agendar PoC
    - Definir deadline
```

---

## Fluxo de Estados de ADR

```
         ┌──────────┐
         │ proposta │
         └────┬─────┘
              │
     ┌────────┴────────┐
     ▼                 ▼
┌─────────┐      ┌───────────┐
│  aceita │      │ rejeitada │
└────┬────┘      └───────────┘
     │
     ▼
┌────────────┐     ┌────────────┐
│ substituida│ ◄── │ nova ADR   │
└────────────┘     └────────────┘
```

---

## Integração com Outros Hooks

| Hook | Integração |
|------|------------|
| `on-entity-create` | Chamado primeiro para validações básicas |
| `on-gap-identified` | Se ADR identifica gap de skill |
| `on-index-update` | Atualiza _index.md após criação |

---

## Campos Obrigatórios vs Opcionais

| Campo | Obrigatório | Validação |
|-------|-------------|-----------|
| titulo | ✅ | min 10 caracteres |
| contexto | ✅ | min 50 caracteres |
| decisao | ✅ | deve ser claro |
| alternativas | ✅ | min 2 alternativas |
| status | ✅ | proposta/aceita |
| decisor | ✅ | deve existir em pessoas/ |
| empresas_afetadas | ✅ | min 1 empresa |
| keywords | ⚠️ | recomendado 3-5 |
| revisao_prevista | ⚠️ | recomendado |
| consequencias | ⚠️ | recomendado |
