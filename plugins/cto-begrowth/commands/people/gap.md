---
command: "people gap $skill"
description: Analisa gap de skill especifico - quem tem, quem pode aprender, iniciativas impactadas.
args:
  skill:
    description: "Nome do skill (ex: data_engineering, python)"
    required: true
---

# /people gap

## Descricao

Analisa um gap de skill especifico: quem tem, quem pode aprender, que iniciativas sao impactadas e opcoes para resolver.

## Uso

```
/people gap [skill]
```

**Exemplos:**
- `/people gap data_engineering`
- `/people gap temporal`
- `/people gap hubspot`
- `/people gap google_ads`

## Fluxo de Execucao

### 1. Validar parametro

```
SE skill nao informado:
  ERRO "Skill e obrigatorio"
  EXEMPLO "/people gap data_engineering"
```

### 2. Buscar pessoas com o skill

```
pessoas_com_skill = []

PARA cada escopo em [holding, utua, resolve, one-control, assiny]:
  LER ./knowledge/[escopo]/pessoas/_index.md
  EXTRAIR entities[]

  PARA cada entity em entities:
    LER ./knowledge/[escopo]/pessoas/[entity.id].md
    EXTRAIR skills[]

    PARA cada skill_pessoa em skills:
      SE skill_pessoa.nome == skill:
        ADICIONAR em pessoas_com_skill:
          - id: entity.id
            nome: entity.nome
            empresa: escopo
            nivel: skill_pessoa.nivel
            iniciativas_count: count(pessoa.iniciativas)
```

### 3. Buscar pessoas com skills relacionados (candidatos a aprender)

```
# Definir skills relacionados por categoria
skills_relacionados = {
  data_engineering: [python, sql, bigquery, dataflow, airflow],
  python: [data_engineering, backend, automacao],
  google_ads: [meta_ads, programatica, analytics],
  meta_ads: [google_ads, programatica, social_media],
  frontend: [react, javascript, typescript, css],
  backend: [python, node, java, go],
  ...
}

pessoas_potenciais = []

SE skill em skills_relacionados:
  relacionados = skills_relacionados[skill]

  PARA cada escopo em [holding, utua, resolve, one-control, assiny]:
    PARA cada entity em _index.entities:
      LER pessoa

      PARA cada skill_pessoa em pessoa.skills:
        SE skill_pessoa.nome em relacionados E skill_pessoa.nivel em [senior, especialista]:
          SE pessoa nao em pessoas_com_skill:
            ADICIONAR em pessoas_potenciais:
              - id: entity.id
                nome: entity.nome
                empresa: escopo
                skill_relacionado: skill_pessoa.nome
                nivel: skill_pessoa.nivel
```

### 4. Buscar iniciativas que precisam do skill

```
iniciativas_afetadas = []

PARA cada escopo em [utua, resolve, one-control, assiny]:
  LER ./knowledge/[escopo]/iniciativas/_index.md
  EXTRAIR entities[]

  PARA cada entity em entities:
    LER ./knowledge/[escopo]/iniciativas/[entity.id].md
    EXTRAIR skills_necessarios

    SE skill em skills_necessarios:
      ADICIONAR em iniciativas_afetadas:
        - id: entity.id
          nome: entity.nome
          empresa: escopo
          status: entity.status
```

### 5. Classificar situacao

```
count_pessoas = count(pessoas_com_skill)

SE count_pessoas == 0:
  situacao = "CRITICO"
  descricao = "Ninguem tem este skill"
  icone = "[X]"
SE count_pessoas == 1:
  situacao = "RISCO"
  descricao = "Apenas 1 pessoa - sem backup"
  icone = "[!]"
SE count_pessoas >= 2:
  situacao = "OK"
  descricao = "Tem backup"
  icone = "[OK]"
```

### 6. Gerar opcoes de resolucao

