---
name: gaps
description: Use this skill to identify missing capabilities (skills, tools, people) and propose resolution options (hire, train, outsource, deprioritize). Triggers on phrases like "gap de skill", "falta capacidade", "quem sabe fazer", "ninguem conhece", "sem backup", or when analyzing if team can execute an initiative.
version: 1.0.0
---

# Skill: Analise de Gaps

## Proposito

Identificar capacidades faltantes e propor opcoes para resolver.

## Quando e Acionado

- Comando `/people gap [skill]`
- Comando `/inventario gap`
- Criacao de iniciativa (verificacao automatica)
- Atribuicao de pessoa (verificacao de match)

## Tipos de Gap

```yaml
tipos_gap:
  skill_ausente:
    descricao: "Ninguem no grupo tem o skill"
    criticidade: "alta"
    opcoes: ["contratar", "terceirizar", "treinar do zero"]

  skill_sem_backup:
    descricao: "Apenas 1 pessoa tem o skill"
    criticidade: "media"
    opcoes: ["treinar backup", "contratar", "documentar"]

  skill_em_empresa_errada:
    descricao: "Skill existe mas nao na empresa que precisa"
    criticidade: "baixa"
    opcoes: ["compartilhar pessoa", "treinar local", "transferir"]

  ferramenta_sem_owner:
    descricao: "Ferramenta em uso sem responsavel"
    criticidade: "media"
    opcoes: ["definir owner", "terceirizar", "depreciar"]

  papel_inexistente:
    descricao: "Papel necessario nao existe na estrutura"
    criticidade: "variavel"
    opcoes: ["criar papel", "distribuir responsabilidade"]
```

## Processo de Analise

### Passo 1: Mapear Skill Necessario

```
# Onde o skill e usado
iniciativas_que_usam = []
PARA cada empresa em [holding, utua, resolve, one-control, assiny]:
  LER ./knowledge/[empresa]/iniciativas/_index.md
  PARA cada iniciativa:
    LER ./knowledge/[empresa]/iniciativas/[id].md
    SE skill em iniciativa.skills_necessarios:
      ADICIONAR {iniciativa, empresa, status}

# Onde o skill existe
pessoas_com_skill = []
PARA cada empresa em [holding, utua, resolve, one-control, assiny]:
  LER ./knowledge/[empresa]/pessoas/_index.md
  PARA cada pessoa:
    LER ./knowledge/[empresa]/pessoas/[id].md
    SE skill em pessoa.skills:
      ADICIONAR {pessoa, nivel, empresa, carga}
```

### Passo 2: Classificar Situacao

```
SE pessoas_com_skill.count == 0:
  situacao = "CRITICO - Ninguem tem"
  tipo = "skill_ausente"

SE pessoas_com_skill.count == 1:
  situacao = "RISCO - Sem backup"
  tipo = "skill_sem_backup"

SE pessoas_com_skill.count >= 2:
  situacao = "OK - Tem backup"
  # Mas verificar distribuicao entre empresas

# Verificar cobertura por empresa
empresas_cobertas = unique(pessoas_com_skill.map(p => p.empresa))
empresas_que_precisam = unique(iniciativas_que_usam.map(i => i.empresa))
empresas_sem_cobertura = empresas_que_precisam - empresas_cobertas

SE empresas_sem_cobertura.count > 0:
  tipo = "skill_em_empresa_errada"
```

### Passo 3: Identificar Candidatos a Treinamento

```
# Buscar skills relacionados
LER ${CLAUDE_PLUGIN_ROOT}/schemas/vocabulario.yaml
skills_relacionados = buscar_skills_proximos(skill)

# Exemplo: para "data_engineering"
# skills_relacionados = ["python", "sql", "etl", "bigquery"]

# Encontrar candidatos
candidatos_treinamento = []
PARA cada pessoa sem o skill:
  match = intersecao(pessoa.skills, skills_relacionados)
  SE match.count > 0:
    esforco = calcular_esforco_treinamento(pessoa, skill, match)
    ADICIONAR {
      pessoa: pessoa,
      skills_atuais: match,
      gap_para_skill: skill - match,
      esforco_estimado: esforco
    }

# Ordenar por menor esforco
candidatos_treinamento.sort_by(c => c.esforco_estimado)
```

### Passo 4: Gerar Opcoes

```yaml
opcoes:
  - tipo: "contratar"
    perfil: "[Perfil gerado baseado no skill]"
    prioridade: "[alta|media|baixa]"
    justificativa: "[Baseado em qtd de iniciativas afetadas]"
    impacto: "Resolve gap permanentemente"

  - tipo: "treinar"
    candidatos: "[Lista de candidatos]"
    skills_gap: "[O que falta aprender]"
    tempo_estimado: "[Baseado no gap]"
    impacto: "Resolve gap, desenvolve pessoa"

  - tipo: "terceirizar"
    escopo: "[Iniciativas especificas]"
    impacto: "Resolve pontualmente, nao constroi capacidade"

  - tipo: "despriorizar"
    iniciativas: "[Que podem esperar]"
    impacto: "Adia problema, pode acumular"
```

### Passo 5: Gerar Recomendacao

```
# Curto prazo (imediato)
SE candidatos_treinamento.count > 0 AND iniciativas_urgentes.count > 0:
  curto_prazo = "Treinar " + candidatos_treinamento[0] + " como backup"
SE candidatos_treinamento.count == 0:
  curto_prazo = "Terceirizar iniciativas urgentes"

# Medio prazo (3-6 meses)
SE iniciativas_afetadas.count > 3:
  medio_prazo = "Contratar " + perfil
SE NAO:
  medio_prazo = "Consolidar treinamento interno"

# Longo prazo (6+ meses)
SE tipo == "skill_ausente" AND iniciativas.count > 5:
  longo_prazo = "Construir squad dedicado"
SE NAO:
  longo_prazo = "Manter capacidade distribuida"
```

