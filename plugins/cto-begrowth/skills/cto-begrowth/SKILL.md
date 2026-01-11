---
name: cto-begrowth
description: Use this skill when the user asks about Be Growth group management, people management, initiatives tracking, ADRs, technical stack, synergies between companies, or any CTO-related tasks for UTUA, RESOLVE, ONE CONTROL, or ASSINY companies. Triggers on questions like "who works on", "what initiatives", "show roadmap", "people status", "gaps", "synergies", "ADR", "tech stack", "inicializar knowledge", "setup cto".
version: 1.0.0
---

# CTO Plugin - Be Growth

Plugin para gestao de pessoas, iniciativas e decisoes tecnicas do grupo Be Growth.

## Empresas do Grupo

```
BE GROWTH (Holding)
├── UTUA        → Arbitragem de trafego e publisher
├── RESOLVE     → Compra de creditos sucessorios
├── ONE CONTROL → DMP + CDP + Engajamento
└── ASSINY      → Checkout e subadquirencia
```

## Arquitetura de Dados

O knowledge fica **fora do plugin**, na raiz do projeto do usuario:

```
projeto/                          # Projeto do usuario
├── knowledge/                    # DADOS - gerenciados pelo plugin
│   ├── holding/
│   │   ├── _index.md
│   │   ├── stack.md
│   │   ├── sinergias.md
│   │   ├── pessoas/
│   │   └── adrs/
│   ├── utua/
│   │   ├── _index.md
│   │   ├── contexto.md
│   │   ├── pessoas/
│   │   ├── iniciativas/
│   │   └── adrs/
│   ├── resolve/
│   ├── one-control/
│   └── assiny/
│
└── cto-plugin/                   # PLUGIN - apenas logica
    ├── skills/
    ├── schemas/
    ├── commands/
    └── workflows/
```

**CRITICO:** Todos os paths de knowledge sao relativos a raiz do projeto, NAO a pasta do plugin!

- CORRETO: `./knowledge/holding/` (a partir da raiz do projeto)
- ERRADO: `cto-plugin/knowledge/` ou `${CLAUDE_PLUGIN_ROOT}/knowledge/`

Ao usar comandos Bash (ls, mkdir, etc.), certifique-se de que o working directory seja a raiz do projeto.

## Inicializacao do Knowledge

Se a pasta `knowledge/` nao existir, o plugin deve criar a estrutura completa com templates.

Para inicializar manualmente, use:
- "inicializar knowledge" ou "setup cto"

A estrutura criada inclui:
- `_index.md` com metadados em cada diretorio
- `contexto.md` com pilares, metas e dores por empresa
- `stack.md` e `sinergias.md` na holding
- Templates de pessoa, iniciativa e ADR nos _index.md

## Comandos Disponiveis

### People - Gestao de Pessoas
- `/people status [empresa|holding|all]` - Visao de pessoas e capacidades
- `/people add [empresa]` - Adicionar pessoa
- `/people get [id]` - Buscar pessoa por ID
- `/people gap [skill]` - Analisar gap de skill
- `/people assign [pessoa] [iniciativa]` - Alocar pessoa em iniciativa

### Roadmap - Gestao de Projetos
- `/roadmap status [empresa|all]` - Visao de iniciativas
- `/roadmap add [empresa]` - Adicionar iniciativa
- `/roadmap get [id]` - Buscar iniciativa por ID
- `/roadmap update [id] [tipo]` - Atualizar iniciativa
- `/roadmap priorize [empresa|all]` - Priorizar backlog
- `/roadmap sinergia [item]` - Analisar sinergias
- `/roadmap impacto [descricao]` - Analisar impacto de mudanca
- `/roadmap adr [escopo]` - Criar ADR

### Inventario - Gestao de Recursos
- `/inventario status [empresa|all]` - Visao de stack
- `/inventario add [tipo] [escopo]` - Adicionar item
- `/inventario gap` - Listar gaps
- `/inventario avaliar [tech]` - Avaliar tecnologia

## Principios de Operacao

1. **Knowledge externo** - Dados ficam em `./knowledge/` na raiz do projeto, nao no plugin
2. **Ler _index.md primeiro** - Cada diretorio tem um _index.md que funciona como tabela do banco de dados
3. **Frontmatter como metadados** - Todos os arquivos .md tem frontmatter YAML estruturado
4. **Validar contra schemas** - Usar schemas em `${CLAUDE_PLUGIN_ROOT}/schemas/` para validar
5. **Vocabulario controlado** - Usar valores de `${CLAUDE_PLUGIN_ROOT}/schemas/vocabulario.yaml`
6. **Manter consistencia** - Atualizar _index.md quando criar/modificar entidades

## Resolucao de Paths