```
opcoes = []

# Opcao 1: Contratar
ADICIONAR em opcoes:
  titulo: "CONTRATAR"
  descricao: "Perfil: [skill] Senior/Especialista"
  prioridade: SE situacao == "CRITICO" ENTAO "Alta" SENAO "Media"

# Opcao 2: Treinar (se houver candidatos)
SE pessoas_potenciais nao vazio:
  melhor_candidato = pessoas_potenciais[0]
  ADICIONAR em opcoes:
    titulo: "TREINAR"
    descricao: "Candidato: [melhor_candidato.nome] ([melhor_candidato.empresa])"
    gap: "Upskill de [melhor_candidato.skill_relacionado] para [skill]"

# Opcao 3: Terceirizar
ADICIONAR em opcoes:
  titulo: "TERCEIRIZAR"
  descricao: "Para iniciativas especificas"
  iniciativas: iniciativas_afetadas[0:3]

# Opcao 4: Despriorizar
SE iniciativas_afetadas nao vazio:
  ADICIONAR em opcoes:
    titulo: "DESPRIORIZAR"
    descricao: "Adiar iniciativas dependentes"
    impacto: "[count] iniciativas afetadas"
```

### 7. Apresentar resultado

## Output Esperado

```
+---------------------------------------------------------+
| GAP ANALYSIS: data_engineering                          |
+---------------------------------------------------------+
|                                                         |
| [!] SITUACAO: RISCO - Apenas 1 pessoa, sem backup       |
|                                                         |
| QUEM TEM (1)                                            |
|   * rodrigo-missagia (holding) - Senior                 |
|     +-- Em 2 iniciativas                                |
|                                                         |
| QUEM PODE APRENDER (2)                                  |
|   * joao-silva (utua) - Tem Python Senior               |
|   * maria-santos (assiny) - Tem SQL Senior              |
|                                                         |
| INICIATIVAS AFETADAS (4)                                |
|   * UTUA-001: Dashboard Real-time                       |
|   * ONE-CONTROL-001: CDP Unificado                      |
|   * RESOLVE-002: ETL Pipeline                           |
|   * ASSINY-003: Data Lake                               |
|                                                         |
+---------------------------------------------------------+
| OPCOES DE RESOLUCAO                                     |
|                                                         |
| 1. CONTRATAR                                            |
|    +-- Perfil: Data Engineer Senior                     |
|    +-- Prioridade: Alta                                 |
|                                                         |
| 2. TREINAR                                              |
|    +-- Candidato: joao-silva (UTUA)                     |
|    +-- Gap: Upskill de Python para Data Engineering     |
|                                                         |
| 3. TERCEIRIZAR                                          |
|    +-- Para iniciativas especificas                     |
|    +-- Recomendado para: UTUA-001, ONE-CONTROL-001      |
|                                                         |
| 4. DESPRIORIZAR                                         |
|    +-- Adiar iniciativas dependentes                    |
|    +-- Impacto: 4 iniciativas                           |
|                                                         |
+---------------------------------------------------------+
```

## Arquivos Lidos

- `./knowledge/[escopo]/pessoas/_index.md` - Para cada escopo
- `./knowledge/[escopo]/pessoas/[id].md` - Para cada pessoa
- `./knowledge/[escopo]/iniciativas/_index.md` - Para cada empresa
- `./knowledge/[escopo]/iniciativas/[id].md` - Para cada iniciativa (skills_necessarios)

## Validacoes

- Skill deve ser informado
- Tratar caso de skill nao encontrado em nenhum lugar

## Analises Complementares

Ao apresentar resultado, considerar:

- **Concentracao de risco**: Se a unica pessoa com o skill esta em muitas iniciativas
- **Distribuicao geografica**: Se o skill esta concentrado em uma empresa
- **Senioridade**: Preferir candidatos senior para treinamento
- **Carga atual**: Evitar sobrecarregar pessoas ja em muitas iniciativas
