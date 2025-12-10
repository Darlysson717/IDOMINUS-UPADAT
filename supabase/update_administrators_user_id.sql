-- Atualizar tabela administrators para incluir user_id
-- Isso permite notificar admins diretamente

-- Adicionar coluna user_id se não existir
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'administrators' AND column_name = 'user_id') THEN
        ALTER TABLE public.administrators ADD COLUMN user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
    END IF;
END $$;

-- Atualizar registros existentes com user_id baseado no email
-- Nota: Isso assume que os emails correspondem a usuários existentes
UPDATE public.administrators
SET user_id = auth.users.id
FROM auth.users
WHERE administrators.email = auth.users.email
AND administrators.user_id IS NULL;

-- Índice para performance
CREATE INDEX IF NOT EXISTS idx_administrators_user_id ON public.administrators(user_id);

-- Atualizar RLS se necessário (assumindo que já existe)
-- Políticas para administrators (se aplicável)