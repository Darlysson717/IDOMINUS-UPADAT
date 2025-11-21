-- Tabela para rastrear cliques em contato
create table if not exists public.contatos (
    id uuid default gen_random_uuid() primary key,
    anuncio_id text not null,
    user_id uuid references auth.users(id) on delete cascade,
    created_at timestamp with time zone default now()
);

-- Políticas RLS
alter table public.contatos enable row level security;

-- Vendedores podem ver contatos dos próprios anúncios
create policy "Vendedores veem contatos dos proprios anuncios" on public.contatos
    for select using (
        exists (
            select 1 from public.veiculos
            where veiculos.id::text = contatos.anuncio_id
            and veiculos.usuario_id = auth.uid()
        )
    );

-- Usuários podem inserir contatos (compradores clicando)
create policy "Usuarios podem inserir contatos" on public.contatos
    for insert with check (auth.uid() = user_id);