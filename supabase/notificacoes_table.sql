-- Estrutura da tabela notificacoes
-- Tabela para armazenar notificações do app

CREATE TABLE IF NOT EXISTS public.notificacoes (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    tipo TEXT NOT NULL, -- e.g., 'favorito', 'mensagem', etc.
    mensagem TEXT NOT NULL,
    veiculo_id UUID REFERENCES public.veiculos(id) ON DELETE CASCADE,
    lida BOOLEAN DEFAULT FALSE,
    criado_em TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices para performance
CREATE INDEX IF NOT EXISTS idx_notificacoes_user_id ON public.notificacoes(user_id);
CREATE INDEX IF NOT EXISTS idx_notificacoes_lida ON public.notificacoes(lida);

-- Habilitar RLS
ALTER TABLE public.notificacoes ENABLE ROW LEVEL SECURITY;

-- Políticas RLS
-- Usuário pode ver suas próprias notificações
DROP POLICY IF EXISTS notificacoes_select_owner ON public.notificacoes;
CREATE POLICY notificacoes_select_owner ON public.notificacoes
FOR SELECT USING (auth.uid() = user_id);

-- Usuário pode inserir notificações para si mesmo (ou talvez para outros, mas vamos restringir)
-- Para notificações, provavelmente o sistema insere, mas para segurança, permitir insert se user_id = auth.uid()
DROP POLICY IF EXISTS notificacoes_insert_owner ON public.notificacoes;
CREATE POLICY notificacoes_insert_owner ON public.notificacoes
FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Usuário pode atualizar suas notificações (marcar como lida)
DROP POLICY IF EXISTS notificacoes_update_owner ON public.notificacoes;
CREATE POLICY notificacoes_update_owner ON public.notificacoes
FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- Usuário pode deletar suas notificações
DROP POLICY IF EXISTS notificacoes_delete_owner ON public.notificacoes;
CREATE POLICY notificacoes_delete_owner ON public.notificacoes
FOR DELETE USING (auth.uid() = user_id);