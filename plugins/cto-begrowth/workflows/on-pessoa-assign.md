---
name: on-pessoa-assign
description: Hook para atribuição de pessoa a iniciativa
triggers:
  - /people assign [pessoa] [iniciativa]
  - /roadmap update [id] owner
  - /roadmap add (quando owner é definido)
events:
  - PreToolUse (before assign)
  - PostToolUse (after assign)
version: 1
---

# Hook: Atribuição de Pessoa

## Propósito

Verificar carga de trabalho, compatibilidade de skills, conflitos de alocação e atualizar todos os arquivos relacionados.

---

## Triggers

Este hook é acionado quando:

| Comando | Papel | Descrição |
|---------|-------|-----------|
| `/people assign [pessoa] [iniciativa]` | owner ou contributor | Atribuição direta |
| `/roadmap update [id] owner` | owner | Mudança de ownership |
| `/roadmap add` com owner | owner | Criação com owner definido |

---

## Fluxo de Execução

### Fase 1: Verificar Carga

```yaml
verificar_carga:
  # Ler dados da pessoa
  LER pessoa.md
  iniciativas_atuais = pessoa.iniciativas[]

  # Contar por papel
  como_owner = iniciativas_atuais.filter(papel == "owner").count
  como_contributor = iniciativas_atuais.filter(papel == "contributor").count
  total = como_owner + como_contributor

  # Limites por papel da pessoa
  limites:
    cto:
      max_owner: 0  # CTO não deve ser owner direto
      max_contributor: 5
      alerta_em: 3

    lider_tech:
      max_owner: 2
      max_contributor: 3
      alerta_em: 3

    lider_negocio:
      max_owner: 3
      max_contributor: 2
      alerta_em: 4

    dev_senior:
      max_owner: 2
      max_contributor: 4
      alerta_em: 4

    dev_pleno:
      max_owner: 1
      max_contributor: 3
      alerta_em: 3

    analista:
      max_owner: 2
      max_contributor: 3
      alerta_em: 4

  # Verificar limites
  verificacao:
    limite = limites[pessoa.papel]

    SE papel_atribuicao == "owner":
      SE como_owner >= limite.max_owner:
        ALERTA "🔴 Pessoa no limite de ownership ([como_owner]/[max])"
        PERGUNTAR "Confirma atribuição mesmo assim?"

      SE como_owner == limite.max_owner - 1:
        ALERTA "⚠️ Pessoa próxima do limite de ownership"

    SE total >= limite.alerta_em:
      ALERTA "⚠️ Pessoa com carga alta: [total] iniciativas"
      LISTAR iniciativas atuais:
        PARA cada iniciativa:
          INFO "  - [id] ([status]) como [papel]"
      PERGUNTAR "Confirma alocação mesmo assim?"

  # Verificar conflito de tempo
  verificar_conflito_tempo:
    PARA cada iniciativa_atual em iniciativas_atuais:
      SE iniciativa_atual.status == "em_andamento":
        SE timeline_overlap(iniciativa_atual, nova_iniciativa):
          ALERTA "⏰ Conflito de timeline com [iniciativa_atual.id]"
          INFO "  [iniciativa_atual.id]: [inicio] - [fim]"
          INFO "  [nova_iniciativa.id]: [inicio] - [fim]"
```

### Fase 2: Verificar Skill Match

```yaml
verificar_skill_match:
  # Ler skills necessários da iniciativa
  LER iniciativa.md
  skills_necessarios = iniciativa.skills_necessarios[]

  # Ler skills da pessoa
  skills_pessoa = pessoa.skills[]

  # Calcular match
  match_detalhado: []
  PARA cada skill_req em skills_necessarios:
    skill_pessoa = skills_pessoa.find(nome == skill_req)

    SE skill_pessoa existe:
      match_detalhado.add({
        skill: skill_req,
        status: "coberto",
        nivel_pessoa: skill_pessoa.nivel,
        nivel_necessario: inferir_nivel(skill_req, iniciativa)
      })
    SENAO:
      match_detalhado.add({
        skill: skill_req,
        status: "gap",
        nivel_pessoa: null,
        nivel_necessario: inferir_nivel(skill_req, iniciativa)
      })

  # Calcular percentual
  cobertos = match_detalhado.filter(status == "coberto").count
  total = skills_necessarios.count
  match_percent = (cobertos / total) * 100

  # Alertar baseado no match
  alertar:
    SE match_percent < 30%:
      ALERTA "🔴 Match de skills muito baixo: [percent]%"
      LISTAR skills faltantes
      PERGUNTAR "Pessoa terá que aprender. Confirma?"

    SE match_percent < 50%:
      ALERTA "⚠️ Match de skills baixo: [percent]%"
      LISTAR skills faltantes
      INFO "Pessoa precisará desenvolver: [lista]"
      PERGUNTAR "Confirma atribuição?"

    SE match_percent < 80%:
      INFO "ℹ️ Match de skills: [percent]%"
      INFO "Skills a desenvolver: [lista gaps]"

    SE match_percent >= 80%:
      INFO "✅ Bom match de skills: [percent]%"

  # Verificar nível
  verificar_nivel:
    PARA cada skill coberto:
      SE skill.nivel_pessoa < skill.nivel_necessario:
        ALERTA "⚠️ [skill]: pessoa é [nivel_pessoa], precisa [nivel_necessario]"
```

