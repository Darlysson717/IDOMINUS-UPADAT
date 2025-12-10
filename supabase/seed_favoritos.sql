-- Popula favoritos com dados de teste (ajuste IDs conforme necessário)
insert into public.favoritos (user_id, veiculo_id, created_at) values
  ('00000000-0000-0000-0000-000000000001', '1', now() - interval '1 day')
  on conflict do nothing;
