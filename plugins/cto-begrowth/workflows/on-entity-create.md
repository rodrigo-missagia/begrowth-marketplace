---
name: on-entity-create
description: Hook genérico para criação de entidades (pessoa, iniciativa, ADR)
triggers:
  - /people add
  - /roadmap add
  - /roadmap adr
events:
  - PreToolUse (before write)
  - PostToolUse (after write)
version: 1
---

# Hook: Criação de Entidade

## Propósito

Garantir consistência quando qualquer entidade (pessoa, iniciativa, ADR) é criada no sistema.

---

## Fluxo de Execução

### Fase PRE (antes de criar)

#### 1. Gerar ID

```yaml
gerar_id:
  pessoa:
    # Converter nome para slug
    # "João Silva" → "joao-silva"
    id: slug(nome)

  iniciativa:
    # Ler próximo ID do _index.md
    # "UTUA-005" → "UTUA-006"
    id: ler _index.md → next_id

  adr:
    # Ler próximo ID do _index.md
    # "BG-ADR-003" → "BG-ADR-004"
    id: ler _index.md → next_id
```

#### 2. Verificar Unicidade

```yaml
verificar_unicidade:
  passos:
    - LER _index.md do diretório correspondente
    - VERIFICAR se id existe em entities[].id

  se_existe:
    - BLOQUEAR criação
    - ERRO: "ID já existe: [id]"
    - SUGERIR: verificar se é atualização ou usar outro nome
```

#### 3. Validar Referências

```yaml
validar_referencias:
  pessoa:
    - SE reporta_a informado:
        VERIFICAR pessoa existe em pessoas/
        SE não existe: ERRO "Pessoa [reporta_a] não encontrada"

    - VALIDAR cada skill em skills[]:
        VERIFICAR skill existe em schemas/vocabulario.yaml
        SE não existe: ALERTA "Skill [nome] não está no vocabulário"

    - VALIDAR papel:
        VERIFICAR papel existe em vocabulario.papeis_pessoa
        SE não existe: ERRO "Papel inválido: [papel]"

  iniciativa:
    - SE owner informado:
        VERIFICAR pessoa existe em [empresa]/pessoas/ OU holding/pessoas/
        SE não existe: ERRO "Owner [id] não encontrado"

    - VALIDAR cada pilar em pilares[]:
        LER [empresa]/contexto.md
        VERIFICAR pilar existe nos pilares estratégicos
        SE não existe: ALERTA "Pilar [nome] não definido em contexto.md"

    - VALIDAR cada skill em skills_necessarios[]:
        VERIFICAR skill existe em schemas/vocabulario.yaml

  adr:
    - VERIFICAR decisor existe em pessoas/:
        BUSCAR em holding/pessoas/ e [empresa]/pessoas/
        SE não existe: ERRO "Decisor [id] não encontrado"

    - VALIDAR cada empresa em empresas_afetadas[]:
        VERIFICAR empresa está em [holding, utua, resolve, one-control, assiny]
        SE inválida: ERRO "Empresa inválida: [nome]"

    - SE substitui informado:
        VERIFICAR ADR existe e status == "aceita"
        SE não existe: ERRO "ADR [id] não encontrada"
        SE status != aceita: ERRO "ADR [id] não está aceita"
```

---

### Fase POST (depois de criar)

#### 1. Atualizar _index.md

```yaml
atualizar_index:
  operacoes:
    - ADICIONAR em entities[]:
        id: [id_gerado]
        file: [id_gerado].md
        # Campos específicos por tipo:
        pessoa:
          nome: [nome]
          papel: [papel]
        iniciativa:
          nome: [nome]
          status: [status]
          owner: [owner]
        adr:
          titulo: [titulo]
          status: [status]
          data: [data_criacao]

    - INCREMENTAR total: total + 1

    - ATUALIZAR contadores:
        pessoa: by_papel[papel] += 1
        iniciativa: by_status[status] += 1
        adr: by_status[status] += 1

    - ATUALIZAR next_id (iniciativa e adr):
        next_id = incrementar_id(id_gerado)

    - ATUALIZAR updated_at: data_atual
```

#### 2. Verificações Contextuais

