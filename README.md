# DOMINIUM

DOMINIUM é um aplicativo Flutter offline-first para soberania pessoal, dividido em quatro domínios:

- **Trono**: estado geral do império, títulos simbólicos e visão consolidada.
- **Tesouro Imperial**: registro de receitas e resumo financeiro em moeda brasileira.
- **Ordens**: tarefas no formato de ordens imperiais com histórico sem culpa.
- **Campanhas**: projetos longos com progresso, marcos e status de guerra.

## Stack

- Flutter (Dart)
- Riverpod para estado
- Hive para persistência local offline
- intl para formatação monetária
- fl_chart para gráficos discretos

## Estrutura

```text
lib/
  core/
  domains/
    throne/
    treasury/
    orders/
    campaigns/
    rituals/
```

## Como executar

1. Instale Flutter SDK.
2. Rode:

```bash
flutter pub get
flutter run
```

## Observações

- Este MVP já contempla base para notificações ritualísticas e biometria em `core/services/imperial_services.dart`.
- O design usa fundo OLED preto, vermelho imperial e detalhes dourados com cards translúcidos.
