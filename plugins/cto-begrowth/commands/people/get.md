---
command: "people get $id"
description: Busca detalhes completos de uma pessoa pelo ID.
args:
  id:
    description: "ID da pessoa (ex: joao-silva)"
    required: true
---

# /people get

## Descricao

Mostra detalhes completos de uma pessoa, incluindo skills, iniciativas atuais e relacionamentos de backup.

## Uso

```
/people get [id]
```

**Exemplos:**
- `/people get joao-silva`
- `/people get rodrigo-missagia`
- `/people get maria-santos`

## Fluxo de Execucao

### 1. Validar parametro

```
SE id nao informado:
  ERRO "ID da pessoa e obrigatorio"
  EXEMPLO "/people get joao-silva"
```

### 2. Buscar pessoa em todos os escopos

```
escopo_encontrado = null
pessoa_entry = null

PARA cada escopo em [holding, utua, resolve, one-control, assiny]:
  LER ./knowledge/[escopo]/pessoas/_index.md
  EXTRAIR entities[]

  PARA cada entity em entities:
    SE entity.id == id:
      escopo_encontrado = escopo
      pessoa_entry = entity
      BREAK

  SE escopo_encontrado:
    BREAK

SE nao encontrado:
  ERRO "Pessoa nao encontrada: [id]"
  SUGERIR "Use /people status para ver todas as pessoas"
```

### 3. Ler arquivo completo da pessoa

```
LER ./knowledge/[escopo_encontrado]/pessoas/[id].md

EXTRAIR frontmatter:
  - nome
  - email
  - papel
  - skills[]
  - iniciativas[]
  - reporta_a
  - backup_de[]
  - backup_por[]

EXTRAIR conteudo markdown (apos frontmatter)
```

### 4. Buscar detalhes das iniciativas

```
iniciativas_detalhes = []

PARA cada iniciativa em pessoa.iniciativas:
  # Determinar escopo da iniciativa pelo prefixo
  # UTUA-001 -> utua, ONE-CONTROL-001 -> one-control, etc
  escopo_iniciativa = extrair_escopo_do_id(iniciativa.id)

  LER ./knowledge/[escopo_iniciativa]/iniciativas/[iniciativa.id].md
  EXTRAIR do frontmatter:
    - nome
    - status

  ADICIONAR em iniciativas_detalhes:
    - id: iniciativa.id
      nome: iniciativa_nome
      status: iniciativa_status
      papel_pessoa: iniciativa.papel
```

### 5. Buscar detalhes de backup

```
backup_info = {
  e_backup_de: [],
  tem_backup: []
}

SE pessoa.backup_de nao vazio:
  PARA cada id_pessoa em pessoa.backup_de:
    LER ./knowledge/[escopo]/pessoas/[id_pessoa].md
    EXTRAIR nome
    ADICIONAR em backup_info.e_backup_de: {id: id_pessoa, nome: nome}

SE pessoa.backup_por nao vazio:
  PARA cada id_pessoa em pessoa.backup_por:
    LER ./knowledge/[escopo]/pessoas/[id_pessoa].md
    EXTRAIR nome
    ADICIONAR em backup_info.tem_backup: {id: id_pessoa, nome: nome}
```

### 6. Buscar quem reporta para essa pessoa

```
reportam_para = []

LER ./knowledge/[escopo_encontrado]/pessoas/_index.md
PARA cada entity em entities:
  LER ./knowledge/[escopo_encontrado]/pessoas/[entity.id].md
  SE pessoa.reporta_a == id:
    ADICIONAR entity em reportam_para
```

### 7. Apresentar resultado

## Output Esperado

```
+---------------------------------------------------------+
| PESSOA: Joao Silva                                      |
+---------------------------------------------------------+
| ID: joao-silva                                          |
| Empresa: UTUA                                           |
| Papel: Lider Tech                                       |
| Email: joao@utua.com                                    |
| Reporta a: rodrigo-missagia                             |
+---------------------------------------------------------+
| SKILLS                                                  |
|   * google_ads: Senior                                  |
|   * python: Pleno                                       |
|   * bigquery: Junior                                    |
+---------------------------------------------------------+
| INICIATIVAS ATUAIS (2)                                  |
|   * UTUA-001: Dashboard Real-time [Em andamento]        |
|     +-- Papel: Owner                                    |
|   * UTUA-003: API Tracking [Em andamento]               |
|     +-- Papel: Contribuidor                             |
+---------------------------------------------------------+
| EQUIPE (reportam para esta pessoa)                      |
|   * maria-santos (Dev Senior)                           |
|   * pedro-oliveira (Analista)                           |
+---------------------------------------------------------+
| BACKUP                                                  |
|   * E backup de: -                                      |
|   * Tem backup: maria-santos                            |
+---------------------------------------------------------+
```

## Arquivos Lidos

- `./knowledge/[escopo]/pessoas/_index.md` - Para busca inicial
- `./knowledge/[escopo]/pessoas/[id].md` - Arquivo da pessoa
- `./knowledge/[escopo]/iniciativas/[id].md` - Para cada iniciativa (frontmatter)
- `./knowledge/[escopo]/pessoas/[id].md` - Para pessoas de backup (frontmatter)

## Validacoes

- ID deve ser informado
- Pessoa deve existir em algum escopo
- Tratar caso de iniciativas nao encontradas (podem ter sido removidas)

## Erros Possiveis

- "Pessoa nao encontrada: [id]"
- "Iniciativa [id] referenciada mas nao encontrada"
- "Pasta knowledge nao existe. Execute 'inicializar knowledge' primeiro"
