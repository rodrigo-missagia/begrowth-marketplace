---
command: "inventario gap"
description: Lista todos os gaps de ferramentas, tecnologias e capacidades.
---

# /inventario gap

## Descricao
Lista todos os gaps de ferramentas, tecnologias e capacidades.

## Uso
```
/inventario gap
```

## Fluxo de Execucao

### 1. Coletar gaps de stack.md
```
LER ./knowledge/holding/stack.md
gaps_stack = frontmatter.gaps
```

### 2. Cruzar com pessoas
```
PARA cada tech em stack (status == homologado):
  BUSCAR pessoas com skill em ./knowledge/[escopo]/pessoas/
  SE count == 0:
    ADICIONAR gap "Tech sem responsavel: [tech]"
  SE count == 1:
    ADICIONAR gap "Tech sem backup: [tech]"
```

### 3. Cruzar com iniciativas
```
PARA cada iniciativa em todas empresas:
  PARA cada skill em skills_necessarios:
    SE skill nao coberto:
      ADICIONAR gap "Skill nao coberto: [skill]"
```

### 4. Classificar por criticidade
```
PARA cada gap:
  criticidade = calcular baseado em:
    - Quantas iniciativas afeta
    - Se tem alguma pessoa (backup vs ninguem)
    - Impacto declarado no gap
```

## Regras de Classificacao

### Criticidade CRITICO
- Tech homologada sem ninguem que conheca
- Skill bloqueando mais de 3 iniciativas
- Ferramenta essencial sem owner

### Criticidade ALTO
- Tech homologada com apenas 1 pessoa (sem backup)
- Skill bloqueando 1-3 iniciativas
- Ferramenta importante sem owner

### Criticidade MEDIO
- Tech em avaliacao sem responsavel
- Skill com cobertura parcial
- Ferramenta secundaria sem owner

## Output Esperado

```
+----------------------------------------------------+
| GAPS - INVENTARIO                                  |
+----------------------------------------------------+
|                                                    |
| CRITICO (2)                                        |
|                                                    |
| 1. Data Engineering - Sem backup                   |
|    Pessoas: 1 (rodrigo-missagia)                   |
|    Iniciativas afetadas: 8                         |
|    Opcoes:                                         |
|    +-- Contratar (prioridade alta)                 |
|    +-- Treinar joao-silva (tem Python Senior)      |
|    +-- Terceirizar iniciativas especificas         |
|                                                    |
| 2. Temporal.io - Ninguem conhece                   |
|    Pessoas: 0                                      |
|    Iniciativas afetadas: 3 (ASSINY)                |
|    ADR: BG-ADR-002 (homologado mas sem capacidade) |
|    Opcoes:                                         |
|    +-- Treinar alguem da ASSINY                    |
|    +-- Contratar especialista                      |
|    +-- Usar alternativa (Airflow?)                 |
|                                                    |
+----------------------------------------------------+
| ALTO (2)                                           |
|                                                    |
| 3. HubSpot                                         |
|    Tipo: Ferramenta sem owner                      |
|    Usado por: ONE CONTROL                          |
|    Opcoes: Definir owner, terceirizar              |
|                                                    |
| 4. AI Enabler (papel)                              |
|    Tipo: Papel nao existe                          |
|    Iniciativas afetadas: UTUA-003, RESOLVE-002     |
|    Opcoes: Criar papel, distribuir responsabilidade|
|                                                    |
+----------------------------------------------------+
| MEDIO (2)                                          |
|                                                    |
| 5. ClickUp                                         |
|    Tipo: Ferramenta sem owner                      |
|                                                    |
| 6. Looker                                          |
|    Tipo: Tech com apenas 1 pessoa                  |
|                                                    |
+----------------------------------------------------+
| RESUMO                                             |
|   Total de gaps: 6                                 |
|   Iniciativas bloqueadas: 11                       |
|   Acao imediata recomendada: Data Engineering      |
+----------------------------------------------------+
```

## Opcoes de Resolucao

Para cada gap identificado, sugerir opcoes:

### Para gaps de SKILL/TECH:
1. **CONTRATAR** - Perfil necessario e prioridade
2. **TREINAR** - Candidatos internos com skills relacionados
3. **TERCEIRIZAR** - Para iniciativas especificas
4. **DESPRIORIZAR** - Adiar iniciativas dependentes

### Para gaps de FERRAMENTA:
1. **DEFINIR OWNER** - Pessoa mais proxima do uso
2. **TERCEIRIZAR** - Consultoria externa
3. **SUBSTITUIR** - Ferramenta alternativa

### Para gaps de PAPEL:
1. **CRIAR PAPEL** - Definir responsabilidades
2. **DISTRIBUIR** - Entre pessoas existentes
3. **CONTRATAR** - Se volume justifica

## Arquivos Consultados

- `./knowledge/holding/stack.md` - Stack e gaps declarados
- `./knowledge/holding/pessoas/_index.md` - Pessoas da holding
- `./knowledge/[empresa]/pessoas/_index.md` - Pessoas por empresa
- `./knowledge/[empresa]/iniciativas/_index.md` - Iniciativas por empresa
- `./knowledge/holding/adrs/` - ADRs para referencia

## Integracao com Outros Comandos

- `/people gap [skill]` - Analise detalhada de um skill especifico
- `/inventario avaliar [tech]` - Iniciar avaliacao de alternativa
- `/people add [empresa]` - Adicionar pessoa para cobrir gap
