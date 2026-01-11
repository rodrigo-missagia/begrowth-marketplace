---
name: on-iniciativa-complete
description: Hook quando iniciativa é concluída
triggers:
  - /roadmap update [id] status (quando status → concluido)
events:
  - PostToolUse (after status change)
version: 1
---

# Hook: Conclusão de Iniciativa

## Propósito

Garantir que conclusões de iniciativas são documentadas adequadamente, dependentes são notificados e sinergias são comunicadas.

---

## Trigger

Este hook é acionado quando:
- `/roadmap update [id] status` muda status para "concluido"
- Edição direta do arquivo com status → "concluido"

---

## Fluxo de Execução

### Fase 1: Coleta Obrigatória

```yaml
coleta_obrigatoria:
  # Antes de permitir conclusão, exigir informações
  perguntas:
    - pergunta: "Qual foi o resultado entregue?"
      campo: resultado
      obrigatorio: true
      validacao: minimo 20 caracteres
      exemplo: "Dashboard implementado com métricas RED em tempo real"

    - pergunta: "Quais aprendizados da iniciativa?"
      campo: aprendizados
      obrigatorio: true
      validacao: minimo 20 caracteres
      exemplo: "BigQuery streaming tem delay de 10s, usar particionamento"

    - pergunta: "Data de conclusão?"
      campo: data_conclusao
      obrigatorio: true
      default: data_atual
      formato: YYYY-MM-DD

  # Bloqueio se incompleto
  se_incompleto:
    BLOQUEAR conclusão
    ERRO: "Preencha resultado e aprendizados antes de concluir"
    MANTER status: "em_andamento"
```

### Fase 2: Verificar Dependentes

```yaml
verificar_dependentes:
  # Buscar iniciativas que dependiam desta
  dependentes: []

  busca:
    PARA cada empresa em [utua, resolve, one-control, assiny]:
      PARA cada iniciativa em [empresa]/iniciativas/:
        LER frontmatter → depende_de
        SE id_concluida em depende_de.iniciativas:
          dependentes.add({
            id: iniciativa.id,
            nome: iniciativa.nome,
            empresa: empresa,
            status: iniciativa.status
          })

  # Notificar sobre dependentes
  notificacao:
    SE dependentes.count > 0:
      PARA cada dependente:
        SE dependente.status == "backlog":
          ALERTA "✅ [dependente.id] pode ser iniciada agora"
          SUGERIR "Verificar se recursos disponíveis"

        SE dependente.status == "pausado":
          ALERTA "⏸️ [dependente.id] estava pausada aguardando esta"
          SUGERIR "Retomar iniciativa?"
```

### Fase 3: Verificar Sinergias

```yaml
verificar_sinergias:
  # Ler sinergias potenciais da iniciativa concluída
  LER iniciativa.sinergia_potencial[]

  # Para cada sinergia identificada
  PARA cada sinergia:
    LEMBRETE "📣 Comunicar conclusão para [sinergia.empresa]"
    INFO "Contexto: [sinergia.como]"

    # Sugerir ação específica
    SE sinergia.tipo == "componente_compartilhavel":
      SUGERIR "Disponibilizar componente para [empresa]"

    SE sinergia.tipo == "padrao_replicavel":
      SUGERIR "Documentar padrão para replicação"

    SE sinergia.tipo == "integracao":
      SUGERIR "Agendar alinhamento técnico com [empresa]"
```

### Fase 4: Atualizar Arquivos

```yaml
atualizar_arquivos:
  # 1. Arquivo da iniciativa
  iniciativa_md:
    frontmatter:
      status: "concluido"
      data_conclusao: [data]
      resultado: [resposta]
      aprendizados: [resposta]
      updated_at: data_atual

    conteudo:
      # Adicionar seção de conclusão
      adicionar_secao: |
        ## Conclusão

        **Data:** [data_conclusao]

        **Resultado Entregue:**
        [resultado]

        **Aprendizados:**
        [aprendizados]

    historico:
      # Adicionar entrada no histórico
      adicionar: |
        | [data_conclusao] | conclusao | Iniciativa concluída |

  # 2. Arquivo _index.md
  index_md:
    entities:
      - ENCONTRAR entrada com id
      - ATUALIZAR status: "concluido"

    by_status:
      - [status_anterior] -= 1
      - concluido += 1

    alerts:
      - REMOVER alertas relacionados a esta iniciativa

    updated_at: data_atual

  # 3. Arquivos de pessoas envolvidas
  pessoas:
    PARA cada pessoa em [owner, contributors]:
      LER pessoa.md
      ATUALIZAR pessoa.iniciativas[]:
        - ENCONTRAR iniciativa por id
        - ATUALIZAR status: "concluido"
        # OU mover para seção de histórico
      SALVAR pessoa.md
```

