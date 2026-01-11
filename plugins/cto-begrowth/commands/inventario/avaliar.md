---
command: "inventario avaliar $tecnologia"
description: Inicia processo de avaliacao de uma nova tecnologia.
args:
  tecnologia:
    description: "Nome da tecnologia a avaliar (ex: Pinecone, Kafka)"
    required: true
---

# /inventario avaliar

## Descricao
Inicia processo de avaliacao de uma nova tecnologia.

## Uso
```
/inventario avaliar [tecnologia]
```

**Exemplos:**
- `/inventario avaliar Pinecone`
- `/inventario avaliar Kafka`
- `/inventario avaliar Snowflake`

## Fluxo de Execucao

### 1. Verificar historico
```
# Ja foi avaliada?
BUSCAR em ./knowledge/holding/stack.md (atual e depreciado)
SE encontrado:
  INFO "Ja avaliada anteriormente"
  MOSTRAR resultado anterior

# Similar em avaliacao?
BUSCAR techs com status == "avaliando"
SE similar:
  ALERTA "Similar em avaliacao: [tech]"
```

### 2. Identificar contexto
```
PERGUNTAR:
  1. Qual problema esta tecnologia resolve?
  2. Quais alternativas ja considerou?
  3. Quais empresas se beneficiariam?
  4. Quem sera responsavel pela avaliacao?
  5. Qual deadline para decisao?
```

### 3. Criar registro de avaliacao
```
ADICIONAR em ./knowledge/holding/stack.md na secao "Em Avaliacao":
  - Nome
  - Contexto
  - Deadline
  - Responsavel
```

### 4. Sugerir criterios de avaliacao
```
BASEADO em ./knowledge/holding/stack.md e ADRs existentes:
  - Integracao com stack atual
  - Curva de aprendizado
  - Custo
  - Escalabilidade
  - Comunidade/suporte
```

### 5. Verificar se precisa ADR
```
SE tecnologia afeta mais de 1 empresa:
  SUGERIR "Criar ADR holding para esta decisao"
SE tecnologia substitui algo existente:
  SUGERIR "Criar ADR com referencia a anterior"
```

## Criterios de Avaliacao Padrao

### Criterios Tecnicos
- Integracao com stack existente
- Performance/escalabilidade
- Seguranca
- Documentacao
- Comunidade/suporte

### Criterios Operacionais
- Custo (licenca, infraestrutura)
- Complexidade de operacao
- Curva de aprendizado
- Monitoramento

### Criterios Estrategicos
- Vendor lock-in
- Roadmap do produto
- Alternativas disponiveis
- Alinhamento com ADRs existentes

## Output Esperado

```
+----------------------------------------------------+
| AVALIACAO INICIADA: Pinecone                       |
+----------------------------------------------------+
|                                                    |
| REGISTRO CRIADO                                    |
|    Responsavel: rodrigo-missagia                   |
|    Deadline: 2025-02-15                            |
|    Contexto: Vector DB para RAG                    |
|                                                    |
| VERIFICACOES                                       |
|    OK Nao avaliada anteriormente                   |
|    !! Avaliacao similar: Vector DB (BG-ADR-003)    |
|       +-- Considerar consolidar avaliacoes         |
|                                                    |
| CRITERIOS SUGERIDOS                                |
|                                                    |
|    Tecnicos:                                       |
|    * Integracao com Python/LangChain               |
|    * Performance de busca vetorial                 |
|    * Suporte a metadados                           |
|    * Escalabilidade                                |
|                                                    |
|    Operacionais:                                   |
|    * Custo por milhao de vetores                   |
|    * SLA e suporte                                 |
|    * Facilidade de operacao                        |
|                                                    |
|    Estrategicos:                                   |
|    * Vendor lock-in                                |
|    * Alternativas open-source                      |
|                                                    |
| RECOMENDACOES                                      |
|    * Criar ADR holding (afeta UTUA, ONE CONTROL)   |
|    * Comparar com: Weaviate, Milvus, pgvector      |
|    * Fazer POC antes de decidir                    |
|                                                    |
| Arquivo: ./knowledge/holding/stack.md              |
|                                                    |
+----------------------------------------------------+
```

## Proximos Passos Apos Avaliacao

### Se APROVAR tecnologia:
1. Atualizar status para "homologado" em stack.md
2. Criar ADR documentando a decisao
3. Identificar responsavel tecnico
4. Planejar capacitacao se necessario

### Se REJEITAR tecnologia:
1. Atualizar status para "rejeitado" em stack.md
2. Documentar motivo da rejeicao
3. Sugerir alternativas se aplicavel

### Se ADIAR decisao:
1. Manter status "avaliando"
2. Atualizar deadline
3. Documentar pendencias

## Arquivos Modificados

- `./knowledge/holding/stack.md` - Adicionar registro de avaliacao

## Arquivos Consultados

- `./knowledge/holding/stack.md` - Verificar historico
- `./knowledge/holding/adrs/` - ADRs relacionadas
- `./knowledge/holding/pessoas/_index.md` - Verificar responsavel

## Integracao com Outros Comandos

- `/roadmap adr holding` - Criar ADR para decisao
- `/inventario add tech holding` - Adicionar tecnologia homologada
- `/inventario status` - Ver status apos registro
