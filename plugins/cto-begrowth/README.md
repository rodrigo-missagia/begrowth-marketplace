# CTO Plugin - Be Growth

Plugin de gestao para CTO do grupo Be Growth, permitindo gerenciar pessoas, iniciativas, ADRs e sinergias entre as 4 empresas do grupo.

## Empresas do Grupo

```
BE GROWTH (Holding)
├── UTUA        → Arbitragem de trafego e publisher
├── RESOLVE     → Compra de creditos sucessorios
├── ONE CONTROL → DMP + CDP + Engajamento
└── ASSINY      → Checkout e subadquirencia
```

## Arquitetura

O plugin separa **logica** de **dados**:

```
projeto/                    # <- RAIZ DO PROJETO (working directory)
├── knowledge/              # DADOS - NA RAIZ, fora do plugin!
│   ├── holding/
│   ├── utua/
│   ├── resolve/
│   ├── one-control/
│   └── assiny/
│
└── cto-plugin/             # PLUGIN - apenas logica
    ├── .claude-plugin/
    ├── skills/
    ├── schemas/
    ├── commands/
    ├── workflows/
    └── templates/
```

**CRITICO:** A pasta `knowledge/` fica na **RAIZ DO PROJETO**, nao dentro do plugin!

- CORRETO: `./knowledge/` (relativo a raiz do projeto)
- ERRADO: `cto-plugin/knowledge/` (dentro do plugin)

## Instalacao

```bash
# Testar localmente:
claude --plugin-dir ./cto-plugin

# Ou copiar para plugins globais:
cp -r cto-plugin ~/.claude/plugins/
```

## Inicializacao

Na primeira execucao, execute o comando de setup:

```
/cto setup
```

Isso cria:

- Arquivo de configuracoes em `.claude/cto-begrowth.local.md`
- Estrutura de knowledge em `./knowledge/`

## Configuracoes

O plugin usa o arquivo `.claude/cto-begrowth.local.md` para configuracoes por projeto.

### Criar/Editar Settings

```bash
/cto setup      # Criar configuracao inicial (interativo)
/cto settings   # Ver/editar configuracoes
```

### Opcoes Disponiveis

```yaml
enabled: true                    # Habilitar/desabilitar plugin

hooks:
  post_write_validation: true    # Validar consistencia apos escrita
  stop_consistency_check: true   # Verificar pendencias ao finalizar
  session_start_check: true      # Verificar knowledge no inicio

default_empresa: holding         # Empresa padrao (holding, utua, resolve, one-control, assiny)

output:
  use_boxes: true                # Usar boxes ASCII para status
  show_alerts: true              # Mostrar alertas
  verbose: false                 # Modo verbose

notification_level: info         # Nivel de notificacao (info, warning, error)
auto_index_update: true          # Atualizar _index.md automaticamente
language: pt-BR                  # Idioma (pt-BR, en)
```

### Desabilitar Temporariamente

Para desabilitar o plugin sem remover o arquivo:

```yaml
enabled: false
```

**Importante:** Mudancas nas configuracoes requerem restart do Claude Code.

### Gitignore

Adicione ao `.gitignore`:

```
.claude/*.local.md
```

## Estrutura do Plugin

```
cto-plugin/
├── .claude-plugin/
│   └── plugin.json           # Manifest
├── skills/
│   └── cto-begrowth/
│       └── SKILL.md          # Entry point e documentacao
├── schemas/                   # Validacao de dados
│   ├── vocabulario.yaml      # Valores permitidos
│   ├── pessoa.schema.yaml
│   ├── iniciativa.schema.yaml
│   ├── adr.schema.yaml
│   └── index.schema.yaml
├── templates/                 # Templates para inicializacao
├── commands/                  # Comandos (em desenvolvimento)
└── workflows/                 # Hooks (em desenvolvimento)
```

## Comandos

### People - Gestao de Pessoas (planejado)

- `/people status [empresa|all]` - Visao de pessoas
- `/people add [empresa]` - Adicionar pessoa
- `/people get [id]` - Buscar pessoa
- `/people gap [skill]` - Analisar gap
- `/people assign [pessoa] [iniciativa]` - Alocar pessoa

### Roadmap - Gestao de Projetos (implementado)

- `/roadmap status [empresa|all]` - Visao de iniciativas e progresso
- `/roadmap add [empresa]` - Adicionar iniciativa (interativo)
- `/roadmap get [id]` - Buscar detalhes de iniciativa
- `/roadmap update [id] [tipo]` - Atualizar iniciativa (interativo)
- `/roadmap priorize [empresa|all]` - Priorizar backlog
- `/roadmap sinergia [item]` - Analisar sinergias entre empresas
- `/roadmap impacto [descricao]` - Analisar impacto de mudanca (interativo)
- `/roadmap adr [escopo]` - Criar nova ADR (interativo)

### Inventario - Gestao de Recursos (planejado)

- `/inventario status [empresa|all]` - Visao de stack
- `/inventario add [tipo]` - Adicionar item
- `/inventario gap` - Listar gaps
- `/inventario avaliar [tech]` - Avaliar tecnologia

## Status de Desenvolvimento

- [x] Fase 1: Estrutura Base e Schemas
- [x] Fase 2: Knowledge Base (Holding)
- [x] Fase 3: Knowledge Base (Empresas)
- [ ] Fase 4: Commands (People)
- [x] Fase 5: Commands (Roadmap)
- [ ] Fase 6: Commands (Inventario)
- [ ] Fase 7: Skills Analiticos
- [ ] Fase 8: Workflows e Hooks
- [ ] Fase 9: Integracao e Testes

## Principios de Design

1. **Separacao dados/logica** - Knowledge externo ao plugin
2. **Contexto > Controle** - Dar contexto certo para decisoes
3. **Simplicidade operacional** - Gestao de tarefas, nao sprints
4. **Consistencia via workflows** - Hooks garantem propagacao
5. **Separacao Holding x Empresas** - Clareza sobre compartilhado vs especifico
