---
name: on-index-update
description: Hook para manter _index.md consistente com entidades do diretório
triggers:
  - Qualquer criação de entidade (pessoa, iniciativa, ADR)
  - Qualquer atualização de entidade
  - Qualquer deleção de entidade
  - Validação periódica de consistência
events:
  - PostToolUse (after entity change)
version: 1
---

# Hook: Atualização de Index

## Propósito

Manter os arquivos `_index.md` sempre sincronizados com os arquivos de entidades do diretório, garantindo consistência do "banco de dados" de arquivos MD.

---

## Papel do _index.md

O arquivo `_index.md` funciona como:

| Função | Descrição |
|--------|-----------|
| **Tabela do banco** | Lista todas entidades do diretório |
| **Cache de estatísticas** | Totais, contagens por status/papel |
| **Controle de IDs** | Próximo ID disponível |
| **Health check** | Alertas agregados |
| **Performance** | Evita ler todos os arquivos para listagens |

---

## Estrutura do _index.md

```yaml
# Campos comuns a todos os tipos
---
type: [pessoas_index | iniciativas_index | adrs_index]
scope: [holding | utua | resolve | one-control | assiny]
version: 1
updated_at: YYYY-MM-DD

# Estatísticas
total: N
by_status: {}  # ou by_papel para pessoas

# Controle de IDs (iniciativas e ADRs)
last_id: "XXX-NNN"
next_id: "XXX-NNN+1"

# Listagem de entidades
entities:
  - id: "id"
    file: "id.md"
    # + campos resumidos específicos

# Saúde
health: [ok | atencao | critico]
health_reason: "motivo"
alerts: []

# Campos específicos por tipo
# pessoas_index: skills_cobertos, skills_sem_backup
# iniciativas_index: (nenhum adicional)
# adrs_index: pending[]
---
```

---

## Operações

### Adicionar Entidade

```yaml
on_entity_create:
  # 1. Gerar entrada para entities[]
  nova_entrada:
    id: [id_gerado]
    file: "[id_gerado].md"

    # Campos por tipo
    pessoa:
      nome: [nome]
      papel: [papel]

    iniciativa:
      nome: [nome]
      status: [status]
      owner: [owner | null]

    adr:
      titulo: [titulo]
      status: [status]
      data: [data_criacao]

  # 2. Adicionar à lista
  entities.add(nova_entrada)

  # 3. Incrementar total
  total += 1

  # 4. Atualizar contadores
  atualizar_contadores:
    pessoa:
      by_papel[pessoa.papel] += 1

    iniciativa:
      by_status[iniciativa.status] += 1

    adr:
      by_status[adr.status] += 1
      SE adr.status == "proposta":
        pending.add({
          id: adr.id,
          titulo: adr.titulo,
          deadline: adr.deadline
        })

  # 5. Atualizar next_id (iniciativas e ADRs)
  atualizar_next_id:
    SE tipo in [iniciativa, adr]:
      last_id = id_gerado
      next_id = incrementar_id(id_gerado)

  # 6. Atualizar timestamp
  updated_at = data_atual

  # 7. Recalcular health
  recalcular_health()

  # 8. Salvar
  SALVAR _index.md
```

### Atualizar Entidade

