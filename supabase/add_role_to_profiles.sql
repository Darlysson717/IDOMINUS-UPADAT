-- Adicionar coluna role à tabela profiles se ela não existir
-- Execute este script após criar a tabela profiles

-- Adicionar coluna role com valor padrão 'user'
ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS role TEXT DEFAULT 'user' CHECK (role IN ('user', 'admin'));

-- Atualizar perfis existentes para ter role 'user' se estiverem null
UPDATE public.profiles
SET role = 'user'
WHERE role IS NULL;

-- Adicionar comentário à coluna
COMMENT ON COLUMN public.profiles.role IS 'Role do usuário: user ou admin';