# Fase 2 — Perfil, Backup Global e Experiência Premium

> Objetivo: transformar o Perfil no centro de persistência e identidade do usuário, com backup automático confiável e evolução visual/cosmética alinhada ao Sistema de Progressão Imperial.

## 1) Visão de produto (o que deve existir)

### 1.1 Backup global por Perfil
- Um único comando de backup no Perfil deve capturar **todo o conteúdo** do app de uma vez.
- O backup deve respeitar `owner_id` e versionamento por domínio.
- O usuário precisa visualizar:
  - último backup realizado,
  - status (ok / pendente / falha),
  - origem (manual, auto on-change, auto on-startup, agendado diário).

### 1.2 Backup automático em eventos críticos
Executar backup em segundo plano nos gatilhos:
1. ao iniciar o app,
2. ao editar/adicionar/remover dados em qualquer tela,
3. diariamente em horário configurado.

Regra UX: backup automático **não pode bloquear** fluxo principal do usuário.

### 1.3 Reformulação do Perfil
- Tela de Perfil com visual “crystal liquid”.
- Foto de perfil, banner/efeito de perfil e seção de customização.
- Itens cosméticos desbloqueados/comprados via Progressão Imperial.

---

## 2) Escopo funcional detalhado

## 2.1 Painel de backup no Perfil
Adicionar seção “Backup & Sincronização” com:
- botão `Backup global agora`,
- card de status com:
  - timestamp do último sucesso,
  - total de domínios sincronizados,
  - fila pendente,
  - último erro amigável,
- toggle `Backup automático` (on/off),
- seletor `Horário diário`.

## 2.2 Motor de backup global (orquestrador)
Criar serviço central de orquestração (ex.: `GlobalBackupOrchestrator`) responsável por:
- registrar jobs de backup (manual e automáticos),
- agrupar alterações por domínio,
- executar pipeline `collect -> serialize -> upload -> confirm`,
- salvar telemetria e estado local do job,
- aplicar política de retry com backoff exponencial.

## 2.3 Backup por alteração (on-change)
Padrão recomendado por domínio:
- após `upsert/delete` no repositório local, disparar evento para fila de backup;
- debounce curto (ex.: 3–10s) para evitar excesso de chamadas;
- consolidar múltiplas mudanças em um único job.

## 2.4 Backup no startup
No bootstrap da aplicação:
1. carregar sessão e conectividade,
2. carregar fila local pendente,
3. se houver conectividade e usuário autenticado, executar job de startup,
4. se offline, manter fila para envio posterior sem travar UI.

## 2.5 Backup diário agendado
- armazenar horário configurado no perfil/configurações;
- no foreground, verificar janela de execução diária;
- em mobile, evoluir para scheduler nativo (quando necessário);
- garantir idempotência (não repetir mais de 1 backup diário na mesma janela).

---

## 3) Arquitetura sugerida

## 3.1 Componentes novos
- `ProfileBackupController` (camada de aplicação)
- `GlobalBackupOrchestrator` (serviço de domínio)
- `BackupJobStore` (persistência local da fila/status)
- `BackupPolicy` (debounce, retry, timeout, prioridade)
- `ProfileCustomizationRepository` (cosméticos/foto/banner/efeitos)

## 3.2 Contratos de dados
Modelo de job (exemplo conceitual):
- `jobId`, `ownerId`, `trigger` (`manual|on_change|startup|daily`),
- `domains` (lista),
- `startedAt`, `finishedAt`,
- `status` (`queued|running|success|failed|partial`),
- `attempt`, `lastError`.

Metadados do perfil:
- `backup_auto_enabled` (bool),
- `backup_daily_time` (HH:mm),
- `last_global_backup_at` (timestamp),
- `last_global_backup_status`.

## 3.3 Observabilidade
Registrar em telemetria:
- latência total do backup,
- payload por domínio,
- taxa de sucesso/falha por trigger,
- motivos de falha categorizados (rede, auth, schema, timeout).

---

## 4) UX e design da nova tela de Perfil

## 4.1 Estrutura visual
Seções sugeridas:
1. Header com banner + avatar + nome imperial,
2. progresso imperial resumido (nível, títulos, moeda interna),
3. backup & sincronização,
4. customização cosmética,
5. segurança e sessão.

## 4.2 Crystal liquid
Diretrizes:
- superfícies translúcidas com blur,
- bordas suaves com brilho interno,
- estados de hover/press com animação curta,
- consistência com `GlassCard` já existente.

## 4.3 Cosméticos de perfil
Itens previstos:
- molduras de avatar,
- banners temáticos,
- efeitos sutis de partículas,
- selos/títulos visuais.

Origem dos itens:
- desbloqueio por nível,
- compra com moeda da Progressão Imperial,
- recompensas de campanhas/rituais.

---

## 5) Regras de negócio essenciais

1. Backup manual sempre permitido quando autenticado.
2. Backup automático nunca interrompe edição principal.
3. Offline nunca bloqueia uso local; apenas fila e reprocessa depois.
4. Um erro de backup deve gerar feedback amigável + ação de retry.
5. Job diário deve respeitar limite de uma execução por dia/janela.
6. Perfil sem sessão remota deve mostrar modo local de forma explícita.

---

## 6) Plano de implementação (passo a passo)

## Etapa A — Fundação de backup global
1. Criar `GlobalBackupOrchestrator` com fila local.
2. Integrar gatilho manual em `ProfileScreen`.
3. Exibir status básico (último sucesso/falha).

## Etapa B — Automação sem fricção
4. Integrar gatilho startup no bootstrap do app.
5. Integrar gatilho on-change em repositórios principais.
6. Adicionar debounce/coalescência de jobs.

## Etapa C — Agendamento diário
7. Persistir horário diário e toggle no perfil.
8. Executar rotina diária idempotente.
9. Medir impacto (latência/falhas).

## Etapa D — Reforma visual do perfil
10. Novo layout crystal liquid com header premium.
11. Avatar/banner/efeitos + catálogo cosmético.
12. Integração com Progressão Imperial para desbloqueio/compra.

## Etapa E — Robustez e governança
13. Retry com backoff + classificação de erro.
14. Telemetria e métricas operacionais.
15. Checklist final de aceite de produto.

---

## 7) Critérios de aceite (pronto de verdade)

- [ ] Backup global manual funciona para todos os domínios ativos.
- [ ] Backup automático roda no startup.
- [ ] Backup automático roda após mudanças relevantes (on-change).
- [ ] Backup diário executa no horário configurado (idempotente).
- [ ] Offline não bloqueia uso local; fila é retomada online.
- [ ] Perfil exibe status de backup claro e acionável.
- [ ] Nova UI de perfil (crystal liquid) implementada sem regressão de performance.
- [ ] Cosméticos integrados ao sistema de progressão (desbloqueio/compra).
- [ ] Telemetria de sucesso/falha disponível por tipo de gatilho.

---

## 8) Riscos e mitigação

- **Excesso de chamadas de backup**: usar debounce/coalescência.
- **Conflitos de versão**: usar `version` por entidade + merge previsível.
- **Impacto de UX**: processar em background, nunca bloquear fluxo.
- **Falhas intermitentes de rede**: retry com backoff e fila persistente.

---

## 9) Próximos passos recomendados

1. Validar este documento como baseline de Fase 2.
2. Quebrar Etapa A em issues técnicas pequenas (2–4 horas cada).
3. Entregar primeiro backup manual + status no perfil.
4. Em seguida, automação startup/on-change.
5. Finalizar com agenda diária + reforma visual + cosméticos.