```yaml
on_entity_update:
  # 1. Encontrar entrada existente
  entry = entities.find(id == entidade.id)

  SE entry não existe:
    ERRO "Entidade [id] não encontrada no _index.md"
    TRIGGER validar_consistencia()

  # 2. Guardar valores antigos para contadores
  valores_antigos:
    status_antigo = entry.status  # para iniciativa/adr
    papel_antigo = entry.papel    # para pessoa
    owner_antigo = entry.owner    # para iniciativa

  # 3. Atualizar campos da entrada
  atualizar_entrada:
    pessoa:
      entry.nome = novo_nome (se mudou)
      entry.papel = novo_papel (se mudou)

    iniciativa:
      entry.nome = novo_nome (se mudou)
      entry.status = novo_status (se mudou)
      entry.owner = novo_owner (se mudou)

    adr:
      entry.titulo = novo_titulo (se mudou)
      entry.status = novo_status (se mudou)

  # 4. Atualizar contadores se mudou
  atualizar_contadores:
    SE status mudou (iniciativa/adr):
      by_status[status_antigo] -= 1
      by_status[novo_status] += 1

    SE papel mudou (pessoa):
      by_papel[papel_antigo] -= 1
      by_papel[novo_papel] += 1

  # 5. Atualizar pending (ADRs)
  SE tipo == adr:
    SE status_antigo == "proposta" AND novo_status != "proposta":
      pending.remove(id)
    SE status_antigo != "proposta" AND novo_status == "proposta":
      pending.add({id, titulo, deadline})

  # 6. Atualizar alerts
  atualizar_alerts:
    SE iniciativa.owner mudou de null para valor:
      alerts.remove("[id]: sem owner")

    SE iniciativa.owner mudou de valor para null:
      alerts.add("[id]: sem owner")

  # 7. Atualizar timestamp
  updated_at = data_atual

  # 8. Recalcular health
  recalcular_health()

  # 9. Salvar
  SALVAR _index.md
```

### Remover Entidade

```yaml
on_entity_delete:
  # 1. Encontrar e remover entrada
  entry = entities.find(id == entidade.id)

  SE entry não existe:
    ALERTA "Entidade [id] já não existe no _index.md"
    RETURN

  entities.remove(entry)

  # 2. Decrementar total
  total -= 1

  # 3. Atualizar contadores
  atualizar_contadores:
    pessoa:
      by_papel[entry.papel] -= 1

    iniciativa:
      by_status[entry.status] -= 1

    adr:
      by_status[entry.status] -= 1
      SE entry.status == "proposta":
        pending.remove(entry.id)

  # 4. Atualizar alerts
  alerts.remove_all(contem: entry.id)

  # 5. Atualizar timestamp
  updated_at = data_atual

  # 6. Recalcular health
  recalcular_health()

  # 7. Salvar
  SALVAR _index.md
```

---

## Recálculo de Health

```yaml
recalcular_health:
  # Coletar todos os alertas
  alertas_atuais = alerts[]

  # Verificar condições por tipo

  # --- pessoas_index ---
  SE tipo == pessoas_index:
    # Skills sem backup
    PARA cada skill em skills_necessarios_geral:
      pessoas_com_skill = contar_pessoas_com_skill(skill)

      SE pessoas_com_skill == 0:
        alertas_atuais.add("Gap: [skill] (ninguém tem)")
        adicionar_em_skills_sem_backup(skill)

      SE pessoas_com_skill == 1:
        alertas_atuais.add("Sem backup: [skill]")
        adicionar_em_skills_sem_backup(skill)

    # Atualizar skills_cobertos
    skills_cobertos = listar_todos_skills_das_pessoas()

  # --- iniciativas_index ---
  SE tipo == iniciativas_index:
    PARA cada entry em entities:
      SE entry.owner == null AND entry.status != "concluido":
        alertas_atuais.add("[entry.id]: sem owner")

      SE entry bloqueada por gap:
        alertas_atuais.add("[entry.id]: bloqueada por gap")

      SE entry.status == "em_andamento" AND atrasada:
        alertas_atuais.add("[entry.id]: atrasada")

  # --- adrs_index ---
  SE tipo == adrs_index:
    PARA cada entry em pending:
      SE entry.deadline < data_atual:
        alertas_atuais.add("[entry.id]: deadline vencido")

      SE entry.deadline < data_atual + 7_dias:
        alertas_atuais.add("[entry.id]: deadline próximo")

  # Definir health
  definir_health:
    SE alertas_atuais.count == 0:
      health = "ok"
      health_reason = null

    SE alertas_atuais.any(contem: "crítico" OR contem: "bloqueada"):
      health = "critico"
      health_reason = "Há alertas críticos"

    SE alertas_atuais.count > 3:
      health = "critico"
      health_reason = "[count] alertas pendentes"

    SE alertas_atuais.count > 0:
      health = "atencao"
      health_reason = "[count] alertas"

  # Atualizar
  alerts = alertas_atuais
```

---

## Validação de Consistência

