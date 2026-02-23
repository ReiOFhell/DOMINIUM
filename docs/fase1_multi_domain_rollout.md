# Dominium — Fase 1.2: Rollout multi-domínio com gate obrigatório

Status: **Planned**
Dependências:
- Fase 1.0 auth/perfil/sessão estável.
- Fase 1.1 treasury sync funcionando ponta a ponta.

Objetivo:

> Expandir backup/sync para domínios P1 (`debts`, `direct_debts`, `accounts`) com controle de risco por checklist de gate, sem liberar domínio incompleto.

---

## 1) Ordem de entrada dos domínios (P1)

1. `debts`
2. `direct_debts`
3. `accounts`

Regra: só iniciar o próximo domínio quando o atual tiver gate 100% completo.

---

## 2) Gate obrigatório por domínio

Cada domínio deve cumprir **todos** os itens abaixo antes de ser considerado liberado:

1. Metacampos de sync adicionados em todas as entidades do domínio:
   - `id`
   - `createdAt`
   - `updatedAt`
   - `deletedAt`
   - `version`
   - `deviceId`
2. Serialização backward-compatible (`fromMap/toMap`) validada.
3. Soft delete implementado (sem hard delete destrutivo).
4. Sync service com checkpoint em `settings.sync_state.<domain>`:
   - `lastSyncAt`
   - `lastCursor`
   - `lastSuccessHash`
   - `pendingWrites`
5. Política de conflito LWW implementada:
   - `updatedAt` > `version` > `deviceId`.
6. Telemetria conectada para falhas de sync e conflitos.
7. SQL remoto criado + RLS por `owner_id = auth.uid()`.
8. Testes unitários mínimos de merge e serialização passando.
9. Teste manual online/offline validado.
10. Rollback documentado (como desativar domínio sem perda local).

---

## 3) Checklist vivo de rollout

| Domínio | Meta fields | Serialização | Soft delete | Checkpoint | LWW | Telemetria | SQL + RLS | Testes | Manual | Rollback | Status |
|---|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|---|
| debts | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | Pendente |
| direct_debts | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | Pendente |
| accounts | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | Pendente |

---

## 4) Critério de avanço entre domínios

- Se qualquer item do gate estiver incompleto: **domínio bloqueado**.
- Se todos os itens estiverem completos: domínio marcado como **Liberado** e próximo domínio pode iniciar.

---

## 5) Critério de pronto da Fase 1.2

A fase estará pronta apenas quando:

1. `debts`, `direct_debts` e `accounts` estiverem com gate 100% completo.
2. Conflitos críticos gerarem telemetria e trilha de revisão.
3. Teste de regressão confirmar que app continua operável offline sem bloqueio de UI.
