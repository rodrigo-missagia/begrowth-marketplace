---
command: "roadmap priorize $scope"
description: Prioriza backlog usando criterios estrategicos. Usa skill de priorizacao.
args:
  scope:
    description: "Escopo: utua, resolve, one-control, assiny, ou all"
    required: false
---

# /roadmap priorize

Executa priorizacao do backlog com base em criterios definidos, gerando ranking recomendado.

## Uso

```
/roadmap priorize [escopo]
```

**Escopos validos:**
- `utua` | `resolve` | `one-control` | `assiny` - Empresa especifica
- `all` - Todas as empresas (default)

## Fluxo de Execucao

### 1. Determinar escopo

```
SE escopo nao informado OU escopo == "all":
  empresas = [utua, resolve, one-control, assiny]
SENAO SE escopo em [utua, resolve, one-control, assiny]:
  empresas = [escopo]
SENAO:
  ERRO "Escopo invalido"
```

### 2. Coletar iniciativas em backlog

```
iniciativas = []

PARA cada empresa em empresas:
  LER ./knowledge/[empresa]/iniciativas/_index.md
  PARA cada entity em entities[]:
    SE entity.status == "backlog":
      LER ./knowledge/[empresa]/iniciativas/[entity.id].md
      ADICIONAR a iniciativas[]
```

### 3. Carregar contexto para priorizacao

```
PARA cada empresa:
  LER ./knowledge/[empresa]/contexto.md
  EXTRAIR:
    - pilares[] (para score de alinhamento)
    - dores[] (para score de urgencia)
    - metas[] (para score de relevancia)

LER ./knowledge/holding/sinergias.md (para score de sinergia)
```

### 4. Calcular scores

Para cada iniciativa, calcular:

```
# 1. Alinhamento com pilares (peso: 25%)
pilares_empresa = empresa.pilares
pilares_iniciativa = iniciativa.pilares
alinhamento = (pilares_em_comum / total_pilares_empresa) * 100

# 2. Resolve dor critica (peso: 25%)
dores_empresa = empresa.dores (ordenadas por prioridade)
dor_match = 0
PARA cada dor em dores_empresa (com peso decrescente):
  SE iniciativa.problema relacionado a dor:
    dor_match = peso_dor
    BREAK
resolve_dor = dor_match

# 3. Habilita outras iniciativas (peso: 15%)
# Quantas iniciativas dependem desta
dependentes = contar_dependentes(iniciativa.id)
habilita_score = min(dependentes * 20, 100)

# 4. Sinergia com grupo (peso: 20%)
sinergias = len(iniciativa.sinergia_potencial)
sinergia_score = min(sinergias * 25, 100)

# 5. Complexidade inversa (peso: 15%)
# Baseado em skills e disponibilidade
gaps = contar_gaps_skill(iniciativa)
tem_owner = iniciativa.owner != null
complexidade_score = 100 - (gaps * 20) + (30 se tem_owner)
complexidade_score = max(0, min(100, complexidade_score))

# Score final
score_final = (
  alinhamento * 0.25 +
  resolve_dor * 0.25 +
  habilita_score * 0.15 +
  sinergia_score * 0.20 +
  complexidade_score * 0.15
)
```

### 5. Gerar ranking

```
# Ordenar por score_final decrescente
iniciativas.sort(by=score_final, desc=true)

# Identificar agrupamentos
grupos = []
PARA cada par de iniciativas:
  SE podem_rodar_juntas(ini1, ini2):
    # Mesmo owner potencial
    # Skills similares
    # Pilares complementares
    grupos.append([ini1, ini2])
```

### 6. Identificar bloqueios

```
alertas = []

PARA cada iniciativa:
  SE nao iniciativa.owner:
    alertas.append("[id]: Sem owner definido")

  gaps = identificar_gaps_skill(iniciativa)
  SE gaps:
    alertas.append("[id]: Gap de skill ([skills])")

  dependencias_nao_concluidas = []
  PARA cada dep em iniciativa.depende_de.iniciativas:
    SE dep.status != "concluido":
      dependencias_nao_concluidas.append(dep)
  SE dependencias_nao_concluidas:
    alertas.append("[id]: Depende de [deps]")
```

## Output Esperado

```
+----------------------------------------------------+
| PRIORIZACAO - [ESCOPO]                             |
+----------------------------------------------------+
|                                                    |
| RANKING RECOMENDADO                                |
|                                                    |
| 1. [ID]: [nome]  [DESTAQUE SE TOP 3]               |
|    Score: [score]/100                              |
|    +- Pilares: [pilares] ([n]/[total])             |
|    +- Dor critica: [SIM/NAO] ([qual])              |
|    +- Habilita: [lista ou "nenhuma"]               |
|    +- Sinergia: [empresas] ([alta/media/baixa])    |
|    +- Complexidade: [Alta/Media/Baixa]             |
|                                                    |
| 2. [ID]: [nome]                                    |
|    Score: [score]/100                              |
|    [...]                                           |
|                                                    |
| [...]                                              |
|                                                    |
+----------------------------------------------------+
| ALERTAS                                            |
|                                                    |
| * [ID]: Sem owner definido                         |
| * [ID]: Gap de skill ([skills])                    |
| * [ID]: Depende de [deps] (nao concluida)          |
|                                                    |
+----------------------------------------------------+
| AGRUPAMENTOS SUGERIDOS                             |
|                                                    |
| * [ID1] + [ID2]: Podem rodar juntas                |
|   -> Mesmo owner potencial                         |
|   -> Skills complementares                         |
|                                                    |
| * [ID3]: Esperar resolver gap                      |
|   -> Sem [skill] disponivel                        |
|                                                    |
+----------------------------------------------------+
| RECOMENDACAO                                       |
|                                                    |
| Iniciar com: [top 1-3 iniciativas]                 |
| Resolver antes: [bloqueios criticos]               |
|                                                    |
+----------------------------------------------------+
```

## Criterios de Priorizacao

| Criterio | Peso | Descricao |
|----------|------|-----------|
| Alinhamento com pilares | 25% | Quantos pilares estrategicos a iniciativa endereca |
| Resolve dor critica | 25% | Se resolve uma das dores prioritarias da empresa |
| Habilita outras | 15% | Quantas iniciativas dependem desta |
| Sinergia com grupo | 20% | Potencial de reuso por outras empresas |
| Complexidade inversa | 15% | Facilidade de execucao (skills, owner) |

## Arquivos Lidos

```
./knowledge/[empresa]/iniciativas/_index.md
./knowledge/[empresa]/iniciativas/[id].md (para cada em backlog)
./knowledge/[empresa]/contexto.md
./knowledge/[empresa]/pessoas/_index.md
./knowledge/holding/sinergias.md
```

## Validacoes

- Escopo deve ser valido
- Deve haver pelo menos 1 iniciativa em backlog para priorizar
