---
command: "roadmap sinergia $item"
description: Analisa sinergias entre empresas para uma iniciativa ou tecnologia. Usa skill de sinergias.
args:
  item:
    description: "ID da iniciativa (ex: UTUA-001) ou nome de tecnologia"
    required: true
---

# /roadmap sinergia

Analisa como uma iniciativa ou tecnologia pode ser aproveitada por outras empresas do grupo.

## Uso

```
/roadmap sinergia [item]
```

**Exemplos:**
- `/roadmap sinergia UTUA-001` - Analisa sinergia de uma iniciativa
- `/roadmap sinergia "sistema de scoring"` - Analisa sinergia de um conceito
- `/roadmap sinergia "chatbot atendimento"` - Analisa sinergia de uma solucao
- `/roadmap sinergia bigquery` - Analisa sinergia de uma tecnologia

## Fluxo de Execucao

### 1. Identificar tipo de item

```
SE item match padrao [A-Z]+-[0-9]{3}:
  tipo = "iniciativa"
  # Ex: UTUA-001, RESOLVE-002
SENAO:
  tipo = "conceito"
  # Ex: "sistema de scoring", "bigquery"
```

### 2. Carregar contexto do item

#### Para iniciativa:

```
empresa_origem = extrair_empresa_do_id(item)
LER ./knowledge/[empresa_origem]/iniciativas/[item].md

EXTRAIR:
  - nome
  - problema
  - pilares[]
  - skills_necessarios[]
  - sinergia_potencial[] (se ja existir)

# Contexto da empresa de origem
LER ./knowledge/[empresa_origem]/contexto.md
EXTRAIR: pilares[], dores[], metas[]
```

#### Para conceito:

```
descricao = item
empresa_origem = null

# Tentar identificar tecnologias mencionadas
LER ${CLAUDE_PLUGIN_ROOT}/schemas/vocabulario.yaml
keywords = extrair_keywords(descricao)
```

### 3. Carregar contexto de todas empresas

```
PARA cada empresa em [utua, resolve, one-control, assiny]:
  LER ./knowledge/[empresa]/contexto.md
  EXTRAIR:
    - pilares[]
    - dores[]
    - metas[]
    - modelo_negocio (descricao)

  LER ./knowledge/[empresa]/iniciativas/_index.md
  EXTRAIR:
    - entities[] (iniciativas existentes)

LER ./knowledge/holding/stack.md
LER ./knowledge/holding/sinergias.md
```

### 4. Analisar aplicabilidade por empresa

```
analise = {}

PARA cada empresa:
  SE empresa == empresa_origem:
    analise[empresa] = {
      tipo: "origem",
      descricao: "Caso primario / desenvolve solucao"
    }
    CONTINUE

  # Calcular relevancia
  relevancia = 0
  como_usar = []
  adaptar = []
  isolar = []

  # Verificar pilares em comum
  pilares_comuns = intersecao(item.pilares, empresa.pilares)
  SE pilares_comuns:
    relevancia += 30
    como_usar.append("Alinha com pilares: " + pilares_comuns)

  # Verificar dores similares
  PARA cada dor em empresa.dores:
    SE item.problema similar a dor.descricao:
      relevancia += 25
      como_usar.append("Resolve dor similar: " + dor.nome)

  # Verificar iniciativas existentes relacionadas
  PARA cada ini em empresa.iniciativas:
    SE keywords_match(item, ini):
      relevancia += 15
      como_usar.append("Relacionado a: " + ini.id)

  # Analisar o que precisa adaptar vs isolar
  SE tipo == "iniciativa":
    # O que eh generico (compartilhar)
    # O que eh especifico do dominio (adaptar)
    # O que eh regra de negocio (isolar)
    adaptar = identificar_adaptacoes(item, empresa)
    isolar = identificar_isolamentos(item, empresa)

  analise[empresa] = {
    relevancia: relevancia,
    prioridade: "alta" se relevancia > 50 senao "media" se relevancia > 25 senao "baixa",
    como_usar: como_usar,
    adaptar: adaptar,
    isolar: isolar
  }
```

### 5. Gerar recomendacao

```
# Determinar estrategia geral
SE todas empresas tem relevancia > 50:
  estrategia = "COMPARTILHAR (totalmente)"
SENAO SE alguma empresa tem relevancia > 50:
  estrategia = "COMPARTILHAR (parcialmente)"
SENAO:
  estrategia = "NAO COMPARTILHAR (especifico demais)"

# Ordenar empresas por relevancia
ordem_sugerida = sorted(analise, by=relevancia, desc=true)
```

## Output Esperado

```
+----------------------------------------------------+
| ANALISE DE SINERGIA: [nome/descricao]              |
| Origem: [empresa_origem ou "conceito"]             |
+----------------------------------------------------+
|                                                    |
| COMO CADA EMPRESA PODE USAR                        |
|                                                    |
| [EMPRESA_ORIGEM] (origem)                          |
|   -> Caso primario: [descricao do uso]             |
|   -> Desenvolve a solucao core                     |
|                                                    |
| [EMPRESA_2] - Prioridade: [alta/media/baixa]       |
|   -> Pode usar: [o que]                            |
|   -> Para: [qual problema/dor]                     |
|   -> Adaptar: [o que precisa customizar]           |
|   -> Isolar: [o que nao deve compartilhar]         |
|                                                    |
| [EMPRESA_3] - Prioridade: [alta/media/baixa]       |
|   -> [...]                                         |
|                                                    |
| [EMPRESA_4] - Prioridade: baixa                    |
|   -> Uso limitado: [motivo]                        |
|   -> Nao priorizar                                 |
|                                                    |
+----------------------------------------------------+
| RECOMENDACAO: [ESTRATEGIA]                         |
+----------------------------------------------------+
|                                                    |
| O QUE COMPARTILHAR                                 |
|   * [componente/modulo generico]                   |
|   * [infra comum]                                  |
|   * [padroes e boas praticas]                      |
|                                                    |
| O QUE ISOLAR                                       |
|   * [regras de negocio especificas]                |
|   * [dados sensiveis]                              |
|   * [customizacoes de dominio]                     |
|                                                    |
| ORDEM SUGERIDA                                     |
|   1. [empresa_origem] desenvolve para [caso]       |
|   2. [empresa_2] adapta para [caso]                |
|   3. [empresa_3] avalia se vale adaptar            |
|   4. [empresa_4]: nao priorizar                    |
|                                                    |
+----------------------------------------------------+
| PROXIMOS PASSOS                                    |
|                                                    |
| * Alinhar arquitetura compartilhavel               |
| * Definir interfaces de integracao                 |
| * Documentar em ADR se decisao estrategica         |
|                                                    |
+----------------------------------------------------+
```

## Arquivos Lidos

```
./knowledge/[empresa]/iniciativas/[id].md (se iniciativa)
./knowledge/[empresa]/contexto.md (todas empresas)
./knowledge/[empresa]/iniciativas/_index.md (todas empresas)
./knowledge/holding/stack.md
./knowledge/holding/sinergias.md
${CLAUDE_PLUGIN_ROOT}/schemas/vocabulario.yaml
```

## Arquivos Potencialmente Atualizados

Se o usuario confirmar, atualizar:

```
./knowledge/[empresa]/iniciativas/[id].md
  - Adicionar em sinergia_potencial[]

./knowledge/holding/sinergias.md
  - Registrar nova sinergia identificada
```

## Validacoes

- Item deve ser informado
- Se for ID de iniciativa, deve existir
