# Dominium — Fase 0 de Fundação para Sync/Cloud

Status: **Pending Approval**
Versão do contrato: **v1.0**

Este documento formaliza a base técnica da Fase 0 para permitir backup/sincronização sem retrabalho em fases futuras.

---

## 1) Contrato mínimo de metadados (obrigatório para entidades sincronizáveis)

Todos os registros que forem sincronizados com nuvem devem incluir os metacampos abaixo:

- `id` (`String`, obrigatório): identificador único global (UUID recomendado).
- `createdAt` (`String ISO8601`, obrigatório): data de criação do registro.
- `updatedAt` (`String ISO8601`, obrigatório): data da última alteração semântica do registro.
- `deletedAt` (`String ISO8601?`, opcional): soft delete; `null` quando ativo.
- `version` (`int`, obrigatório): versão incremental local por registro.
- `deviceId` (`String`, obrigatório): identificador lógico do dispositivo que fez a última escrita.

### Regras de atualização

1. Criar registro:
   - `createdAt = now`, `updatedAt = now`, `deletedAt = null`, `version = 1`.
2. Alterar registro:
   - `updatedAt = now`, `version = version + 1`.
3. Remover logicamente:
   - `deletedAt = now`, `updatedAt = now`, `version = version + 1`.
4. Restaurar (undelete):
   - `deletedAt = null`, `updatedAt = now`, `version = version + 1`.

---

## 2) Sync domains e checkpoints

A sincronização deve ser segmentada por domínio para reduzir acoplamento e simplificar retries.

Domínios iniciais:

1. `treasury` (`treasury_entries`)
2. `debts` (`debts`)
3. `direct_debts` (`direct_debts`)
4. `accounts` (`accounts`, `account_movements`)
5. `campaigns` (`campaigns`)
6. `orders` (`orders`)
7. `progression` (`progression`)
8. `codex` (`codex`)
9. `rituals` (`rituals`)
10. `monthly_reports` (`monthly_reports`)
11. `settings` (`settings`)
12. `timeline_notes` (chave em `settings`)
13. `telemetry` (`telemetry`) — **opcional de upload**, obrigatório local

### Checkpoint por domínio

Cada domínio deve manter:

- `lastSyncAt` (`String ISO8601`)
- `lastCursor` (`String?`, opcional para paginação remota)
- `lastSuccessHash` (`String?`, opcional para integridade)
- `pendingWrites` (`int`, opcional)

Persistência recomendada dos checkpoints: `settings.sync_state.<domain>`.

---

## 3) Política de conflito (v1)

Política inicial: **LWW (Last Write Wins)** por registro, com auditoria para entidades críticas.

### Critério de vencedor

Comparar na ordem:

1. `updatedAt` mais recente vence;
2. empate -> `version` maior vence;
3. empate -> ordenação lexical de `deviceId` (desempatador determinístico).

### Entidades críticas (exigem auditoria)

- `account_movements`
- `debt_payments`
- `direct_debt.payments`
- `monthly_reports`

Para estas entidades, além do merge LWW:

- registrar log de conflito local (`telemetry`), com antes/depois;
- registrar checksum simples (`hash(payload_sem_meta)`) quando aplicável;
- marcar `needsReview = true` em caso de conflito destrutivo (ex.: dois pagamentos editados no mesmo timestamp).

---

## 4) Contrato JSON de referência

```json
{
  "id": "uuid",
  "createdAt": "2026-02-16T10:20:30.000Z",
  "updatedAt": "2026-02-16T10:21:05.000Z",
  "deletedAt": null,
  "version": 3,
  "deviceId": "android-a346m",
  "payload": {
    "domainSpecific": true
  }
}
```

---

## 5) Checklist de migração por domínio (gate obrigatório)

Use este checklist antes de habilitar sync em qualquer domínio.

### Template (copiar por domínio)

- [ ] Domínio mapeado para box/chave local
- [ ] Entidade possui os 6 metacampos padrão
- [ ] `fromMap/toMap` atualizados com defaults backward-compatible
- [ ] Migração em `HiveSchemaManager` adicionada e idempotente
- [ ] Casos de soft delete cobertos
- [ ] Teste unitário de serialização + merge
- [ ] Conflito LWW testado
- [ ] Entidade marcada como crítica/não crítica
- [ ] Telemetria de inconsistência conectada
- [ ] Rollback documentado

### Planejamento inicial por domínio

| Domínio | Prioridade | Crítico | Observação |
|---|---:|:---:|---|
| treasury | P1 | Médio | Base para fluxo de caixa |
| debts | P1 | Alto | Inclui pagamentos/cartão |
| direct_debts | P1 | Alto | Inclui pagamentos diretos |
| accounts | P1 | Alto | Movimentações são sensíveis |
| progression | P2 | Médio | Impacta título/estado |
| settings | P2 | Baixo | Preferências + sync state |
| campaigns/orders | P3 | Médio | Dados de execução |
| timeline_notes | P3 | Baixo | Anotações, baixo risco |
| telemetry | P4 | Baixo | Upload opcional |

---

## 6) Checklist de aprovação (critério de pronto da Fase 0)

A Fase 0 será considerada pronta quando:

1. Este contrato for aprovado;
2. Os metacampos e regras forem aceitos como padrão institucional;
3. O checklist por domínio for usado como gate obrigatório de rollout;
4. Política de conflito LWW + auditoria crítica estiver formalmente definida.

### Aprovação formal

| Item | Responsável | Status | Evidência |
|---|---|---|---|
| Contrato de metadados aprovado | Tech Lead | Pendente | Link para decisão |
| Sync domains validados | Eng. App | Pendente | Lista de domínios |
| Política LWW + auditoria aprovada | Eng. App + Produto | Pendente | ADR/ata |
| Checklist por domínio adotado | Time | Pendente | PRs com checklist |

---

## 7) Checklist de migração por domínio (execução)

Preencher durante a fase de implementação:

| Domínio | Meta fields | Migração | Testes | Conflito | Telemetria | Rollback | Status |
|---|:---:|:---:|:---:|:---:|:---:|:---:|---|
| treasury | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | Pendente |
| debts | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | Pendente |
| direct_debts | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | Pendente |
| accounts | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | Pendente |
| progression | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | Pendente |
| settings | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | Pendente |
| campaigns/orders | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | Pendente |
| timeline_notes | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | Pendente |
| telemetry | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | Pendente |

