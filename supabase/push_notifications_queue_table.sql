-- Tabela para fila de notificações push
-- Armazena notificações pendentes para envio via FCM

CREATE TABLE IF NOT EXISTS public.push_notifications_queue (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    data JSONB,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'sent', 'failed')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    sent_at TIMESTAMP WITH TIME ZONE,
    error_message TEXT
);

-- Índices para performance
CREATE INDEX IF NOT EXISTS idx_push_notifications_queue_user_id ON public.push_notifications_queue(user_id);
CREATE INDEX IF NOT EXISTS idx_push_notifications_queue_status ON public.push_notifications_queue(status);
CREATE INDEX IF NOT EXISTS idx_push_notifications_queue_created_at ON public.push_notifications_queue(created_at);

-- Habilitar RLS
ALTER TABLE public.push_notifications_queue ENABLE ROW LEVEL SECURITY;

-- Políticas RLS
-- Apenas usuários autenticados podem inserir (para enviar notificações)
DROP POLICY IF EXISTS push_notifications_queue_insert_authenticated ON public.push_notifications_queue;
CREATE POLICY push_notifications_queue_insert_authenticated ON public.push_notifications_queue
FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

-- Sistema pode ler e atualizar (para processar a fila)
-- Nota: Para produção, crie uma service role ou função específica