```yaml
validar_consistencia:
  # Executar periodicamente ou sob demanda
  trigger: "/validate" ou automático

  verificacoes:
    # 1. Comparar entities[] com arquivos no diretório
    arquivos_no_diretorio = listar_arquivos("*.md", exceto: "_index.md")
    ids_no_index = entities[].id

    arquivos_sem_entrada = arquivos_no_diretorio - ids_no_index
    entradas_sem_arquivo = ids_no_index - arquivos_no_diretorio

    SE arquivos_sem_entrada.count > 0:
      ALERTA "Arquivos sem entrada no _index.md:"
      PARA cada arquivo:
        INFO "  - [arquivo]"
      SUGERIR "Executar /sync para sincronizar"

    SE entradas_sem_arquivo.count > 0:
      ALERTA "Entradas sem arquivo correspondente:"
      PARA cada entrada:
        INFO "  - [entrada.id]"
      SUGERIR "Executar /sync para limpar"

    # 2. Verificar total
    total_calculado = arquivos_no_diretorio.count
    SE total != total_calculado:
      ALERTA "Total inconsistente: index=[total], real=[calculado]"
      FIX: total = total_calculado

    # 3. Verificar by_status/by_papel
    contadores_reais = contar_por_status_ou_papel()
    SE by_status != contadores_reais:
      ALERTA "Contadores inconsistentes"
      FIX: by_status = contadores_reais

    # 4. Verificar next_id
    SE tipo in [iniciativa, adr]:
      maior_id = calcular_maior_id(entities)
      proximo_esperado = incrementar(maior_id)
      SE next_id != proximo_esperado:
        ALERTA "next_id inconsistente: atual=[next_id], esperado=[proximo]"
        FIX: next_id = proximo_esperado

  # Resultado
  resultado:
    status: "ok" | "inconsistente" | "corrigido"
    problemas_encontrados: N
    problemas_corrigidos: N
    acoes_pendentes: []
```

---

## Sincronização Completa

```yaml
sincronizar:
  # Reconstruir _index.md do zero baseado nos arquivos
  trigger: "/sync [diretorio]"

  fluxo:
    # 1. Listar todos os arquivos
    arquivos = listar_arquivos("*.md", exceto: "_index.md")

    # 2. Ler frontmatter de cada arquivo
    entities = []
    PARA cada arquivo:
      frontmatter = ler_frontmatter(arquivo)
      entities.add(extrair_entrada(frontmatter))

    # 3. Calcular estatísticas
    total = entities.count
    by_status = contar_por_status(entities)  # ou by_papel

    # 4. Calcular next_id
    SE tipo in [iniciativa, adr]:
      last_id = calcular_maior_id(entities)
      next_id = incrementar(last_id)

    # 5. Recalcular health
    recalcular_health()

    # 6. Salvar novo _index.md
    SALVAR _index.md

  output:
    status: "sincronizado"
    entities_encontradas: N
    alertas_gerados: N
```

---

## Output do Hook

```yaml
hook_output:
  status: "success"

  operacao: "create" | "update" | "delete" | "sync"

  index_atualizado:
    file: "knowledge/[escopo]/[tipo]/_index.md"
    tipo: "[pessoas_index | iniciativas_index | adrs_index]"

  mudancas:
    entities:
      adicionadas: []
      atualizadas: []
      removidas: []

    contadores:
      total:
        anterior: N
        atual: M
      by_status:
        [status]:
          anterior: N
          atual: M

    next_id:
      anterior: "XXX-NNN"
      atual: "XXX-NNN+1"

  health:
    anterior: "ok"
    atual: "atencao"
    reason: "2 alertas"

  alerts:
    adicionados: []
    removidos: []
    total: N
```

---

## Exemplo de Execução

