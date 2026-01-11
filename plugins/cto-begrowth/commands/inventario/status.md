---
command: "inventario status $scope"
description: Visao consolidada do stack tecnico, ferramentas e gaps.
args:
  scope:
    description: "Escopo: holding, utua, resolve, one-control, assiny, ou all (default)"
    required: false
---

# /inventario status

## Descricao
Mostra visao consolidada do stack tecnico, ferramentas e gaps.

## Uso
```
/inventario status [escopo]
```

**Escopos validos:**
- `holding` - Stack compartilhado do grupo
- `utua` | `resolve` | `one-control` | `assiny` - Stack especifico
- `all` - Visao consolidada (default)

## Fluxo de Execucao

### 1. Ler stack.md do escopo
```
SE escopo == "holding" ou "all":
  LER ./knowledge/holding/stack.md
  EXTRAIR:
    - by_status (homologado, avaliando, depreciado)
    - gaps
    - health

SE escopo == empresa ou "all":
  # Empresas podem ter tech especifica nao listada no holding
  # Por enquanto, usamos apenas holding/stack.md
```

### 2. Cruzar com pessoas
```
PARA cada tech em stack:
  BUSCAR pessoas com skill correspondente em ./knowledge/[escopo]/pessoas/
  SE nenhuma pessoa:
    ADICIONAR ao gap
```

### 3. Cruzar com iniciativas
```
PARA cada gap:
  BUSCAR iniciativas que precisam do skill em ./knowledge/[escopo]/iniciativas/
  ADICIONAR a lista de "bloqueadas"
```

## Output Esperado

```
+----------------------------------------------------+
| INVENTARIO - BE GROWTH                             |
+----------------------------------------------------+
|                                                    |
| TECNOLOGIAS HOMOLOGADAS (12)                       |
|                                                    |
| Data Platform                                      |
|   OK BigQuery      | rodrigo-missagia | BG-ADR-001 |
|   OK Pub/Sub       | rodrigo-missagia | -          |
|   OK Dataflow      | -                | -          |
|                                                    |
| Backend                                            |
|   OK Python        | 5 pessoas        | -          |
|   OK FastAPI       | 3 pessoas        | -          |
|   OK Temporal.io   | -                | BG-ADR-002 |
|                                                    |
| AI/ML                                              |
|   OK LangChain     | rodrigo-missagia | -          |
|   OK OpenAI API    | rodrigo-missagia | -          |
|                                                    |
| Observabilidade                                    |
|   OK Grafana       | -                | -          |
|   OK Prometheus    | -                | -          |
|                                                    |
+----------------------------------------------------+
| EM AVALIACAO (2)                                   |
|                                                    |
|   >> Vector DB     | Deadline: 2025-01-31          |
|     +-- Responsavel: CTO                           |
|     +-- ADR pendente: BG-ADR-003                   |
|                                                    |
|   >> Feature Store | Sem deadline                  |
|     +-- Responsavel: nao definido                  |
|                                                    |
+----------------------------------------------------+
| GAPS DE CAPACIDADE (4)                             |
|                                                    |
|   [X] HubSpot                                      |
|      Impacto: ALTO                                 |
|      Iniciativas bloqueadas: -                     |
|      Plano: Avaliar terceirizar                    |
|                                                    |
|   [X] ClickUp                                      |
|      Impacto: MEDIO                                |
|      Iniciativas bloqueadas: -                     |
|      Plano: Definir owner                          |
|                                                    |
|   [X] AI Enabler (papel)                           |
|      Impacto: ALTO                                 |
|      Iniciativas bloqueadas: UTUA-003, RESOLVE-002 |
|      Plano: Criar papel                            |
|                                                    |
|   [X] Data Eng backup                              |
|      Impacto: CRITICO                              |
|      Iniciativas bloqueadas: Todas com BigQuery    |
|      Plano: Contratar                              |
|                                                    |
+----------------------------------------------------+
| SAUDE: ATENCAO                                     |
| Motivo: 4 gaps de capacidade                       |
+----------------------------------------------------+
```

## Regras de Formatacao

- Usar boxes ASCII para melhor visualizacao
- Status das tecnologias:
  - `OK` - Homologado
  - `>>` - Em avaliacao
  - `[X]` - Gap/faltando
- Mostrar responsavel e ADR quando existirem
- Calcular health baseado em:
  - OK: Nenhum gap critico
  - ATENCAO: Gaps de capacidade existentes
  - CRITICO: Gaps bloqueando iniciativas

## Arquivos Consultados

- `./knowledge/holding/stack.md` - Stack tecnico e gaps
- `./knowledge/holding/pessoas/_index.md` - Pessoas da holding
- `./knowledge/[empresa]/pessoas/_index.md` - Pessoas por empresa
- `./knowledge/[empresa]/iniciativas/_index.md` - Iniciativas por empresa
