---
command: "roadmap update $id $tipo"
description: Atualiza uma iniciativa existente (status, progresso, escopo, owner, nota). Comando interativo.
args:
  id:
    description: "ID da iniciativa (ex: UTUA-001)"
    required: true
  tipo:
    description: "Tipo de atualizacao: status, progresso, escopo, owner, nota"
    required: false
---

# /roadmap update

Atualiza uma iniciativa existente. Este comando eh interativo e adapta o fluxo ao tipo de atualizacao.

## Uso

```
/roadmap update [id] [tipo]
```

**Tipos de atualizacao:**
- `status` - Muda status (backlog -> em_andamento -> concluido)
- `progresso` - Atualiza percentual de conclusao
- `escopo` - Registra mudanca de escopo
- `owner` - Muda owner da iniciativa
- `nota` - Adiciona nota ao historico

**Exemplos:**
- `/roadmap update UTUA-001 status`
- `/roadmap update UTUA-001 progresso`
- `/roadmap update RESOLVE-002 owner`

## Fluxo de Execucao

### 1. Validar parametros

```
SE id nao informado:
  ERRO "Informe o ID da iniciativa"

SE tipo nao informado:
  PERGUNTAR "Qual tipo de atualizacao? (status, progresso, escopo, owner, nota)"

SE tipo nao em [status, progresso, escopo, owner, nota]:
  ERRO "Tipo invalido. Use: status, progresso, escopo, owner, nota"
```

### 2. Localizar e ler iniciativa

```
# Extrair empresa do ID
empresa = extrair_empresa_do_id(id)

caminho = ./knowledge/[empresa]/iniciativas/[id].md
SE arquivo nao existe:
  ERRO "Iniciativa [id] nao encontrada"

LER caminho
EXTRAIR frontmatter e conteudo
```

### 3. Executar atualizacao por tipo

---

#### Tipo: status

```
status_atual = iniciativa.status

MOSTRAR status atual
PERGUNTAR "Novo status?"
  Opcoes: backlog, em_andamento, pausado, concluido, cancelado

SE novo_status == status_atual:
  INFO "Status ja eh [status]. Nenhuma mudanca."
  RETORNAR

# Validacoes especificas
SE novo_status == "em_andamento" E status_atual == "backlog":
  SE nao iniciativa.owner:
    ALERTA "Iniciativa sem owner. Definir owner agora?"
    SE sim:
      # Coletar owner (ver tipo owner abaixo)

  # Definir data de inicio
  iniciativa.inicio = data_hoje

SE novo_status == "concluido":
  PERGUNTAR "Qual foi o resultado alcancado?"
  -> resultado (obrigatorio)

  PERGUNTAR "Quais foram os aprendizados?"
  -> aprendizados (obrigatorio)

  iniciativa.data_conclusao = data_hoje
  iniciativa.progresso = 100
  iniciativa.resultado = resultado
  iniciativa.aprendizados = aprendizados

SE novo_status == "cancelado":
  PERGUNTAR "Motivo do cancelamento?"
  -> motivo (obrigatorio)

  ADICIONAR ao historico: "[data] - Cancelada: [motivo]"

SE novo_status == "pausado":
  PERGUNTAR "Motivo da pausa?"
  -> motivo

  ADICIONAR ao historico: "[data] - Pausada: [motivo]"

# Atualizar
iniciativa.status = novo_status
iniciativa.updated_at = data_hoje
ADICIONAR ao historico: "[data] - Status: [status_atual] -> [novo_status]"
```

---

#### Tipo: progresso

```
progresso_atual = iniciativa.progresso

PERGUNTAR "Novo percentual de progresso? (0-100)"
-> novo_progresso

SE novo_progresso < 0 OU novo_progresso > 100:
  ERRO "Progresso deve ser entre 0 e 100"

SE novo_progresso == progresso_atual:
  INFO "Progresso ja eh [progresso]%. Nenhuma mudanca."
  RETORNAR

iniciativa.progresso = novo_progresso
iniciativa.updated_at = data_hoje
ADICIONAR ao historico: "[data] - Progresso: [progresso_atual]% -> [novo_progresso]%"

SE novo_progresso == 100 E iniciativa.status != "concluido":
  ALERTA "Progresso 100% mas status nao eh concluido. Deseja atualizar status?"
```

---

#### Tipo: escopo

