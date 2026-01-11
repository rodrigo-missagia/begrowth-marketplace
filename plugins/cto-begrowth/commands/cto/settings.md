---
command: "cto settings"
description: Exibe ou edita as configuracoes do plugin CTO Be Growth
allowed-tools: ["Read", "Edit", "AskUserQuestion"]
---

# /cto settings - Gerenciar Configuracoes

Este comando permite visualizar e editar as configuracoes do plugin.

## Passos

### 1. Verificar se existe arquivo de settings

Verificar se existe `.claude/cto-begrowth.local.md`.

Se nao existir, informar:
```
Settings nao encontrado. Execute '/cto setup' para criar.
```

### 2. Ler e exibir configuracoes atuais

Ler o arquivo e exibir em formato amigavel:

```
┌────────────────────────────────────────┐
│ CTO Be Growth - Settings               │
├────────────────────────────────────────┤
│ Status: ✅ Habilitado                  │
│                                        │
│ HOOKS                                  │
│   Post-write validation: ✅            │
│   Stop consistency check: ✅           │
│   Session start check: ✅              │
│                                        │
│ PREFERENCIAS                           │
│   Empresa padrao: holding              │
│   Idioma: pt-BR                        │
│   Auto-update index: ✅                │
│                                        │
│ OUTPUT                                 │
│   Boxes: ✅                            │
│   Alertas: ✅                          │
│   Verbose: ❌                          │
└────────────────────────────────────────┘
```

### 3. Perguntar se deseja editar

Use AskUserQuestion:
- Header: "Acao"
- Options:
  - `view` - Apenas visualizar (feito)
  - `edit` - Editar configuracoes
  - `disable` - Desabilitar plugin temporariamente
  - `enable` - Habilitar plugin

### 4. Se editar, perguntar qual setting

Use AskUserQuestion com multiSelect:
- Header: "Editar"
- Options:
  - `hooks` - Configuracoes de hooks
  - `empresa` - Empresa padrao
  - `output` - Formato de saida
  - `language` - Idioma

### 5. Aplicar mudancas

Usar Edit tool para modificar o frontmatter do arquivo.

### 6. Lembrar sobre restart

Informar: "Mudancas aplicadas. Reinicie o Claude Code para que as novas configuracoes de hooks entrem em vigor."
