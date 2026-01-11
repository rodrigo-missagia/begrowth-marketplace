---
# CTO Be Growth Plugin Settings
# Copy this file to: .claude/cto-begrowth.local.md

enabled: true

# Hooks Configuration
hooks:
  post_write_validation: true      # Valida consistencia apos escrita
  stop_consistency_check: true     # Verifica pendencias ao finalizar
  session_start_check: true        # Verifica knowledge no inicio

# Default Company (utua, resolve, one-control, assiny, holding)
default_empresa: holding

# Output Format
output:
  use_boxes: true                  # Usar boxes ASCII para status
  show_alerts: true                # Mostrar alertas nos status
  verbose: false                   # Modo verbose (mais detalhes)

# Notification Level (info, warning, error)
notification_level: info

# Auto-update _index.md on entity changes
auto_index_update: true

# Language for messages (pt-BR, en)
language: pt-BR
---

# CTO Be Growth - Configuracao Local

Este arquivo configura o plugin CTO Be Growth para este projeto.

## Contexto do Projeto

Descreva aqui o contexto especifico deste projeto ou prioridades atuais:

-

## Notas

-
