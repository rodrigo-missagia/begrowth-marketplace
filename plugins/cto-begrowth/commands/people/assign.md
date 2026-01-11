---
command: "people assign $pessoa $iniciativa $papel"
description: Aloca pessoa em iniciativa com validacao de carga e skills.
args:
  pessoa:
    description: "ID da pessoa (ex: joao-silva)"
    required: true
  iniciativa:
    description: "ID da iniciativa (ex: UTUA-001)"
    required: true
  papel:
    description: "Papel: owner ou contribuidor (default: contribuidor)"
    required: false
---

# /people assign

## Descricao

Registra alocacao de pessoa em iniciativa, validando carga de trabalho e match de skills.

## Uso

```
/people assign [pessoa] [iniciativa] [papel]
```

**Papeis validos:** `owner` | `contribuidor`

**Exemplos:**
- `/people assign joao-silva UTUA-001 owner`
- `/people assign maria-santos UTUA-001 contribuidor`
- `/people assign pedro-oliveira ONE-CONTROL-001`

## Fluxo de Execucao

### 1. Validar parametros

```
SE pessoa nao informada:
  ERRO "ID da pessoa e obrigatorio"
  EXEMPLO "/people assign joao-silva UTUA-001 owner"

SE iniciativa nao informada:
  ERRO "ID da iniciativa e obrigatorio"
  EXEMPLO "/people assign joao-silva UTUA-001 owner"

SE papel nao informado:
  papel = "contribuidor"  # default
```

### 2. Validar pessoa existe

```
pessoa_encontrada = null
pessoa_escopo = null

PARA cada escopo em [holding, utua, resolve, one-control, assiny]:
  LER ./knowledge/[escopo]/pessoas/_index.md

  PARA cada entity em entities:
    SE entity.id == pessoa:
      pessoa_encontrada = entity
      pessoa_escopo = escopo
      BREAK

SE pessoa_encontrada == null:
  ERRO "Pessoa nao encontrada: [pessoa]"
  SUGERIR "Use /people status para ver todas as pessoas"
```

### 3. Validar iniciativa existe

```
iniciativa_encontrada = null
iniciativa_escopo = null

# Extrair escopo do ID da iniciativa
# UTUA-001 -> utua
# ONE-CONTROL-001 -> one-control
# RESOLVE-001 -> resolve
# ASSINY-001 -> assiny

iniciativa_escopo = extrair_escopo_do_id(iniciativa)

LER ./knowledge/[iniciativa_escopo]/iniciativas/_index.md

PARA cada entity em entities:
  SE entity.id == iniciativa:
    iniciativa_encontrada = entity
    BREAK

SE iniciativa_encontrada == null:
  ERRO "Iniciativa nao encontrada: [iniciativa]"
  SUGERIR "Use /roadmap status para ver todas as iniciativas"
```

### 4. Ler dados completos

```
LER ./knowledge/[pessoa_escopo]/pessoas/[pessoa].md
EXTRAIR:
  - skills[]
  - iniciativas[]

LER ./knowledge/[iniciativa_escopo]/iniciativas/[iniciativa].md
EXTRAIR:
  - nome
  - skills_necessarios
  - owner
  - contributors[]
```

### 5. Verificar carga atual da pessoa

```
count_iniciativas = count(pessoa.iniciativas)

SE count_iniciativas >= 3:
  ALERTA "[!] Pessoa ja em [count_iniciativas] iniciativas (limite recomendado: 3)"
  PERGUNTAR "Confirma alocacao mesmo assim? (s/n)"

  SE resposta != "s":
    CANCELAR "Alocacao cancelada pelo usuario"
```

### 6. Verificar match de skills

```
skills_pessoa = [s.nome PARA s em pessoa.skills]
skills_necessarios = iniciativa.skills_necessarios

match = intersecao(skills_pessoa, skills_necessarios)
match_percent = (count(match) / count(skills_necessarios)) * 100

SE match_percent < 50:
  ALERTA "[!] Match de skills baixo: [match_percent]%"

  skills_faltantes = diferenca(skills_necessarios, skills_pessoa)
  INFO "Skills faltantes: [skills_faltantes]"

  PERGUNTAR "Continuar mesmo assim? (s/n)"

  SE resposta != "s":
    CANCELAR "Alocacao cancelada pelo usuario"
```

