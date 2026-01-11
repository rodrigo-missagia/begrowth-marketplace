---
command: "people add $scope"
description: Adiciona nova pessoa ao diretorio. Comando interativo.
args:
  scope:
    description: "Escopo: holding, utua, resolve, one-control, ou assiny"
    required: false
---

# /people add

## Descricao

Adiciona nova pessoa ao diretorio de pessoas de uma empresa.

**IMPORTANTE:** A pasta `knowledge/` fica na RAIZ DO PROJETO, nao dentro do plugin!

- CORRETO: `./knowledge/holding/pessoas/` (a partir da raiz do projeto)
- ERRADO: `cto-plugin/knowledge/` ou qualquer caminho dentro do plugin

## Uso

```
/people add [escopo]
```

**Escopos validos:** `holding`, `utua`, `resolve`, `one-control`, `assiny`

## Fluxo de Execucao

### 1. Validar escopo

```
SE escopo nao informado:
  PERGUNTAR "Em qual empresa adicionar? (holding, utua, resolve, one-control, assiny)"

VALIDAR escopo em [holding, utua, resolve, one-control, assiny]
SE invalido:
  ERRO "Escopo invalido. Use: holding, utua, resolve, one-control, assiny"
```

### 2. Carregar vocabulario

```
LER ${CLAUDE_PLUGIN_ROOT}/schemas/vocabulario.yaml
EXTRAIR:
  - papeis_pessoa
  - niveis_skill
```

### 3. Coletar dados interativamente

```
PERGUNTAR em sequencia:

1. "Qual o nome completo?"
   -> nome

2. "Qual o email?"
   -> email

3. "Qual o papel?"
   LISTAR opcoes: cto, lider_tech, lider_negocio, dev_senior, dev_pleno, analista, pmo
   -> papel

4. "Quais skills e niveis? (formato: skill:nivel, skill:nivel)"
   EXEMPLO: "python:senior, google_ads:pleno, sql:senior"
   VALIDAR niveis em [junior, pleno, senior, especialista]
   -> skills[]

5. "Reporta a quem? (ID da pessoa ou vazio)"
   LER ./knowledge/[escopo]/pessoas/_index.md
   LISTAR pessoas existentes como opcoes
   -> reporta_a (opcional)
```

### 4. Gerar ID

```
id = slug(nome)
EXEMPLO: "Joao Silva" -> "joao-silva"
EXEMPLO: "Maria da Silva Santos" -> "maria-da-silva-santos"

REGRAS:
  - Lowercase
  - Espacos viram hifens
  - Remover acentos
  - Remover caracteres especiais
```

### 5. Verificar unicidade

```
LER ./knowledge/[escopo]/pessoas/_index.md
EXTRAIR entities[].id

SE id em entities[].id:
  ERRO "Pessoa ja existe com este ID: [id]"
  SUGERIR "Use /people get [id] para ver detalhes"
```

### 6. Criar arquivo da pessoa

```
CRIAR ./knowledge/[escopo]/pessoas/[id].md

FRONTMATTER:
---
type: pessoa
id: [id]
scope: [escopo]
version: 1
created_at: [data-atual]
updated_at: [data-atual]

nome: [nome]
email: [email]
papel: [papel]

skills:
  - nome: [skill1]
    nivel: [nivel1]
  - nome: [skill2]
    nivel: [nivel2]

iniciativas: []

reporta_a: [reporta_a ou null]
backup_de: []
backup_por: []
---

# [nome]

## Contexto

[Descricao a ser preenchida]

## Responsabilidades

- [A definir]

## Notas

- Criado em [data-atual]
```

### 7. Atualizar _index.md

```
LER ./knowledge/[escopo]/pessoas/_index.md

ATUALIZAR frontmatter:
  - Incrementar total
  - Adicionar em entities[]:
      - id: [id]
        nome: [nome]
        papel: [papel]
        skills: [lista de nomes de skills]
  - Atualizar by_papel.[papel] += 1
  - Adicionar novos skills em skills_cobertos (se nao existiam)
  - Atualizar updated_at

ESCREVER ./knowledge/[escopo]/pessoas/_index.md
```

### 8. Verificar gaps cobertos

```
LER ./knowledge/[escopo]/pessoas/_index.md
EXTRAIR skills_sem_backup

PARA cada skill em pessoa.skills:
  SE skill.nome em skills_sem_backup:
    INFO "Pessoa cobre gap de: [skill.nome]"
    REMOVER skill.nome de skills_sem_backup

SE houve mudancas em skills_sem_backup:
  ATUALIZAR _index.md
```

## Output Esperado

```
[OK] Pessoa criada: Joao Silva (joao-silva)

Arquivo: ./knowledge/utua/pessoas/joao-silva.md

Atualizado _index.md:
   * Total: 4 -> 5
   * Lider Tech: 1 -> 2

Observacoes:
   * Cobre gap de: google_ads
   * Ainda sem backup para: programatica
```

## Arquivos Modificados

- `./knowledge/[escopo]/pessoas/[id].md` - Criado
- `./knowledge/[escopo]/pessoas/_index.md` - Atualizado

## Validacoes

- Escopo deve ser valido
- Nome nao pode ser vazio
- Email deve ter formato valido
- Papel deve estar no vocabulario
- Skills devem ter nivel valido
- ID deve ser unico no escopo

## Rollback

Se ocorrer erro apos criar arquivo:
1. Remover arquivo criado
2. Reverter _index.md ao estado anterior
3. Informar usuario do erro
