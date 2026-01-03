-- Sincronizar roles de admin entre tabelas administrators e profiles
-- Execute este script após adicionar a coluna role à tabela profiles

-- Atualizar perfis de administradores para role 'admin'
UPDATE public.profiles
SET role = 'admin'
WHERE id IN (
    SELECT user_id
    FROM public.administrators
    WHERE user_id IS NOT NULL
);

-- Garantir que todos os outros perfis tenham role 'user'
UPDATE public.profiles
SET role = 'user'
WHERE role IS NULL OR role NOT IN ('user', 'admin');

-- Verificar se a sincronização funcionou
-- SELECT p.id, p.name, p.role, a.email as admin_email
-- FROM public.profiles p
-- LEFT JOIN public.administrators a ON p.id = a.user_id
-- WHERE p.role = 'admin' OR a.user_id IS NOT NULL;