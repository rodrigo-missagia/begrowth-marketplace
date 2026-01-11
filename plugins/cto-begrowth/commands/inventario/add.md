---
command: "inventario add $tipo $escopo"
description: Adiciona novo item ao inventario (tech, ferramenta, fornecedor, integracao).
args:
  tipo:
    description: "Tipo: tech, ferramenta, fornecedor, ou integracao"
    required: true
  escopo:
    description: "Escopo: holding, utua, resolve, one-control, ou assiny"
    required: false
---

# /inventario add

## Descricao

Adiciona novo item ao inventario (tecnologia, ferramenta, fornecedor ou integracao).

**IMPORTANTE:** A pasta `knowledge/` fica na RAIZ DO PROJETO, nao dentro do plugin!

- CORRETO: `./knowledge/holding/stack.md` (a partir da raiz do projeto)
- ERRADO: `cto-plugin/knowledge/` ou qualquer caminho dentro do plugin

## Uso
```
/inventario add [tipo] [escopo]
```

**Tipos:**
- `tech` - Tecnologia/linguagem/framework
- `ferramenta` - Ferramenta SaaS/software
- `fornecedor` - Fornecedor/parceiro
- `integracao` - Integracao entre sistemas

**Escopos:**
- `holding` - Compartilhado entre empresas
- `utua` | `resolve` | `one-control` | `assiny` - Especifico da empresa

## Fluxo de Execucao

### 1. Verificar se ja existe
```
LER ./knowledge/holding/stack.md
SE item similar existe:
  ALERTA "Similar existente: [nome]"
  PERGUNTAR "Continuar mesmo assim?"
```

### 2. Coletar dados
```
PERGUNTAR por tipo:

tech:
  - Nome da tecnologia?
  - Categoria? (data, backend, frontend, ai, observabilidade)
  - Status? (homologado, avaliando)
  - Responsavel? (pessoa ou "nao definido")
  - ADR relacionada?

ferramenta:
  - Nome da ferramenta?
  - Categoria? (crm, projeto, comunicacao, analytics)
  - Status? (em uso, avaliando)
  - Custo mensal? (opcional)
  - Responsavel?

fornecedor:
  - Nome do fornecedor?
  - Servico prestado?
  - Contrato ate?
  - Valor mensal?
  - Responsavel pelo relacionamento?

integracao:
  - Sistema origem?
  - Sistema destino?
  - Tipo? (api, webhook, batch, realtime)
  - Status? (ativo, planejado, depreciado)
  - Responsavel?
```

### 3. Avaliar sinergia
```
SE escopo != holding:
  PERGUNTAR "Esta tecnologia pode beneficiar outras empresas?"
  SE sim:
    SUGERIR "Considere adicionar ao holding"
```

### 4. Atualizar stack.md
```
SE tipo == "tech":
  ADICIONAR a secao correspondente em ./knowledge/holding/stack.md
  ATUALIZAR frontmatter (by_status, total)
```

### 5. Verificar responsavel
```
SE responsavel informado:
  SE responsavel nao existe em ./knowledge/[escopo]/pessoas/:
    ALERTA "Pessoa nao encontrada"
  SENAO:
    VERIFICAR se pessoa tem skill compativel
```

## Output Esperado

```
OK Tecnologia adicionada: Redis

Arquivo: ./knowledge/holding/stack.md

DETALHES:
   * Categoria: Backend (cache)
   * Status: avaliando
   * Responsavel: joao-silva
   * ADR: -

VERIFICACOES:
   * Similar existente: nenhum
   * Responsavel tem skill: OK (redis: junior)

SINERGIAS:
   * UTUA: Cache de campanhas
   * ASSINY: Cache de sessoes de checkout
   * ONE CONTROL: Cache de segmentos

PROXIMOS PASSOS:
   * Criar ADR se for homologar
   * Definir criterios de avaliacao
```

## Validacoes

### Categorias de Tecnologia Validas
- `data` - Data Platform (BigQuery, Pub/Sub, etc)
- `backend` - Backend (Python, FastAPI, etc)
- `frontend` - Frontend (React, Next.js, etc)
- `ai` - AI/ML (LangChain, OpenAI, etc)
- `observabilidade` - Observabilidade (Grafana, Prometheus, etc)
- `infra` - Infraestrutura (GCP, Docker, etc)

### Categorias de Ferramenta Validas
- `crm` - CRM (HubSpot, Salesforce, etc)
- `projeto` - Gestao de Projetos (ClickUp, Jira, etc)
- `comunicacao` - Comunicacao (Slack, Discord, etc)
- `analytics` - Analytics (GA, Mixpanel, etc)
- `design` - Design (Figma, etc)
- `documentacao` - Documentacao (Notion, Confluence, etc)

## Arquivos Modificados

- `./knowledge/holding/stack.md` - Adicionar item a lista
- `./knowledge/[escopo]/pessoas/[id].md` - Verificar responsavel (somente leitura)

## Hooks Acionados

- Verificacao de duplicatas
- Analise de sinergias entre empresas
- Sugestao de ADR quando necessario
