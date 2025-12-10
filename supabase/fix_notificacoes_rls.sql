-- Atualizar política RLS para notificações
-- Permitir que usuários autenticados insiram notificações para qualquer usuário
-- (necessário para notificações do sistema como favoritos, verificações, etc.)

DROP POLICY IF EXISTS notificacoes_insert_owner ON public.notificacoes;
CREATE POLICY notificacoes_insert_authenticated ON public.notificacoes
FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);