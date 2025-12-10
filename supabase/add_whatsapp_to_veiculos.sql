-- Adicionar coluna WhatsApp na tabela veiculos
alter table public.veiculos
add column if not exists whatsapp text;

-- Comentário na coluna
comment on column public.veiculos.whatsapp is 'Número do WhatsApp do vendedor para contato';