### Fase 5: Registrar no Histórico

```yaml
registrar_historico:
  # Adicionar entrada estruturada no histórico da iniciativa
  entrada_historico:
    data: [data_conclusao]
    tipo: "conclusao"
    autor: [owner ou quem executou comando]
    descricao: "Iniciativa concluída com sucesso"
    detalhes:
      resultado: [resultado]
      aprendizados: [aprendizados]
      duracao: calcular([inicio], [data_conclusao])
      dependentes_desbloqueados: [lista de ids]
      sinergias_comunicar: [lista de empresas]
```

---

## Output do Hook

```yaml
hook_output:
  status: "success"

  iniciativa:
    id: "UTUA-001"
    nome: "Dashboard Real-time de Performance"
    status_anterior: "em_andamento"
    status_novo: "concluido"
    data_conclusao: "2025-01-10"

  documentacao:
    resultado: "Dashboard implementado com métricas RED"
    aprendizados: "BigQuery streaming tem delay de 10s"
    duracao_dias: 71

  notificacoes:
    dependentes:
      - id: "UTUA-003"
        status: "backlog"
        acao: "Pode ser iniciada"
      - id: "UTUA-005"
        status: "pausado"
        acao: "Retomar"

    sinergias:
      - empresa: "ONE CONTROL"
        tipo: "componente_compartilhavel"
        acao: "Comunicar padrão de dashboard"
      - empresa: "ASSINY"
        tipo: "padrao_replicavel"
        acao: "Documentar métricas RED"

  arquivos_atualizados:
    - "knowledge/utua/iniciativas/UTUA-001.md"
    - "knowledge/utua/iniciativas/_index.md"
    - "knowledge/utua/pessoas/joao-silva.md"
    - "knowledge/utua/pessoas/maria-santos.md"

  proximos_passos:
    - "Comunicar ONE CONTROL sobre dashboard"
    - "Iniciar UTUA-003 (desbloqueada)"
    - "Retomar UTUA-005 (aguardava esta)"
```

---

## Exemplo de Execução

```
ENTRADA: /roadmap update UTUA-001 status concluido

FASE 1 - COLETA:
  ? Qual foi o resultado entregue?
  > Dashboard implementado com métricas RED (ROAS, CPL, CPA)
    em tempo real com refresh de 30 segundos

  ? Quais aprendizados da iniciativa?
  > BigQuery streaming tem delay de ~10s. Optamos por
    particionamento por hora para melhor custo-benefício.
    Looker tem limite de 50 gráficos por dashboard.

  ? Data de conclusão?
  > 2025-01-10 (default: hoje)

FASE 2 - DEPENDENTES:
  ✅ UTUA-003 (Automação de Alertas) pode ser iniciada
     → Dependia do dashboard para trigger de alertas

  ⏸️ UTUA-005 estava pausada aguardando
     → Precisava dos padrões de métricas

FASE 3 - SINERGIAS:
  📣 Comunicar ONE CONTROL
     → Podem usar mesmo padrão de dashboard
     Sugestão: Agendar alinhamento técnico

  📣 Comunicar ASSINY
     → Padrão de métricas RED pode ser replicado
     Sugestão: Documentar para replicação

FASE 4 - ATUALIZAÇÕES:
  ✓ UTUA-001.md atualizado (status, resultado, aprendizados)
  ✓ _index.md atualizado (by_status, entities)
  ✓ joao-silva.md atualizado (iniciativa concluída)

OUTPUT:
  status: success
  duracao: 71 dias
  proximos_passos:
    - Iniciar UTUA-003
    - Comunicar ONE CONTROL
    - Documentar padrão para ASSINY
```

---

## Integração com Commands

| Situação | Trigger | Ação |
|----------|---------|------|
| `/roadmap update [id] status concluido` | Direto | Executa hook completo |
| Edição manual do arquivo | Detectar mudança | Solicitar informações faltantes |
| Status já era concluido | Ignorar | Não re-executar hook |

---

## Validações de Bloqueio

| Condição | Ação |
|----------|------|
| Resultado não informado | BLOQUEAR, pedir resultado |
| Aprendizados não informados | BLOQUEAR, pedir aprendizados |
| Iniciativa não existe | ERRO, ID não encontrado |
| Status já era concluido | ALERTA, já concluída |

---

## Métricas Coletadas

Ao concluir, o hook calcula automaticamente:

```yaml
metricas:
  duracao_dias: diferenca(inicio, data_conclusao)
  mudancas_escopo: contar(historico onde tipo == "escopo")
  pessoas_envolvidas: count(owner + contributors)
  sinergias_geradas: count(sinergia_potencial)
  dependentes_desbloqueados: count(dependentes)
```
