-- Tabela para armazenar tokens FCM dos usuários
-- Necessária para enviar notificações push mesmo quando o usuário não está logado

CREATE TABLE IF NOT EXISTS public.user_fcm_tokens (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    fcm_token TEXT NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, fcm_token)
);

-- Índices para performance
CREATE INDEX IF NOT EXISTS idx_user_fcm_tokens_user_id ON public.user_fcm_tokens(user_id);
CREATE INDEX IF NOT EXISTS idx_user_fcm_tokens_token ON public.user_fcm_tokens(fcm_token);

-- Habilitar RLS
ALTER TABLE public.user_fcm_tokens ENABLE ROW LEVEL SECURITY;

-- Políticas RLS
-- Usuário pode ver apenas seus próprios tokens
DROP POLICY IF EXISTS user_fcm_tokens_select_owner ON public.user_fcm_tokens;
CREATE POLICY user_fcm_tokens_select_owner ON public.user_fcm_tokens
FOR SELECT USING (auth.uid() = user_id);

-- Usuário pode inserir apenas seus próprios tokens
DROP POLICY IF EXISTS user_fcm_tokens_insert_owner ON public.user_fcm_tokens;
CREATE POLICY user_fcm_tokens_insert_owner ON public.user_fcm_tokens
FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Usuário pode atualizar apenas seus próprios tokens
DROP POLICY IF EXISTS user_fcm_tokens_update_owner ON public.user_fcm_tokens;
CREATE POLICY user_fcm_tokens_update_owner ON public.user_fcm_tokens
FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- Usuário pode deletar apenas seus próprios tokens
DROP POLICY IF EXISTS user_fcm_tokens_delete_owner ON public.user_fcm_tokens;
CREATE POLICY user_fcm_tokens_delete_owner ON public.user_fcm_tokens
FOR DELETE USING (auth.uid() = user_id);