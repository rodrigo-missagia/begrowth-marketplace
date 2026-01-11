---
command: "cto setup"
description: Inicializa o plugin CTO Be Growth criando arquivo de settings e estrutura knowledge
allowed-tools: ["Read", "Write", "Glob", "Bash", "AskUserQuestion"]
---

# /cto setup - Inicializacao do Plugin

Este comando configura o plugin CTO Be Growth para o projeto atual.

**IMPORTANTE:** A pasta `knowledge/` deve ser criada na RAIZ DO PROJETO, nao dentro do plugin!

- CORRETO: `./knowledge/` (a partir da raiz do projeto)
- ERRADO: `cto-plugin/knowledge/` ou qualquer caminho dentro do plugin

## Passos

### 1. Verificar se ja existe configuracao

Verificar se existe `.claude/cto-begrowth.local.md`. Se existir, perguntar se deseja sobrescrever.

### 2. Perguntar preferencias

Use AskUserQuestion para coletar:

**Pergunta 1: Empresa padrao**
- Header: "Empresa"
- Options:
  - `holding` - Be Growth (holding)
  - `utua` - UTUA (trafego/publisher)
  - `resolve` - RESOLVE (creditos)
  - `one-control` - ONE CONTROL (DMP/CDP)
  - `assiny` - ASSINY (checkout)

**Pergunta 2: Nivel de validacao**
- Header: "Validacao"
- Options:
  - `full` - Todas as validacoes ativas (Recomendado)
  - `minimal` - Apenas validacao de sessao
  - `off` - Sem validacoes automaticas

**Pergunta 3: Idioma**
- Header: "Idioma"
- Options:
  - `pt-BR` - Portugues (Recomendado)
  - `en` - English

### 3. Criar arquivo de settings

Criar diretorio `.claude/` se nao existir.

Criar `.claude/cto-begrowth.local.md` com as preferencias coletadas:

```markdown
---
enabled: true

hooks:
  post_write_validation: [true se full, false caso contrario]
  stop_consistency_check: [true se full, false caso contrario]
  session_start_check: [true se full ou minimal]

default_empresa: [empresa escolhida]

output:
  use_boxes: true
  show_alerts: true
  verbose: false

notification_level: info
auto_index_update: [true se full]
language: [idioma escolhido]
---

# CTO Be Growth - Configuracao Local

Configuracao criada em [data atual].

## Contexto do Projeto

-

## Notas

-
```

### 4. Verificar/Criar estrutura knowledge

Verificar se existe `./knowledge/`. Se nao existir, perguntar se deseja criar.

Se sim, criar estrutura basica:
- `knowledge/holding/` com `_index.md`
- `knowledge/[empresa-padrao]/` com `_index.md` e `contexto.md`

Usar templates de `${CLAUDE_PLUGIN_ROOT}/templates/` se disponiveis.

### 5. Adicionar ao .gitignore

Verificar se `.gitignore` existe. Se sim, verificar se ja tem `.claude/*.local.md`.
Se nao tiver, adicionar a linha.

### 6. Confirmar

Informar ao usuario:
- Arquivo de settings criado em `.claude/cto-begrowth.local.md`
- Estrutura knowledge em `./knowledge/` (se criada)
- Lembrar que mudancas nas settings requerem restart do Claude Code
- Listar comandos disponiveis: `/people`, `/roadmap`, `/inventario`
