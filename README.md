# DOMINIUM

DOMINIUM é um aplicativo Flutter offline-first para soberania pessoal, dividido em quatro domínios:

- **Trono**: estado geral do império, títulos simbólicos, conselheira imperial e visão consolidada.
- **Tesouro Imperial**: registro de receitas e resumo financeiro em moeda brasileira.
- **Ordens**: tarefas no formato de ordens imperiais com histórico sem culpa.
- **Campanhas**: projetos longos com progresso, marcos e status de guerra.

## Diferenciais desta versão

- Personalização imperial no Trono:
  - renomear domínios da navegação inferior;
  - alternar paleta entre Vermelho Imperial e Azul Real;
  - persistência dessa configuração em Hive.
- Conselheira Imperial com recomendações automáticas baseadas em pendências, execução de ordens e estagnação de campanhas.
- Ritual diário e títulos honoríficos com linguagem adulta e tom de comando.

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

- Este MVP já contempla biometria em `core/services/imperial_services.dart` e mantém placeholders para notificações ritualísticas.
- O design usa fundo OLED preto, vermelho imperial e detalhes dourados com cards translúcidos.
