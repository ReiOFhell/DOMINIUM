# IMPERIUM / DOMINIUM

Sistema de soberania pessoal offline-first com arquitetura modular em Flutter.

## Núcleo atual

- **Trono**: estado do império, títulos, conselheira e ritual diário.
- **Tesouro**: receitas, histórico e leitura de saldo.
- **Trono das Dívidas**: gestão robusta de cartão (compras, faturas, pagamentos, projeção e plano de quitação).
- **Ordens**: execução de decretos diários.
- **Campanhas**: guerras de longo prazo.
- **Oráculo Financeiro**: gráficos, auditoria e calculadora de possibilidades.

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
