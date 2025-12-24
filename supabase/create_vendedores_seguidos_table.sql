-- Criar tabela para vendedores seguidos pelos usuários
CREATE TABLE IF NOT EXISTS public.vendedores_seguidos (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    vendedor_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    criado_em TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    -- Garantir que um usuário não siga o mesmo vendedor duas vezes
    UNIQUE(user_id, vendedor_id),

    -- Um usuário não pode seguir a si mesmo
    CHECK (user_id != vendedor_id)
);

-- Índices para performance
CREATE INDEX IF NOT EXISTS idx_vendedores_seguidos_user_id ON public.vendedores_seguidos(user_id);
CREATE INDEX IF NOT EXISTS idx_vendedores_seguidos_vendedor_id ON public.vendedores_seguidos(vendedor_id);

-- Políticas RLS (Row Level Security)
ALTER TABLE public.vendedores_seguidos ENABLE ROW LEVEL SECURITY;

-- Política: usuários podem ver apenas seus próprios follows
CREATE POLICY "Users can view their own follows" ON public.vendedores_seguidos
    FOR SELECT USING (auth.uid() = user_id);

-- Política: usuários podem inserir apenas seus próprios follows
CREATE POLICY "Users can insert their own follows" ON public.vendedores_seguidos
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Política: usuários podem deletar apenas seus próprios follows
CREATE POLICY "Users can delete their own follows" ON public.vendedores_seguidos
    FOR DELETE USING (auth.uid() = user_id);

-- Política: usuários podem atualizar apenas seus próprios follows
CREATE POLICY "Users can update their own follows" ON public.vendedores_seguidos
    FOR UPDATE USING (auth.uid() = user_id);