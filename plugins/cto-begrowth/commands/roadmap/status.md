---
command: "roadmap status $scope"
description: Visao de iniciativas e progresso por empresa ou do grupo todo. Use para ver status das iniciativas.
args:
  scope:
    description: "Escopo: utua, resolve, one-control, assiny, ou all (default)"
    required: false
---

# /roadmap status

Mostra visao consolidada de iniciativas agrupadas por status.

## Uso

```
/roadmap status [escopo]
```

**Escopos validos:**
- `utua` | `resolve` | `one-control` | `assiny` - Empresa especifica
- `all` - Todas as empresas (default se nao informado)

## Fluxo de Execucao

### 1. Determinar escopo

```
SE escopo nao informado OU escopo == "all":
  empresas = [utua, resolve, one-control, assiny]
SENAO SE escopo em [utua, resolve, one-control, assiny]:
  empresas = [escopo]
SENAO:
  ERRO "Escopo invalido. Use: utua, resolve, one-control, assiny ou all"
```

### 2. Para cada empresa, ler _index.md

```
PARA cada empresa em empresas:
  LER ./knowledge/[empresa]/iniciativas/_index.md
  EXTRAIR do frontmatter:
    - total
    - by_status (backlog, em_andamento, pausado, concluido, cancelado)
    - health
    - alerts[]
    - entities[] (lista resumida)
```

### 3. Consolidar dados

```
totais_gerais = {
  total: 0,
  em_andamento: 0,
  backlog: 0,
  pausado: 0,
  concluido: 0,
  cancelado: 0,
  bloqueadas: 0,
  sem_owner: 0
}

PARA cada empresa:
  SOMAR nos totais_gerais
  CONTAR bloqueadas (iniciativas com alerts de bloqueio)
  CONTAR sem_owner (iniciativas sem owner)
```

### 4. Apresentar resultado

Para cada empresa, mostrar:
- Total de iniciativas
- Contagem por status (com indicadores de cor)
- Lista das iniciativas em andamento com progresso e owner
- Alertas relevantes

## Output Esperado

```
+----------------------------------------------------+
| ROADMAP STATUS - [ESCOPO]                          |
+----------------------------------------------------+
|                                                    |
| UTUA (5 iniciativas)                               |
|   [backlog]      Backlog: 2                        |
|   [andamento]    Em andamento: 2                   |
|   [ok]           Concluido: 1                      |
|                                                    |
|   EM ANDAMENTO:                                    |
|   * UTUA-001: Dashboard Real-time (40%)            |
|     -> Owner: joao-silva                           |
|   * UTUA-003: API Tracking (60%)                   |
|     -> Owner: maria-santos                         |
|                                                    |
|   ALERTAS:                                         |
|   * UTUA-002: sem owner                            |
|   * UTUA-004: bloqueada por gap de skill           |
|                                                    |
| RESOLVE (3 iniciativas)                            |
|   [...]                                            |
|                                                    |
+----------------------------------------------------+
| RESUMO GERAL                                       |
|   Total: 15 iniciativas                            |
|   Em andamento: 6                                  |
|   Bloqueadas: 3                                    |
|   Sem owner: 4                                     |
+----------------------------------------------------+
```

## Informacoes Extras

- Se uma empresa nao tiver o arquivo `_index.md`, informar que nao ha iniciativas registradas
- Ordenar iniciativas em andamento por progresso (maior primeiro)
- Destacar iniciativas pausadas ha mais de 30 dias
- Mostrar health geral do roadmap se disponivel

## Arquivos Lidos

```
./knowledge/[empresa]/iniciativas/_index.md
```

## Validacoes

- Verificar se escopo eh valido
- Verificar se arquivos _index.md existem
