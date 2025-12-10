-- Permite que o dono do anúncio enxergue favoritos recebidos
-- Observação: PostgreSQL não suporta "IF NOT EXISTS" em CREATE POLICY.
-- Primeiro derrubamos a política (se existir) e depois criamos novamente.
drop policy if exists favoritos_select_owner on public.favoritos;
create policy favoritos_select_owner on public.favoritos
for select
using (
  auth.uid() = user_id
  or exists (
    select 1
      from public.veiculos v
     where v.id = veiculo_id
        and v.usuario_id = auth.uid()
  )
);

-- Garantir que RLS esteja habilitado na tabela favoritos
alter table public.favoritos enable row level security;

-- Permitir que o dono do favorito remova seus registros
drop policy if exists favoritos_delete_owner on public.favoritos;
create policy favoritos_delete_owner on public.favoritos
for delete
using (auth.uid() = user_id);

-- Permitir que o usuário insira seus próprios favoritos
drop policy if exists favoritos_insert_owner on public.favoritos;
create policy favoritos_insert_owner on public.favoritos
for insert
with check (auth.uid() = user_id);

-- Permitir que o usuário atualize seus próprios favoritos
drop policy if exists favoritos_update_owner on public.favoritos;
create policy favoritos_update_owner on public.favoritos
for update
using (auth.uid() = user_id)
with check (auth.uid() = user_id);
