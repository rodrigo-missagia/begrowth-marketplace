---
command: "roadmap get $id"
description: Busca detalhes completos de uma iniciativa pelo ID.
args:
  id:
    description: "ID da iniciativa (ex: UTUA-001)"
    required: true
---

# /roadmap get

Mostra detalhes completos de uma iniciativa, incluindo dependencias, pessoas envolvidas e sinergias.

## Uso

```
/roadmap get [id]
```

**Exemplos:**
- `/roadmap get UTUA-001`
- `/roadmap get RESOLVE-003`
- `/roadmap get ONE-CONTROL-002`

## Fluxo de Execucao

### 1. Identificar empresa pelo prefixo

```
SE id nao informado:
  ERRO "Informe o ID da iniciativa (ex: UTUA-001)"

# Extrair empresa do prefixo
prefixo = id.split("-")[0].lower()  # UTUA-001 -> utua

mapeamento = {
  "utua": "utua",
  "resolve": "resolve",
  "one": "one-control",  # ONE-CONTROL-001 -> one-control
  "assiny": "assiny"
}

SE prefixo == "one":
  empresa = "one-control"
  # Ajustar ID para formato correto
SENAO:
  empresa = mapeamento[prefixo]
```

### 2. Ler arquivo da iniciativa

```
caminho = ./knowledge/[empresa]/iniciativas/[id].md

SE arquivo nao existe:
  ERRO "Iniciativa [id] nao encontrada"

LER caminho
EXTRAIR frontmatter completo:
  - id, nome, status, progresso
  - owner, contributors[]
  - problema, pilares[]
  - skills_necessarios[]
  - depende_de (iniciativas, adrs, pessoas)
  - sinergia_potencial[]
  - inicio, previsao_fim, data_conclusao
  - resultado, aprendizados

EXTRAIR conteudo markdown:
  - Descricao
  - Decisoes
  - Historico
  - Notas
```

### 3. Enriquecer com dados de pessoas

```
# Owner
SE owner:
  LER ./knowledge/[empresa]/pessoas/[owner].md
  EXTRAIR: nome_completo, papel

# Contributors
PARA cada contributor em contributors[]:
  LER ./knowledge/[empresa]/pessoas/[contributor].md
  EXTRAIR: nome_completo, papel
```

### 4. Enriquecer com ADRs relacionadas

```
PARA cada adr_id em depende_de.adrs[]:
  # ADRs podem ser da holding (BG-ADR-*) ou locais
  SE adr_id comeca com "BG-ADR":
    LER ./knowledge/holding/adrs/[adr_id].md
  SENAO:
    LER ./knowledge/[empresa]/adrs/[adr_id].md
  EXTRAIR: titulo, status
```

### 5. Verificar cobertura de skills

```
LER ./knowledge/[empresa]/pessoas/_index.md
PARA cada skill em skills_necessarios[]:
  coberto = false
  nivel = null
  pessoa_com_skill = null

  PARA cada pessoa em entities[]:
    LER pessoa completa se necessario
    SE pessoa tem skill:
      coberto = true
      nivel = pessoa.skills[skill]
      pessoa_com_skill = pessoa.id
      BREAK

  skills_status.append({
    skill: skill,
    coberto: coberto,
    nivel: nivel,
    pessoa: pessoa_com_skill
  })
```

### 6. Buscar iniciativas dependentes (reverse lookup)

```
# Quais iniciativas dependem desta?
dependentes = []
PARA cada outra_iniciativa em _index.entities[]:
  SE outra_iniciativa != id:
    LER outra_iniciativa
    SE id em outra_iniciativa.depende_de.iniciativas[]:
      dependentes.append(outra_iniciativa.id)
```

### 7. Apresentar resultado

## Output Esperado

```
+----------------------------------------------------+
| [ID]: [nome]                                       |
+----------------------------------------------------+
| Status: [status_icon] [status] ([progresso]%)      |
| Inicio: [inicio]                                   |
| Previsao: [previsao_fim]                           |
+----------------------------------------------------+
| PROBLEMA                                           |
| [problema]                                         |
|                                                    |
| PILARES: [pilares]                                 |
+----------------------------------------------------+
| PESSOAS                                            |
|   Owner: [nome_completo] ([owner_id])              |
|   Contributors:                                    |
|     * [nome_completo] ([contributor_id])           |
+----------------------------------------------------+
| SKILLS NECESSARIOS                                 |
|   [ok] [skill] ([pessoa]: [nivel])                 |
|   [gap] [skill] (gap)                              |
+----------------------------------------------------+
| DEPENDENCIAS                                       |
|   ADRs:                                            |
|     * [adr_id]: [titulo] ([status])                |
|   Iniciativas:                                     |
|     * [ini_id]: [nome]                             |
|   Pessoas:                                         |
|     * [pessoa_id]                                  |
+----------------------------------------------------+
| SINERGIAS POTENCIAIS                               |
|   * [empresa]: [como]                              |
+----------------------------------------------------+
| DEPENDEM DESTA                                     |
|   * [ini_id]: [nome]                               |
+----------------------------------------------------+
| HISTORICO                                          |
|   [data]: [evento]                                 |
|   [data]: [evento]                                 |
+----------------------------------------------------+
```

**Se iniciativa concluida, adicionar:**

```
+----------------------------------------------------+
| RESULTADO                                          |
| [resultado]                                        |
|                                                    |
| APRENDIZADOS                                       |
| [aprendizados]                                     |
+----------------------------------------------------+
```

## Arquivos Lidos

```
./knowledge/[empresa]/iniciativas/[id].md
./knowledge/[empresa]/pessoas/_index.md
./knowledge/[empresa]/pessoas/[owner].md
./knowledge/[empresa]/pessoas/[contributor].md
./knowledge/holding/adrs/[adr_id].md
./knowledge/[empresa]/adrs/[adr_id].md
./knowledge/[empresa]/iniciativas/_index.md
```

## Validacoes

- ID deve ser informado
- Formato do ID deve ser valido (EMPRESA-NNN)
- Arquivo da iniciativa deve existir
