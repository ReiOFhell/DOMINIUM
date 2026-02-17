# Dominium — Fase 1: Perfil + Autenticação

Status: **Planned**
Dependência: Fase 0 aprovada (`docs/fase0_sync_foundation.md`).

Objetivo da fase:

> Vincular o Imperium a uma identidade persistente de usuário com autenticação segura, sessão local persistente e comportamento offline sem bloqueio.

---

## 1) Escopo da Fase 1 (o que entra)

1. Perfil remoto (`ImperiumProfile`) por usuário.
2. Login seguro (Supabase Auth: magic link/senha).
3. Sessão persistente local (reabriu app, continua autenticado).
4. Fallback offline (sem internet, app continua operando localmente).

Não entra nesta fase:

- Sync completo multi-dispositivo (Fase 2+).
- Feed “For You”.
- Motor de recomendação avançado.

---

## 2) Modelo de dados mínimo (perfil remoto)

`ImperiumProfile` (tabela/coleção remota):

- `profileId` (uuid)
- `ownerId` (uuid do auth user)
- `displayName` (string)
- `identityVisual` (json: palette, banner, avatar/emblema)
- `realmSummary` (json: nível, título atual, risco atual, saldo resumido)
- `createdAt` (ISO8601)
- `updatedAt` (ISO8601)
- `deletedAt` (ISO8601|null)
- `version` (int)
- `deviceId` (string)

Observação: manter compatibilidade com o contrato da Fase 0.

---

## 3) Fluxos de usuário obrigatórios

### 3.1 Login

- Usuário informa email/senha (ou magic link).
- Recebe sessão válida.
- App associa sessão ao `ownerId`.

### 3.2 Primeiro acesso autenticado

- Se perfil remoto não existir: criar `ImperiumProfile`.
- Se existir: carregar perfil e aplicar identidade visual local.

### 3.3 Reabertura de app

- Sessão persistida é restaurada automaticamente.
- Usuário entra no app sem repetir login.

### 3.4 Sem internet

- Se já havia sessão local válida, app abre em modo offline.
- Operações locais continuam (Hive), com UI de estado offline.

---

## 4) Arquitetura sugerida (implementação)

### Cliente

- `AuthController` (estado de sessão)
- `ProfileController` (load/create/update do perfil)
- `SessionStore` local para token/refresh/session metadata
- `ConnectivityGate` para alternar online/offline sem bloquear navegação

### Backend (Supabase recomendado)

- Auth (email/senha e/ou magic link)
- Tabela `imperium_profiles`
- Políticas de acesso por `ownerId`

### 4.1 O que precisa existir para ter vínculo real com a nuvem

Checklist mínimo para sair de "planejado" e efetivamente conectar app + cloud:

1. Projeto Supabase criado com Auth habilitado.
2. Provedores de login habilitados (email/senha e/ou magic link).
3. Tabela `imperium_profiles` criada com índice por `owner_id`.
4. RLS (Row Level Security) habilitado com política `owner_id = auth.uid()`.
5. Chaves e URL do Supabase configuradas no app (ambiente seguro).
6. `AuthController` implementado para refletir sessão em tempo real.
7. `SessionStore` implementado para restaurar sessão ao abrir o app.
8. `ProfileController` implementado com fluxo **get-or-create**.
9. Telemetria local de falha de auth/sync conectada.
10. Teste de ponta a ponta validando login, criação do perfil e reabertura.

Sem os itens 3 + 4 + 8, existe login, mas **não existe vínculo de dados do usuário com a nuvem**.

### 4.2 SQL base sugerido (Supabase)

```sql
create table if not exists public.imperium_profiles (
  profile_id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  display_name text not null,
  identity_visual jsonb not null default '{}'::jsonb,
  realm_summary jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  version int not null default 1,
  device_id text not null
);

create unique index if not exists imperium_profiles_owner_uidx
  on public.imperium_profiles(owner_id);

alter table public.imperium_profiles enable row level security;

create policy "select own profile"
  on public.imperium_profiles for select
  using (owner_id = auth.uid());

create policy "insert own profile"
  on public.imperium_profiles for insert
  with check (owner_id = auth.uid());

create policy "update own profile"
  on public.imperium_profiles for update
  using (owner_id = auth.uid())
  with check (owner_id = auth.uid());
```

### 4.3 Contrato de integração no app (sequência mínima)

1. App inicializa Hive + providers locais.
2. App inicializa Supabase client com URL/chave do ambiente.
3. `SessionStore.restore()` tenta recuperar sessão persistida.
4. Se sessão válida: `ProfileController.getOrCreate(ownerId)`.
5. Se offline e sessão local existir: entra modo offline sem bloquear shell.
6. Quando conexão voltar: reconciliar perfil remoto e atualizar checkpoint local.

---

## 5) Critérios de pronto (Definition of Done)

A Fase 1 está concluída somente quando:

1. Usuário autentica com sucesso.
2. Usuário fecha/reabre app e mantém sessão.
3. `ImperiumProfile` é criado no primeiro login e lido nos próximos.
4. Sem internet, app não bloqueia uso local (modo offline funcional).
5. Falhas de auth/sessão são registradas em telemetria local.
6. Checklist de testes da fase está 100% verde.

---

## 6) Testes obrigatórios da fase

### Unitários

- [ ] parse/restore de sessão local
- [ ] criação de perfil quando inexistente
- [ ] decisão de fallback offline

### Integração

- [ ] login -> cria perfil -> home
- [ ] reiniciar app -> sessão restaurada
- [ ] sem rede -> abre com dados locais

### Regressão

- [ ] providers atuais de domínio continuam carregando sem login forçado
- [ ] tema/identidade não quebra o shell principal

---

## 7) Plano de execução (1–2 semanas)

## Semana 1 — Auth + Sessão

- [ ] adicionar client/provider de autenticação
- [ ] implementar login/logout
- [ ] persistir sessão local
- [ ] guardar telemetria de falhas de autenticação

**Marco M1:** usuário autentica e mantém sessão após reinício.

## Semana 2 — Perfil + Offline

- [ ] criar/read/update de `ImperiumProfile`
- [ ] acoplar identidade visual do perfil à configuração local
- [ ] garantir comportamento offline sem bloqueio
- [ ] testes de integração de fase

**Marco M2:** perfil e sessão funcionam online/offline com critérios de pronto atendidos.

---

## 8) Checklist de aprovação da Fase 1

| Item | Responsável | Status | Evidência |
|---|---|---|---|
| Escopo técnico aprovado | Produto + Tech Lead | Pendente | ata/issue |
| Modelo `ImperiumProfile` aprovado | Backend + App | Pendente | schema |
| Fluxo de login aprovado | Produto | Pendente | gravação/prints |
| Sessão persistente validada | QA/App | Pendente | teste/manual |
| Offline fallback validado | QA/App | Pendente | teste/manual |

---

## 9) Resposta objetiva: “o que deve ser feito para ter vínculo com a nuvem?”

Para haver vínculo real com a nuvem no Dominium, é obrigatório implementar este fluxo ponta a ponta:

1. Autenticar usuário no Supabase Auth.
2. Salvar/restaurar sessão localmente para manter identidade entre reinícios.
3. Criar (ou buscar) `ImperiumProfile` associado ao `ownerId` do usuário autenticado.
4. Proteger tabela com RLS por `ownerId = auth.uid()`.
5. Executar sincronização inicial de leitura/escrita respeitando metadados da Fase 0.

Se qualquer etapa acima faltar, a conexão fica parcial (ex.: login sem perfil, ou perfil sem segurança por dono).
