# IMPERIUM / DOMINIUM

Sistema de soberania pessoal offline-first com arquitetura modular em Flutter.

## Núcleo atual

- **Trono**: estado do império, títulos, conselheira e ritual diário.
- **Tesouro**: receitas, histórico e leitura de saldo.
- **Trono das Dívidas**: gestão robusta de cartão (compras, faturas, pagamentos, projeção e plano de quitação).
- **Dívidas Diretas**: obrigações fora de cartão (empréstimos, promessas, parcelamentos informais).
- **Contas e Saldo Real**: contas bancárias, dinheiro físico e reservas líquidas.
- **Ordens**: execução de decretos diários.
- **Campanhas**: guerras de longo prazo.
- **Oráculo Financeiro**: gráficos, auditoria e calculadora de possibilidades.
- **Codex Imperial**: biblioteca viva de sistemas descobertos e domínio de uso.



## Separação estrutural do domínio financeiro

- **Saldo (o que existe):** consolidado por contas reais.
- **Receita (o que entra):** histórico de entradas no Tesouro.
- **Dívida (o que é devido):** dividido em cartão e dívida direta.
- O Centro mostra simultaneamente:
  - saldo atual total,
  - total de obrigações,
  - caixa líquido projetado.

## Rebranding Liquid Crystal Imperial (Ordem Visual)

- Navegação principal reorganizada em 4 domínios superiores:
  - **Centro** (estado atual e prioridades imediatas)
  - **Finanças** (Tesouro, Dívidas, Oráculo)
  - **Execução** (Ordens, Campanhas)
  - **Sistema** (Progressão, Codex)
- Hierarquia de informação orientada por contexto e risco (atenção automática para dívida/pressão).
- Camada de entrada por hubs para reduzir ruído e tornar funções profundas mais encontráveis.

## Princípio de ensino do próprio sistema

O app opera com aprendizagem progressiva e contextual:

- Revela funcionalidades quando elas se tornam necessárias.
- Explica: o que é, por que existe, quando usar, como usar e o custo de ignorar.
- Registra estado de domínio por módulo:
  - Não descoberto
  - Descoberto, não usado
  - Usado superficialmente
  - Dominado
- Ativa o **Mentor Invisível** para intervenções estratégicas sem sobrecarga.


## Sistema de Progressão Imperial (Grandioso e com Gravidade)

- **Progresso por prova real**: crescimento real, manutenção estratégica, vitória tática e disciplina.
- **Títulos vivos com efeito prático**: variam por risco e nível, desbloqueiam ferramentas e mudam vantagens.
- **Ordem (doutrina)**: Cofre Negro, Lâmina Rubra, Trono Dourado e Conclave alteram foco de evolução.
- **Campanha de arco automática**: objetivo supremo, missões semanais e desafio chefe.
- **Economia interna**: Glória, Disciplina, Influência e Selos com anti-exploração (anti-farm).
- **Loja Imperial funcional**: Oráculos, Decretos, Relíquias e Bênçãos com requisito de nível e custo.
- **Consequências reais**: penalidade por risco severo/crítico, queda de XP e potencial queda de nível em estado crítico.

## Estética imperial “cristal líquido vermelho”

- Glassmorphism sombrio com núcleo rubro interno.
- Camadas translúcidas com ruído leve, reflexo e profundidade.
- Estados emocionais visuais: calmo, alerta, crítico e vitória.

## Recursos de dívida implementados

- Modelo completo de cartão com:
  - limite, banco, fechamento/vencimento, juros e encargos base;
  - compras à vista/parceladas com categorias, tags e local;
  - faturas por ciclo com mínimo/pago/em aberto;
  - pagamentos por tipo e origem;
  - estado da dívida (em dia, atenção, atraso, rotativo, renegociada, quitada).
- Projeção mensal de fatura (parcelas vivas, total previsto e limite comprometido futuro).
- Alertas inteligentes de fechamento, risco de rotativo e comprometimento de limite.
- Modo Guerra com simulação de plano de quitação por orçamento mensal.

## Recursos analíticos implementados

- Fluxo mensal (ganhos, gastos, saldo).
- Composição de dívida por cartão (pizza).
- Modo Auditor (detecção de picos de gasto).
- Ritual de Fechamento do Mês (checklist operacional).
- Calculadora de Possibilidades com cenários:
  - Conservador
  - Realista
  - Agressivo

## Stack

- Flutter + Riverpod
- Hive (offline-first)
- intl
- fl_chart

## Execução

```bash
flutter pub get
flutter run
```

## Roadmap técnico (faseado)

- Fase 0 (fundação de sync/cloud): contrato de metadados, sync domains e política de conflito.
- Documento oficial: `docs/fase0_sync_foundation.md`.


### Execução com Supabase (Fase 1 mínima)

Use `--dart-define` para injetar URL/chave pública no app cliente:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://ymgtbhisvxphenatvryf.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=<SUA_ANON_KEY>
```

Sem essas variáveis, o app usa a configuração padrão do projeto Supabase já definida no bootstrap e deve abrir com tela de login cloud.

- Fase 1.2 (rollout multi-domínio P1 com gate): `docs/fase1_multi_domain_rollout.md`.