### 7. Verificar se ja esta alocado

```
alocacao_existente = null

PARA cada aloc em pessoa.iniciativas:
  SE aloc.id == iniciativa:
    alocacao_existente = aloc
    BREAK

SE alocacao_existente != null:
  SE alocacao_existente.papel == papel:
    INFO "Pessoa ja alocada nesta iniciativa com mesmo papel"
    SAIR

  SE alocacao_existente.papel != papel:
    INFO "Atualizando papel de [alocacao_existente.papel] para [papel]"
    # Continuar para atualizar
```

### 8. Verificar substituicao de owner

```
SE papel == "owner":
  SE iniciativa.owner != null E iniciativa.owner != pessoa:
    owner_anterior = iniciativa.owner
    ALERTA "[!] Substituindo owner anterior: [owner_anterior]"

    # Atualizar arquivo do owner anterior
    LER ./knowledge/[escopo_owner]/pessoas/[owner_anterior].md
    REMOVER iniciativa de owner_anterior.iniciativas
    ESCREVER arquivo atualizado
```

### 9. Atualizar arquivo da pessoa

```
SE alocacao_existente == null:
  # Nova alocacao
  ADICIONAR em pessoa.iniciativas:
    - id: [iniciativa]
      papel: [papel]
SENAO:
  # Atualizar papel existente
  alocacao_existente.papel = papel

ATUALIZAR updated_at

ESCREVER ./knowledge/[pessoa_escopo]/pessoas/[pessoa].md
```

### 10. Atualizar arquivo da iniciativa

```
SE papel == "owner":
  iniciativa.owner = pessoa
  # Remover de contributors se estava la
  REMOVER pessoa de iniciativa.contributors (se existir)
SENAO:
  # Adicionar como contribuidor
  SE pessoa nao em iniciativa.contributors:
    ADICIONAR pessoa em iniciativa.contributors

ATUALIZAR updated_at

ESCREVER ./knowledge/[iniciativa_escopo]/iniciativas/[iniciativa].md
```

### 11. Atualizar _index.md da iniciativa

```
LER ./knowledge/[iniciativa_escopo]/iniciativas/_index.md

PARA cada entity em entities:
  SE entity.id == iniciativa:
    SE papel == "owner":
      entity.owner = pessoa
    BREAK

ATUALIZAR updated_at

ESCREVER ./knowledge/[iniciativa_escopo]/iniciativas/_index.md
```

### 12. Apresentar resultado

## Output Esperado

```
[OK] Alocacao registrada

Joao Silva -> UTUA-001 (Owner)

[!] ALERTAS:
   * Pessoa ja em 3 iniciativas (limite recomendado)
   * Skill match: 80% (falta: temporal)

ARQUIVOS ATUALIZADOS:
   * ./knowledge/utua/pessoas/joao-silva.md
   * ./knowledge/utua/iniciativas/UTUA-001.md
   * ./knowledge/utua/iniciativas/_index.md
```

## Arquivos Modificados

- `./knowledge/[pessoa_escopo]/pessoas/[pessoa].md` - Atualizado
- `./knowledge/[iniciativa_escopo]/iniciativas/[iniciativa].md` - Atualizado
- `./knowledge/[iniciativa_escopo]/iniciativas/_index.md` - Atualizado
- `./knowledge/[escopo_owner]/pessoas/[owner_anterior].md` - Se houve substituicao

## Validacoes

- Pessoa deve existir
- Iniciativa deve existir
- Papel deve ser "owner" ou "contribuidor"
- Verificar sobrecarga (mais de 3 iniciativas)
- Verificar match de skills (alerta se < 50%)

## Alertas Emitidos

- Pessoa sobrecarregada (>3 iniciativas)
- Match de skills baixo (<50%)
- Substituicao de owner
- Pessoa de empresa diferente da iniciativa

## Rollback

Se ocorrer erro durante atualizacao:
1. Reverter arquivo da pessoa
2. Reverter arquivo da iniciativa
3. Reverter _index.md
4. Reverter arquivo do owner anterior (se aplicavel)
5. Informar usuario do erro