```
TRIGGER: Criação de UTUA-006

OPERAÇÃO: on_entity_create

1. GERAR ENTRADA:
   {
     id: "UTUA-006",
     file: "UTUA-006.md",
     nome: "Automação de Bids",
     status: "backlog",
     owner: null
   }

2. ADICIONAR À LISTA:
   entities.add(nova_entrada)

3. ATUALIZAR ESTATÍSTICAS:
   total: 5 → 6
   by_status.backlog: 2 → 3

4. ATUALIZAR next_id:
   last_id: UTUA-006
   next_id: UTUA-007

5. ATUALIZAR ALERTS:
   alerts.add("UTUA-006: sem owner")

6. RECALCULAR HEALTH:
   health: ok → atencao
   reason: "1 alerta"

7. ATUALIZAR TIMESTAMP:
   updated_at: 2025-01-10

OUTPUT:
  status: success
  mudancas:
    entities.adicionadas: [UTUA-006]
    total: 5 → 6
    by_status.backlog: 2 → 3
    next_id: UTUA-006 → UTUA-007
  health: ok → atencao
  alerts.adicionados: ["UTUA-006: sem owner"]
```

---

## Integração com Outros Hooks

| Hook | Aciona on-index-update |
|------|------------------------|
| `on-entity-create` | Após criar qualquer entidade |
| `on-iniciativa-complete` | Após mudar status |
| `on-adr-create` | Após criar ADR |
| `on-gap-identified` | Para atualizar alerts |
| `on-pessoa-assign` | Após mudar owner |

---

## Comandos Relacionados

| Comando | Ação |
|---------|------|
| `/validate [escopo]` | Verifica consistência do _index.md |
| `/sync [escopo]` | Reconstrói _index.md do zero |
| `/status` | Usa _index.md para visão rápida |

---

## Performance

O _index.md otimiza performance:

```yaml
sem_index:
  /roadmap status utua:
    - Ler todos os arquivos em iniciativas/
    - Parsear frontmatter de cada um
    - Calcular estatísticas
    - Tempo: O(n) leituras

com_index:
  /roadmap status utua:
    - Ler apenas _index.md
    - Estatísticas já calculadas
    - Tempo: O(1) leitura
```

---

## Estrutura Final do _index.md

### pessoas/_index.md

```yaml
---
type: pessoas_index
scope: utua
version: 1
updated_at: 2025-01-10

total: 4
by_papel:
  lider_tech: 1
  lider_negocio: 1
  analista: 2

entities:
  - id: joao-silva
    file: joao-silva.md
    nome: "João Silva"
    papel: lider_tech
  - id: maria-santos
    file: maria-santos.md
    nome: "Maria Santos"
    papel: analista

health: atencao
health_reason: "1 skill sem backup"
alerts:
  - "Sem backup: bigquery"

skills_cobertos: [python, google_ads, bigquery, analytics]
skills_sem_backup: [bigquery]
---
```

### iniciativas/_index.md

```yaml
---
type: iniciativas_index
scope: utua
version: 1
updated_at: 2025-01-10

total: 6
by_status:
  backlog: 3
  em_andamento: 2
  concluido: 1

last_id: "UTUA-006"
next_id: "UTUA-007"

entities:
  - id: UTUA-001
    file: UTUA-001.md
    nome: "Dashboard Real-time"
    status: concluido
    owner: joao-silva
  - id: UTUA-006
    file: UTUA-006.md
    nome: "Automação de Bids"
    status: backlog
    owner: null

health: atencao
health_reason: "1 iniciativa sem owner"
alerts:
  - "UTUA-006: sem owner"
---
```

### adrs/_index.md

```yaml
---
type: adrs_index
scope: holding
version: 1
updated_at: 2025-01-10

total: 4
by_status:
  proposta: 1
  aceita: 2
  substituida: 1

last_id: "BG-ADR-004"
next_id: "BG-ADR-005"

entities:
  - id: BG-ADR-001
    file: BG-ADR-001.md
    titulo: "BigQuery como Warehouse"
    status: aceita
    data: 2024-06-15
  - id: BG-ADR-004
    file: BG-ADR-004.md
    titulo: "Vector DB para RAG"
    status: proposta
    data: 2025-01-10

health: atencao
health_reason: "1 decisão pendente"
alerts:
  - "BG-ADR-004: deadline 2025-01-31"

pending:
  - id: BG-ADR-004
    titulo: "Vector DB para RAG"
    deadline: 2025-01-31
    responsavel: rodrigo-missagia
---
```
