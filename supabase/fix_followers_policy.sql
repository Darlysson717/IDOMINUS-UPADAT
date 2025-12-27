-- Atualizar política RLS para permitir que vendedores vejam seus próprios seguidores
-- A política atual só permite que usuários vejam seus próprios follows (user_id = auth.uid())
-- Mas para contar seguidores, o vendedor precisa ver quem o segue (vendedor_id = auth.uid())

-- Remover política existente
DROP POLICY IF EXISTS "Users can view their own follows" ON public.vendedores_seguidos;

-- Nova política: usuários podem ver seus próprios follows OU quem os segue
CREATE POLICY "Users can view their follows and followers" ON public.vendedores_seguidos
    FOR SELECT USING (auth.uid() = user_id OR auth.uid() = vendedor_id);