## Output Esperado

```yaml
output:
  gap:
    skill: "[nome do skill]"
    tipo: "[skill_ausente|skill_sem_backup|skill_em_empresa_errada|...]"
    situacao: "[CRITICO|RISCO|OK]"

  atual:
    pessoas:
      - id: "[pessoa-id]"
        empresa: "[empresa]"
        nivel: "[junior|pleno|senior]"
        iniciativas: "[count]"
        carga: "[baixa|media|alta]"
    cobertura_empresas: ["lista de empresas cobertas"]
    empresas_sem_cobertura: ["lista de empresas sem cobertura"]

  impacto:
    iniciativas_afetadas:
      - id: "[ID]"
        nome: "[Nome]"
        status: "[status]"
        empresa: "[empresa]"
    total: "[numero]"
    bloqueadas: "[numero]"

  candidatos_treinamento:
    - id: "[pessoa-id]"
      empresa: "[empresa]"
      skills_atuais: ["lista"]
      gap_para_skill: ["lista"]
      esforco_estimado: "[baixo|medio|alto]"
      recomendacao: "[Bom candidato|Considerar|Nao recomendado]"

  opcoes:
    - tipo: "[contratar|treinar|terceirizar|despriorizar]"
      detalhes: "[especificos da opcao]"
      justificativa: "[por que considerar]"

  recomendacao:
    curto_prazo: "[acao imediata]"
    medio_prazo: "[acao 3-6 meses]"
    longo_prazo: "[estrategia]"
```

## Formato de Resposta

```
+----------------------------------------------------------+
| ANALISE DE GAP: [skill]                                  |
+----------------------------------------------------------+
| Situacao: [CRITICO|RISCO|OK]                             |
| Tipo: [tipo do gap]                                      |
+----------------------------------------------------------+

COBERTURA ATUAL:
+-----------+----------------+--------+--------+
| Pessoa    | Empresa        | Nivel  | Carga  |
+-----------+----------------+--------+--------+
| [pessoa]  | [empresa]      | senior | alta   |
+-----------+----------------+--------+--------+
Empresas cobertas: [lista]
Empresas SEM cobertura: [lista]

IMPACTO:
  * Iniciativas afetadas: [total]
  * Iniciativas bloqueadas: [bloqueadas]
  * Iniciativas por empresa:
    - UTUA: [count]
    - RESOLVE: [count]
    - ONE CONTROL: [count]
    - ASSINY: [count]

CANDIDATOS A TREINAMENTO:
+-----------+----------------+----------------+----------+
| Pessoa    | Skills Atuais  | Gap            | Esforco  |
+-----------+----------------+----------------+----------+
| [pessoa]  | python, sql    | bigquery, etl  | medio    |
+-----------+----------------+----------------+----------+

OPCOES:
  1. CONTRATAR - [perfil]
     Prioridade: [alta|media]
     Justificativa: [texto]

  2. TREINAR - [candidato]
     Tempo estimado: [tempo]
     Justificativa: [texto]

  3. TERCEIRIZAR
     Escopo: [iniciativas]
     Justificativa: [texto]

RECOMENDACAO:
  * Curto prazo: [acao]
  * Medio prazo: [acao]
  * Longo prazo: [estrategia]
```

## Exemplo de Uso

```
Usuario: /people gap data_engineering

Resposta:
+----------------------------------------------------------+
| ANALISE DE GAP: data_engineering                         |
+----------------------------------------------------------+
| Situacao: RISCO                                          |
| Tipo: skill_sem_backup                                   |
+----------------------------------------------------------+

COBERTURA ATUAL:
+-----------------+----------------+--------+--------+
| Pessoa          | Empresa        | Nivel  | Carga  |
+-----------------+----------------+--------+--------+
| rodrigo-missagi | holding        | senior | alta   |
+-----------------+----------------+--------+--------+
Empresas cobertas: [holding]
Empresas SEM cobertura: [utua, resolve, one-control, assiny]

IMPACTO:
  * Iniciativas afetadas: 8
  * Iniciativas bloqueadas: 5
  * Iniciativas por empresa:
    - UTUA: 2 (Dashboard, Tracking)
    - RESOLVE: 2 (ETL Carteiras, Analytics)
    - ONE CONTROL: 3 (CDP, DMP, Segmentacao)
    - ASSINY: 1 (Analytics Checkout)

CANDIDATOS A TREINAMENTO:
+-----------+----------------+--------------------+----------+
| Pessoa    | Skills Atuais  | Gap                | Esforco  |
+-----------+----------------+--------------------+----------+
| joao-silv | python, sql    | bigquery, dataflow | medio    |
| maria-san | sql, analytics | python, bigquery   | alto     |
+-----------+----------------+--------------------+----------+

OPCOES:
  1. CONTRATAR - Data Engineer Senior
     Prioridade: alta
     Justificativa: 8 iniciativas dependem, 1 pessoa e risco

  2. TREINAR - joao-silva
     Tempo estimado: 3 meses
     Justificativa: Ja tem base solida, custo menor

  3. TERCEIRIZAR
     Escopo: RESOLVE-002, ASSINY-003
     Justificativa: Resolve pontualmente

  4. DESPRIORIZAR
     Escopo: ONE-CONTROL-003
     Justificativa: Pode esperar resolver gap

RECOMENDACAO:
  * Curto prazo: Treinar joao-silva como backup imediato
  * Medio prazo: Contratar Data Engineer para demanda
  * Longo prazo: Construir squad de dados centralizado
```
