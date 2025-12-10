-- Garante coluna de timestamp nos favoritos para filtros por período
alter table public.favoritos
    add column if not exists created_at timestamptz not null default now();

-- Normaliza registros antigos que possam ter ficado com NULL
update public.favoritos
   set created_at = coalesce(created_at, now())
 where created_at is null;

-- Índice para acelerar consultas por data
create index if not exists favoritos_created_at_idx
    on public.favoritos (created_at);