### Fase 3: Verificar Conflitos

```yaml
verificar_conflitos:
  # Cross-empresa
  verificar_cross_empresa:
    SE pessoa.empresa_base != iniciativa.empresa:
      INFO "ℹ️ Alocação cross-empresa"
      INFO "  Pessoa: [empresa_base]"
      INFO "  Iniciativa: [iniciativa.empresa]"
      PERGUNTAR "Confirma alocação cross-empresa?"

      # Verificar aprovação necessária
      SE requer_aprovacao_cross:
        ALERTA "Requer aprovação do líder de [empresa_base]"

  # Já é owner de outra
  verificar_ownership_multiplo:
    SE papel_atribuicao == "owner":
      outras_owner = pessoa.iniciativas.filter(papel == "owner")

      SE outras_owner.count > 0:
        INFO "ℹ️ Pessoa já é owner de:"
        PARA cada outra:
          INFO "  - [outra.id]: [outra.nome] ([outra.status])"

        SE outras_owner.any(status == "em_andamento"):
          ALERTA "⚠️ Pessoa já é owner de iniciativa em andamento"
          PERGUNTAR "Confirma múltiplo ownership?"

  # Conflito com papel
  verificar_papel:
    SE pessoa.papel == "cto" AND papel_atribuicao == "owner":
      ALERTA "⚠️ CTO não deve ser owner direto de iniciativas"
      SUGERIR "Considerar papel de 'sponsor' ao invés de owner"
      PERGUNTAR "Confirma mesmo assim?"

  # Dependência circular
  verificar_dependencia:
    SE pessoa em iniciativa.depende_de.pessoas:
      ALERTA "ℹ️ Iniciativa já depende desta pessoa"
      INFO "Pessoa é crítica para esta iniciativa"
```

### Fase 4: Atualizar Arquivos

```yaml
atualizar_arquivos:
  # 1. Se muda owner, atualizar pessoa anterior
  atualizar_owner_anterior:
    SE papel_atribuicao == "owner" AND iniciativa.owner != null:
      owner_anterior = iniciativa.owner

      SE owner_anterior != pessoa.id:
        LER owner_anterior.md

        # Remover iniciativa
        owner_anterior.iniciativas.remove(iniciativa.id)

        # Adicionar ao histórico (opcional)
        owner_anterior.historico.add({
          data: data_atual,
          tipo: "ownership_transferido",
          iniciativa: iniciativa.id,
          para: pessoa.id
        })

        SALVAR owner_anterior.md

        INFO "✓ [owner_anterior.id] removido como owner"

  # 2. Atualizar pessoa nova
  atualizar_pessoa:
    LER pessoa.md

    # Adicionar iniciativa
    pessoa.iniciativas.add({
      id: iniciativa.id,
      papel: papel_atribuicao,  # owner | contributor
      desde: data_atual
    })

    # Atualizar updated_at
    pessoa.updated_at = data_atual

    SALVAR pessoa.md

    INFO "✓ [pessoa.id] adicionado como [papel_atribuicao]"

  # 3. Atualizar iniciativa
  atualizar_iniciativa:
    LER iniciativa.md

    SE papel_atribuicao == "owner":
      iniciativa.owner = pessoa.id
    SENAO:
      SE pessoa.id não em iniciativa.contributors:
        iniciativa.contributors.add(pessoa.id)

    iniciativa.updated_at = data_atual

    # Adicionar ao histórico
    iniciativa.historico.add({
      data: data_atual,
      tipo: "atribuicao",
      pessoa: pessoa.id,
      papel: papel_atribuicao
    })

    SALVAR iniciativa.md

  # 4. Atualizar _index.md de iniciativas
  atualizar_index:
    LER [empresa]/iniciativas/_index.md

    # Encontrar entrada
    entry = entities.find(id == iniciativa.id)

    # Atualizar owner
    SE papel_atribuicao == "owner":
      entry.owner = pessoa.id

    # Remover de alerts se tinha "sem owner"
    SE tinha alerta "sem owner":
      alerts.remove("[iniciativa.id]: sem owner")
      recalcular_health()

    updated_at = data_atual

    SALVAR _index.md
```

---

## Output do Hook

