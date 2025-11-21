-- Permite que o dono do anúncio enxergue favoritos recebidos
create policy if not exists favoritos_select_owner on public.favoritos
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
