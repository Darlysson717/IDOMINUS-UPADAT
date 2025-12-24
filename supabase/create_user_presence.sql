-- Cria tabela para presença de usuários (heartbeat)
create table if not exists user_presence (
  user_id uuid primary key references auth.users(id) on delete cascade,
  last_seen timestamptz not null default now(),
  meta jsonb
);

-- Index para consultas por last_seen
create index if not exists idx_user_presence_last_seen on user_presence (last_seen);

-- Ativa RLS e políticas mínimas
alter table user_presence enable row level security;

-- Autenticados podem inserir apenas sua própria linha
create policy user_presence_insert on user_presence
  for insert
  with check (auth.uid() = user_id);

-- Autenticados podem atualizar apenas sua própria linha
create policy user_presence_update on user_presence
  for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- Permitir leitura para usuários autenticados (para mostrar contadores)
create policy user_presence_select on user_presence
  for select
  using (auth.role() = 'authenticated');
