-- Tabela para registrar presença (heartbeat)
-- Uso: clientes autenticados fazem UPSERT { user_id, last_seen, meta }

create table if not exists user_presence (
  user_id uuid primary key,
  last_seen timestamptz not null default now(),
  meta jsonb
);

create index if not exists idx_user_presence_last_seen on user_presence (last_seen);

-- Função auxiliar (opcional) para contar usuários online (últimos 2 minutos)
create or replace function count_users_online(p_minutes int default 2)
returns bigint language sql stable as $$
  select count(*)::bigint from user_presence where last_seen > now() - (p_minutes || ' minutes')::interval;
$$;

-- Exemplos de policies (ajustar conforme seu RLS/roles):
-- 1) Autenticados podem inserir/upsertar apenas sua própria linha
-- create policy "allow_upsert_own_presence" on user_presence for insert, update using (auth.role() = 'authenticated' and auth.uid() = user_id);

-- 2) Leitura: permitir que usuários autenticados leiam contagem (se desejar, restrinja por role)
-- create policy "allow_select_authenticated" on user_presence for select using (auth.role() = 'authenticated');

-- NOTA: políticas acima são sugestões e devem ser adaptadas ao seu modelo de segurança.
-- Também recomendo criar uma policy que impeça escrita de 'meta' arbitrário ou limitar taxa de escrita.