```yaml
hook_output:
  status: "success" | "warning" | "blocked"

  atribuicao:
    pessoa: "joao-silva"
    iniciativa: "UTUA-001"
    papel: "owner"
    data: "2025-01-10"

  verificacoes:
    carga:
      status: "atencao" | "ok" | "critico"
      iniciativas_atuais: 3
      como_owner: 1
      como_contributor: 2
      alerta: "Pessoa em limite de carga"

    skill_match:
      status: "ok" | "atencao" | "critico"
      percentual: 85
      skills_cobertos: ["python", "bigquery", "google_ads"]
      skills_faltantes: ["looker"]
      niveis_insuficientes: []

    conflitos:
      cross_empresa: false
      multiplo_ownership: true
      cto_como_owner: false

  arquivos_atualizados:
    - "knowledge/utua/pessoas/joao-silva.md"
    - "knowledge/utua/iniciativas/UTUA-001.md"
    - "knowledge/utua/iniciativas/_index.md"

  owner_anterior:
    pessoa: "maria-santos"
    acao: "Removida de UTUA-001"
    arquivo: "knowledge/utua/pessoas/maria-santos.md"

  recomendacoes:
    - "Desenvolver skill looker (gap identificado)"
    - "Monitorar carga nas próximas semanas"
```

---

## Exemplo de Execução

```
ENTRADA: /people assign joao-silva UTUA-001 owner

FASE 1 - CARGA:
  📊 Situação atual de joao-silva:
     - ASSINY-001 como owner (em_andamento)
     - ONE-CONTROL-001 como contributor (em_andamento)
     - UTUA-003 como contributor (backlog)
     Total: 3 iniciativas

  ⚠️ ALERTA: Pessoa próxima do limite
     Papel: lider_tech
     Limite owner: 2 (atual: 1 → será 2)
     Limite total: 5 (atual: 3 → será 4)

  ? Confirma atribuição? [S/n]

FASE 2 - SKILL MATCH:
  🎯 Skills necessários para UTUA-001:
     - python: ✅ senior (pessoa tem senior)
     - bigquery: ✅ pleno (pessoa tem pleno)
     - looker: ❌ não tem
     - google_ads: ✅ senior (pessoa tem senior)

  ℹ️ Match: 75%
  📝 Skills a desenvolver: looker

FASE 3 - CONFLITOS:
  ✅ Mesma empresa (utua)
  ⚠️ Será owner de 2 iniciativas:
     - ASSINY-001 (em_andamento)
     - UTUA-001 (será nova)

  ? Confirma múltiplo ownership? [S/n]

FASE 4 - ATUALIZAÇÕES:
  👤 Owner anterior: maria-santos
     ✓ Removida de UTUA-001
     ✓ Arquivo atualizado

  👤 Novo owner: joao-silva
     ✓ Adicionado como owner
     ✓ Arquivo atualizado

  📄 Iniciativa UTUA-001:
     ✓ owner: joao-silva
     ✓ Histórico atualizado

  📋 _index.md:
     ✓ Entry atualizada
     ✓ Alerta "sem owner" removido

OUTPUT:
  status: success (com warnings)
  atribuicao:
    pessoa: joao-silva
    iniciativa: UTUA-001
    papel: owner
  warnings:
    - "Carga próxima do limite"
    - "Gap de skill: looker"
  recomendacoes:
    - "Desenvolver looker em 2-3 semanas"
    - "Monitorar carga do joao-silva"
```

---

## Matriz de Limites por Papel

| Papel | Max Owner | Max Contributor | Max Total | Alerta Em |
|-------|-----------|-----------------|-----------|-----------|
| cto | 0 | 5 | 5 | 3 |
| lider_tech | 2 | 3 | 5 | 3 |
| lider_negocio | 3 | 2 | 5 | 4 |
| dev_senior | 2 | 4 | 6 | 4 |
| dev_pleno | 1 | 3 | 4 | 3 |
| analista | 2 | 3 | 5 | 4 |
| pmo | 5 | 2 | 7 | 5 |

---

## Integração com Outros Hooks

| Hook | Quando aciona |
|------|---------------|
| `on-entity-create` | Se criar iniciativa com owner |
| `on-gap-identified` | Se skill match < 50% |
| `on-index-update` | Após atualizar |

---

## Casos Especiais

### Transferência de Ownership

```yaml
transferencia:
  trigger: "/roadmap update UTUA-001 owner novo-owner"

  fluxo:
    - Executar hook para novo owner
    - Remover owner anterior
    - Manter contributors

  notificacoes:
    - Notificar owner anterior
    - Notificar contributors
    - Registrar no histórico
```

### Remoção de Atribuição

```yaml
remocao:
  trigger: "/people unassign joao-silva UTUA-001"

  verificacoes:
    - SE é owner e não há substituto: BLOQUEAR
    - SE é único contributor: ALERTA

  atualizacoes:
    - Remover de pessoa.iniciativas[]
    - Remover de iniciativa.owner ou contributors[]
    - Atualizar _index.md
```

### Atribuição em Lote

```yaml
lote:
  trigger: "/people assign joao-silva UTUA-001,UTUA-002,UTUA-003"

  fluxo:
    - Verificar carga para TODAS as iniciativas
    - Alertar se ultrapassar limite total
    - Processar uma a uma
    - Resumo consolidado no final
```