```yaml
verificacoes_contextuais:
  pessoa:
    # Verificar se cobre algum gap
    - LER pessoas/_index.md → skills_sem_backup
    - PARA cada skill em pessoa.skills[]:
        SE skill em skills_sem_backup:
          INFO "Pessoa cobre gap de [skill]"
          ATUALIZAR skills_sem_backup (remover skill)
          ATUALIZAR skills_cobertos (adicionar skill)

  iniciativa:
    # Executar análise de sinergias
    - EXECUTAR skill sinergias com iniciativa
    - SE encontrar sinergias:
        INFO "Sinergia potencial com: [empresas]"
        ATUALIZAR iniciativa.sinergia_potencial[]

    # Verificar gaps de skills
    - PARA cada skill em skills_necessarios[]:
        LER pessoas/_index.md → skills_cobertos
        SE skill não em skills_cobertos:
          ALERTA "Gap identificado: [skill]"
          ADICIONAR em pessoas/_index.md → alerts[]
          TRIGGER on-gap-identified

  adr:
    # Atualizar ADR substituída
    - SE substitui informado:
        LER adr_antiga
        ATUALIZAR adr_antiga:
          status → "substituida"
          substituida_por → [novo_id]
        SALVAR adr_antiga

    # Buscar ADRs similares
    - PARA cada adr em [escopo]/adrs/:
        LER frontmatter (keywords)
        CALCULAR similaridade com nova_adr.keywords
        SE similaridade > 50%:
          INFO "ADR relacionada: [adr.id] - [adr.titulo]"

    # Identificar iniciativas afetadas
    - PARA cada empresa:
        PARA cada iniciativa:
          SE keywords_match(iniciativa, nova_adr):
            INFO "Iniciativa afetada: [id] - [nome]"
```

#### 3. Recalcular Health

```yaml
recalcular_health:
  passos:
    - CONTAR alerts[] no _index.md

    - DEFINIR health:
        SE alerts.count == 0:
          health = "ok"
        SE alerts contém palavra "crítico":
          health = "critico"
        SE alerts.count > 0:
          health = "atencao"

    - ATUALIZAR _index.md:
        health: [novo_health]
        health_reason: [motivo se não ok]
```

---

## Output do Hook

```yaml
hook_output:
  status: "success" | "error" | "blocked"

  entity_created:
    type: "pessoa" | "iniciativa" | "adr"
    id: "[id_gerado]"
    file: "knowledge/[escopo]/[tipo]/[id].md"

  index_updated:
    file: "knowledge/[escopo]/[tipo]/_index.md"
    changes:
      - "total: [old] → [new]"
      - "by_status.[status]: [old] → [new]"
      - "next_id: [old] → [new]"

  alerts:
    - "[tipo]: [mensagem]"

  info:
    - "[contexto]: [mensagem]"

  related:
    - "ADR relacionada: [id]"
    - "Iniciativa similar: [id]"
    - "Sinergia potencial: [empresas]"

  errors:
    - "[campo]: [erro]"
```

---

## Exemplo de Execução

### Criação de Iniciativa

```
ENTRADA: /roadmap add utua
  nome: "Automação de Bids"
  problema: "Processo manual de ajuste"
  pilares: [automacao, qualidade]
  skills_necessarios: [python, google_ads, ml]
  owner: joao-silva

PRE-VALIDAÇÃO:
  ✓ ID gerado: UTUA-006
  ✓ ID único verificado
  ✓ Owner joao-silva existe
  ✓ Pilares automacao e qualidade existem em contexto.md
  ✓ Skills python, google_ads, ml no vocabulário

CRIAÇÃO:
  ✓ Arquivo criado: knowledge/utua/iniciativas/UTUA-006.md

POST-ATUALIZAÇÃO:
  ✓ _index.md atualizado:
    - total: 5 → 6
    - by_status.backlog: 2 → 3
    - next_id: UTUA-006 → UTUA-007

  ⚠️ ALERTAS:
    - Gap identificado: ml (ninguém tem este skill)

  ℹ️ INFO:
    - Sinergia potencial: ONE CONTROL (usa ML para segmentação)
    - ADR relacionada: BG-ADR-001 (BigQuery para dados)

OUTPUT:
  status: success
  entity_created:
    type: iniciativa
    id: UTUA-006
    file: knowledge/utua/iniciativas/UTUA-006.md
  alerts:
    - "Gap: ml"
  related:
    - "Sinergia: ONE CONTROL"
    - "ADR: BG-ADR-001"
```

---

## Integração com Commands

| Command | Trigger | Tipo de Entidade |
|---------|---------|------------------|
| `/people add [empresa]` | on-entity-create | pessoa |
| `/roadmap add [empresa]` | on-entity-create | iniciativa |
| `/roadmap adr [escopo]` | on-entity-create + on-adr-create | adr |

---

## Erros Comuns

| Erro | Causa | Solução |
|------|-------|---------|
| "ID já existe" | Tentativa de criar com ID duplicado | Usar outro nome ou verificar se é atualização |
| "Owner não encontrado" | Pessoa referenciada não existe | Criar pessoa primeiro ou corrigir ID |
| "Pilar não definido" | Pilar não está em contexto.md | Adicionar pilar ou usar existente |
| "Skill não no vocabulário" | Skill não padronizado | Adicionar ao vocabulário ou usar existente |