```
PERGUNTAR "Descreva a mudanca de escopo:"
-> descricao_mudanca

PERGUNTAR "Impacto na previsao de conclusao?"
  Opcoes: nenhum, atraso_pequeno, atraso_grande, antecipacao
-> impacto_timeline

SE impacto_timeline != "nenhum":
  PERGUNTAR "Nova data de previsao?"
  -> nova_previsao
  iniciativa.previsao_fim = nova_previsao

iniciativa.updated_at = data_hoje
ADICIONAR ao historico: "[data] - Escopo alterado: [descricao_mudanca]"

# Verificar impacto em sinergias
SE iniciativa.sinergia_potencial nao vazio:
  INFO "Esta iniciativa tem sinergias. Mudanca de escopo pode afetar:"
  PARA cada sinergia:
    MOSTRAR empresa e como
  PERGUNTAR "Deseja executar analise de impacto? (/roadmap impacto)"
```

---

#### Tipo: owner

```
owner_atual = iniciativa.owner

# Listar pessoas disponiveis
LER ./knowledge/[empresa]/pessoas/_index.md
MOSTRAR lista de pessoas

PERGUNTAR "Novo owner?"
-> novo_owner

SE novo_owner nao existe em pessoas:
  ERRO "Pessoa [novo_owner] nao encontrada"

# Atualizar arquivo do owner anterior (se tinha)
SE owner_atual:
  LER ./knowledge/[empresa]/pessoas/[owner_atual].md
  REMOVER iniciativa.id de pessoa.iniciativas[]
  SALVAR arquivo

# Atualizar arquivo do novo owner
LER ./knowledge/[empresa]/pessoas/[novo_owner].md
ADICIONAR iniciativa.id em pessoa.iniciativas[]
SALVAR arquivo

iniciativa.owner = novo_owner
iniciativa.updated_at = data_hoje
ADICIONAR ao historico: "[data] - Owner: [owner_atual] -> [novo_owner]"
```

---

#### Tipo: nota

```
PERGUNTAR "Nota a adicionar:"
-> nota

iniciativa.updated_at = data_hoje
ADICIONAR ao historico: "[data] - Nota: [nota]"
```

---

### 4. Salvar iniciativa

```
SALVAR ./knowledge/[empresa]/iniciativas/[id].md
  COM frontmatter atualizado
  COM historico atualizado
```

### 5. Atualizar _index.md

```
ATUALIZAR ./knowledge/[empresa]/iniciativas/_index.md:
  - Atualizar entity correspondente (status, owner, progresso)
  - SE status mudou: atualizar by_status
  - SE owner mudou: atualizar alerts (remover "sem owner" se agora tem)
```

### 6. Verificar notificacoes

```
# Iniciativas dependentes
LER todas iniciativas que dependem desta
SE alguma estava bloqueada por esta E status == "concluido":
  INFO "Iniciativas desbloqueadas: [lista]"

# Sinergias
SE status == "concluido" E sinergia_potencial nao vazio:
  INFO "Sinergias identificadas. Comunicar empresas:"
  PARA cada sinergia:
    MOSTRAR empresa e como
```

## Output Esperado

```
+----------------------------------------------------+
| INICIATIVA ATUALIZADA: [ID]                        |
+----------------------------------------------------+
|                                                    |
| MUDANCA:                                           |
|   * [campo]: [valor_antigo] -> [valor_novo]        |
|   * [detalhes adicionais]                          |
|                                                    |
| NOTIFICACOES:                                      |
|   * [acao sugerida]                                |
|                                                    |
| Arquivos atualizados:                              |
|   * ./knowledge/[empresa]/iniciativas/[id].md      |
|   * ./knowledge/[empresa]/iniciativas/_index.md    |
|   * [outros arquivos se owner mudou]               |
|                                                    |
+----------------------------------------------------+
```

## Arquivos Lidos

```
./knowledge/[empresa]/iniciativas/[id].md
./knowledge/[empresa]/iniciativas/_index.md
./knowledge/[empresa]/pessoas/_index.md
./knowledge/[empresa]/pessoas/[pessoa].md (se owner)
```

## Arquivos Atualizados

```
./knowledge/[empresa]/iniciativas/[id].md
./knowledge/[empresa]/iniciativas/_index.md
./knowledge/[empresa]/pessoas/[owner_antigo].md (se mudou owner)
./knowledge/[empresa]/pessoas/[owner_novo].md (se mudou owner)
```

## Validacoes

- ID deve existir
- Tipo deve ser valido
- Novo status/progresso/owner devem ser validos
- Resultado e aprendizados obrigatorios ao concluir
- Motivo obrigatorio ao cancelar
