---
command: "people status $scope"
description: Visao de pessoas e capacidades por empresa ou do grupo todo.
args:
  scope:
    description: "Escopo: holding, utua, resolve, one-control, assiny, ou all (default)"
    required: false
---

# /people status

## Descricao

Mostra visao consolidada de pessoas, skills e gaps.

## Uso

```
/people status [escopo]
```

**Escopos validos:**
- `holding` - Apenas pessoas da holding
- `utua` | `resolve` | `one-control` | `assiny` - Empresa especifica
- `all` - Todas as empresas (default)

## Fluxo de Execucao

### 1. Identificar escopo

```
SE escopo nao informado OU escopo = "all":
  escopos = [holding, utua, resolve, one-control, assiny]
SE escopo = empresa especifica:
  VALIDAR escopo em [holding, utua, resolve, one-control, assiny]
  SE invalido:
    ERRO "Escopo invalido. Use: holding, utua, resolve, one-control, assiny ou all"
  escopos = [escopo]
```

### 2. Para cada escopo, ler _index.md

```
PARA cada empresa em escopos:
  LER ./knowledge/[empresa]/pessoas/_index.md
  EXTRAIR do frontmatter:
    - total
    - by_papel
    - health
    - alerts
    - skills_cobertos
    - skills_sem_backup
```

### 3. Consolidar dados

```
totais = {
  pessoas: 0,
  gaps_criticos: 0,
  sobrecarregados: 0
}

PARA cada empresa:
  totais.pessoas += empresa.total
  totais.gaps_criticos += count(empresa.skills_sem_backup)
  totais.sobrecarregados += count(empresa.alerts onde tipo = "sobrecarga")
```

### 4. Apresentar resultado

## Output Esperado

```
+---------------------------------------------------------+
| PEOPLE STATUS - [ESCOPO]                                |
+---------------------------------------------------------+
|                                                         |
| HOLDING (2 pessoas)                                     |
|   * CTO: 1                                              |
|   * Analista: 1                                         |
|   Skills: arquitetura, python, data_engineering         |
|   [OK] Health: OK                                       |
|                                                         |
| UTUA (4 pessoas)                                        |
|   * Lider Tech: 1                                       |
|   * Dev Senior: 2                                       |
|   * Analista: 1                                         |
|   Skills: google_ads, meta_ads, python                  |
|   [!] Health: ATENCAO                                   |
|   +-- Sem backup para: programatica                     |
|                                                         |
| [... outras empresas ...]                               |
|                                                         |
+---------------------------------------------------------+
| RESUMO GERAL                                            |
|   Total: 15 pessoas                                     |
|   Gaps criticos: 3                                      |
|   Pessoas sobrecarregadas: 2                            |
+---------------------------------------------------------+
```

## Alertas Automaticos

Durante a apresentacao, destacar:

- **Skills sem backup** (apenas 1 pessoa tem o skill)
- **Pessoas sobrecarregadas** (em mais de 3 iniciativas)
- **Papeis sem representante** (papel esperado mas sem ninguem)

## Arquivos Lidos

- `./knowledge/[escopo]/pessoas/_index.md` - Para cada escopo

## Validacoes

- Verificar se pasta `./knowledge/` existe
- Verificar se `_index.md` existe para cada escopo
- Se nao existir, sugerir: "Execute 'inicializar knowledge' primeiro"
