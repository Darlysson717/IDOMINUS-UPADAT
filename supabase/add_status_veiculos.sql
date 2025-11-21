-- Adiciona a coluna de status para controlar anúncios ativos/inativos
alter table public.veiculos
    add column if not exists status text not null default 'ativo';

-- Garante que todos os registros antigos fiquem como ativos
update public.veiculos
   set status = 'ativo'
 where status is null;

-- Índice auxiliar para filtros frequentes por status
create index if not exists veiculos_status_idx
    on public.veiculos (status);