**IMPORTANTE:** O working directory para comandos deve ser a **raiz do projeto do usuario**, NAO a pasta do plugin.

```
# CORRETO - Caminhos para DADOS (knowledge):
# Working directory: /path/to/projeto (raiz do projeto)
./knowledge/[escopo]/[tipo]/[arquivo].md

# ERRADO - Nunca usar caminho dentro do plugin:
# ${CLAUDE_PLUGIN_ROOT}/knowledge/  <- INCORRETO!
# cto-plugin/knowledge/             <- INCORRETO!

# Para arquivos do PLUGIN (schemas, templates):
${CLAUDE_PLUGIN_ROOT}/schemas/vocabulario.yaml
${CLAUDE_PLUGIN_ROOT}/schemas/pessoa.schema.yaml
```

**Regra:** Ao executar comandos Bash ou verificar existencia de pastas knowledge, sempre use o caminho relativo `./knowledge/` a partir da raiz do projeto, nunca a partir da pasta do plugin.

## Leitura Inteligente de Arquivos

Para consultas rapidas, ler apenas _index.md:
```
LER ./knowledge/[escopo]/[tipo]/_index.md
EXTRAIR: total, by_status, health, alerts
```

Para detalhes, ler arquivo individual:
```
LER ./knowledge/[escopo]/[tipo]/[id].md
EXTRAIR: frontmatter completo + conteudo
```

## Formato de Resposta

Usar boxes para status:
```
┌────────────────────────────────────────┐
│ TITULO                                 │
├────────────────────────────────────────┤
│ Conteudo organizado                    │
│   • Item 1                             │
│   • Item 2                             │
│                                        │
│ ⚠️ ALERTAS:                            │
│   • Alerta 1                           │
└────────────────────────────────────────┘
```

## Skills Analiticos

O plugin inclui 4 skills analiticos para analises avancadas:

### sinergias
Identifica oportunidades de compartilhamento entre empresas.
- **Quando usar:** Ao criar iniciativa, avaliar tecnologia, criar ADR
- **Arquivo:** `${CLAUDE_PLUGIN_ROOT}/skills/sinergias/SKILL.md`
- **Output:** Analise por empresa, o que compartilhar vs isolar, ordem sugerida

### priorizacao
Ordena iniciativas do backlog por criterios objetivos.
- **Quando usar:** `/roadmap priorize`
- **Arquivo:** `${CLAUDE_PLUGIN_ROOT}/skills/priorizacao/SKILL.md`
- **Criterios:** Alinhamento pilares (30%), Dor critica (25%), Habilita outras (15%), Sinergia (15%), Viabilidade (15%)
- **Output:** Ranking com scores, agrupamentos, bloqueios

### gaps
Identifica capacidades faltantes e propoe solucoes.
- **Quando usar:** `/people gap`, `/inventario gap`, criacao de iniciativas
- **Arquivo:** `${CLAUDE_PLUGIN_ROOT}/skills/gaps/SKILL.md`
- **Tipos:** skill_ausente, skill_sem_backup, skill_em_empresa_errada, ferramenta_sem_owner
- **Output:** Situacao, candidatos a treinamento, opcoes (contratar/treinar/terceirizar)

### impacto
Avalia consequencias de mudancas propostas.
- **Quando usar:** `/roadmap impacto`, depreciar ADR, mudar stack, remover pessoa
- **Arquivo:** `${CLAUDE_PLUGIN_ROOT}/skills/impacto/SKILL.md`
- **Tipos:** tecnologia, adr, pessoa, iniciativa, estrutura
- **Output:** Criticidade, dependencias, riscos, recomendacoes

## Arquivos de Referencia do Plugin

- `${CLAUDE_PLUGIN_ROOT}/schemas/vocabulario.yaml` - Valores permitidos para campos
- `${CLAUDE_PLUGIN_ROOT}/schemas/pessoa.schema.yaml` - Estrutura de arquivo de pessoa
- `${CLAUDE_PLUGIN_ROOT}/schemas/iniciativa.schema.yaml` - Estrutura de arquivo de iniciativa
- `${CLAUDE_PLUGIN_ROOT}/schemas/adr.schema.yaml` - Estrutura de arquivo de ADR
- `${CLAUDE_PLUGIN_ROOT}/schemas/index.schema.yaml` - Estrutura de _index.md
- `${CLAUDE_PLUGIN_ROOT}/skills/sinergias/SKILL.md` - Skill de analise de sinergias
- `${CLAUDE_PLUGIN_ROOT}/skills/priorizacao/SKILL.md` - Skill de priorizacao
- `${CLAUDE_PLUGIN_ROOT}/skills/gaps/SKILL.md` - Skill de analise de gaps
- `${CLAUDE_PLUGIN_ROOT}/skills/impacto/SKILL.md` - Skill de analise de impacto
