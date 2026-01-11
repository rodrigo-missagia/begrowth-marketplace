# Be Growth Plugin Marketplace

Marketplace de plugins para Claude Code do grupo Be Growth.

## Plugins Disponíveis

### cto-begrowth

Plugin de gestão CTO para o grupo Be Growth.

**Funcionalidades:**
- Gestão de pessoas e skills
- Roadmap de iniciativas
- ADRs (Architecture Decision Records)
- Análise de sinergias entre empresas
- Inventário tecnológico

**Empresas suportadas:**
- UTUA - Arbitragem de tráfego e publisher
- RESOLVE - Compra de créditos sucessórios
- ONE CONTROL - DMP + CDP + Engajamento
- ASSINY - Checkout e subadquirência

## Instalação

### Adicionar o Marketplace

```bash
/marketplace add begrowth-plugins github:SEU_USUARIO/begrowth-marketplace
```

### Instalar o Plugin

```bash
/plugin install cto-begrowth@begrowth-plugins
```

## Uso Local (Desenvolvimento)

```bash
claude --plugin-dir /caminho/para/begrowth-marketplace/plugins/cto-begrowth
```

## Comandos Disponíveis

### People
- `/people/status` - Visão de pessoas e capacidades
- `/people/add` - Adicionar pessoa
- `/people/get` - Buscar pessoa
- `/people/gap` - Analisar gaps de skills
- `/people/assign` - Alocar pessoa em iniciativa

### Roadmap
- `/roadmap/status` - Visão de iniciativas
- `/roadmap/add` - Adicionar iniciativa
- `/roadmap/get` - Buscar iniciativa
- `/roadmap/update` - Atualizar iniciativa
- `/roadmap/priorize` - Priorizar backlog
- `/roadmap/sinergia` - Analisar sinergias
- `/roadmap/impacto` - Analisar impacto
- `/roadmap/adr` - Criar ADR

### Inventário
- `/inventario/status` - Visão de stack
- `/inventario/add` - Adicionar item
- `/inventario/gap` - Listar gaps
- `/inventario/avaliar` - Avaliar tecnologia

### CTO
- `/cto/setup` - Configurar plugin
- `/cto/settings` - Gerenciar configurações

## Agentes

### text-parser

Agente inteligente para importação em massa. Recebe texto livre e automaticamente identifica e cadastra:
- **Pessoas**: Nomes, cargos, skills, emails
- **Iniciativas**: Projetos, problemas, objetivos
- **Tecnologias**: Ferramentas, linguagens, frameworks

**Uso:**
```
Equipe da Assiny:
- João Silva - dev senior, skills: python, react
- Maria Santos - analista de dados, skills: sql, bigquery

Projetos Q1:
1. Dashboard de métricas - visibilidade real-time
2. Automação de reports - relatórios automáticos

Stack: Python, FastAPI, PostgreSQL, Redis
```

O agente irá:
1. Identificar o escopo (Assiny)
2. Extrair 2 pessoas, 2 iniciativas e 4 tecnologias
3. Confirmar com você antes de cadastrar
4. Executar os cadastros e reportar resultado

**Trigger phrases:** "importar lista", "cadastrar pessoas", "processar texto", "bulk import", "entrada em massa"

## Licença

MIT License - Be Growth 2025
