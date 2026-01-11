---
name: text-parser
description: Use this skill when the user provides free-form text containing lists of people, project descriptions, or technology mentions that should be registered in the CTO system. Triggers on phrases like "cadastrar pessoas", "importar lista", "processar texto", "adicionar equipe", "registrar iniciativas", "bulk import", "entrada em massa", or when the user pastes a block of text with names, roles, projects, or technologies.
version: 1.0.0
---

# Text Parser Skill

Processa texto livre e identifica automaticamente entidades (pessoas, iniciativas, tecnologias) para cadastro em massa no sistema CTO Be Growth.

## Quando Usar

Esta skill e ativada quando o usuario:
- Fornece lista de pessoas com nomes e cargos
- Descreve projetos ou iniciativas em texto corrido
- Menciona tecnologias que estao em uso ou avaliacao
- Cola texto de planilhas, documentos ou emails
- Pede para "importar", "processar" ou "cadastrar" em massa

**Frases de trigger:**
- "cadastrar a equipe"
- "importar lista de pessoas"
- "processar esse texto"
- "adicionar essas iniciativas"
- "registrar as tecnologias"
- "entrada em massa"
- "bulk import"
- "organizar e cadastrar"

## Fluxo Resumido

```
1. RECEBER texto do usuario
2. IDENTIFICAR tipo: pessoas, iniciativas, tecnologias ou misto
3. IDENTIFICAR escopo/empresa (ou perguntar)
4. EXTRAIR entidades estruturadas
5. VALIDAR contra vocabulario e _index existente
6. CONFIRMAR com usuario antes de executar
7. CADASTRAR entidades confirmadas
8. REPORTAR resultado
```

## Mapeamentos Automaticos

### Papeis (texto livre -> vocabulario)
| Texto no input | Papel no sistema |
|----------------|------------------|
| desenvolvedor senior, dev sr, senior developer | dev_senior |
| desenvolvedor pleno, dev pleno, mid developer | dev_pleno |
| desenvolvedor junior, dev jr, junior | dev_junior |
| analista, analyst | analista |
| lider tecnico, tech lead, lead | lider_tech |
| gerente, manager, gestor | lider_negocio |
| cto, chief technology | cto |
| pmo, project manager | pmo |
| analista de dados, data analyst | analista_dados |
| engenheiro de dados, data engineer | engenheiro_dados |
| arquiteto, architect | arquiteto |
| po, product owner | po |

### Niveis (texto livre -> vocabulario)
| Texto no input | Nivel no sistema |
|----------------|------------------|
| jr, junior, iniciante | junior |
| pleno, mid, intermediario | pleno |
| sr, senior, experiente | senior |
| especialista, expert, master | especialista |

### Tecnologias (categoria automatica)
| Tecnologia | Categoria |
|------------|-----------|
| Python, Go, Java, Node, FastAPI, Django | backend |
| React, Vue, Angular, Next.js, Svelte | frontend |
| PostgreSQL, MySQL, Redis, MongoDB | backend (database) |
| BigQuery, Snowflake, dbt, Spark | data |
| OpenAI, LangChain, Anthropic, Claude | ai |
| Grafana, Prometheus, Datadog | observabilidade |
| Docker, Kubernetes, GCP, AWS, Azure | infra |

## Formato de Confirmacao

Antes de executar qualquer cadastro, apresentar:

```
+--------------------------------------------------+
| ANALISE DO TEXTO                                  |
+--------------------------------------------------+
| Escopo: [empresa]                                |
|                                                  |
| PESSOAS ([N]):                                   |
|   1. [nome] - [papel] - [skills]                 |
|   2. [nome] - [papel] - [skills]                 |
|                                                  |
| INICIATIVAS ([N]):                               |
|   1. [nome] - [problema]                         |
|   2. [nome] - [problema]                         |
|                                                  |
| TECNOLOGIAS ([N]):                               |
|   1. [nome] ([categoria]) - [status]             |
|                                                  |
| ALERTAS:                                         |
|   * [duplicatas, campos faltando, etc]           |
+--------------------------------------------------+

Confirmar cadastro?
```

## Comandos Relacionados

Apos usar o text-parser, sugerir:
- `/people status [empresa]` - Ver pessoas cadastradas
- `/roadmap status [empresa]` - Ver iniciativas
- `/roadmap priorize [empresa]` - Priorizar backlog
- `/inventario status` - Ver stack

## Arquivos Necessarios

Para executar, a skill precisa acessar:
- `${CLAUDE_PLUGIN_ROOT}/schemas/vocabulario.yaml` - Vocabulario controlado
- `./knowledge/[escopo]/pessoas/_index.md` - Verificar duplicatas de pessoas
- `./knowledge/[escopo]/iniciativas/_index.md` - Proximo ID de iniciativa
- `./knowledge/[escopo]/contexto.md` - Pilares para inferir em iniciativas
- `./knowledge/holding/stack.md` - Verificar tecnologias existentes

## Agente Associado

Esta skill utiliza o agente `text-parser` localizado em:
`${CLAUDE_PLUGIN_ROOT}/agents/text-parser/AGENT.md`

O agente contem a logica completa de parsing, validacao e cadastro.
