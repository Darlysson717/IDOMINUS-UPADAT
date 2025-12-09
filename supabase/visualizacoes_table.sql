-- Estrutura da tabela visualizacoes
-- Tabela para armazenar visualizações de anúncios

CREATE TABLE IF NOT EXISTS public.visualizacoes (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    anuncio_id TEXT NOT NULL,
    viewer_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    criado_em TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices para performance
CREATE INDEX IF NOT EXISTS idx_visualizacoes_anuncio_id ON public.visualizacoes(anuncio_id);
CREATE INDEX IF NOT EXISTS idx_visualizacoes_viewer_id ON public.visualizacoes(viewer_id);
CREATE INDEX IF NOT EXISTS idx_visualizacoes_criado_em ON public.visualizacoes(criado_em);

-- Habilitar RLS
ALTER TABLE public.visualizacoes ENABLE ROW LEVEL SECURITY;

-- Políticas RLS
-- Qualquer um pode inserir visualizações (para não logados também)
DROP POLICY IF EXISTS visualizacoes_insert ON public.visualizacoes;
CREATE POLICY visualizacoes_insert ON public.visualizacoes
FOR INSERT WITH CHECK (true);

-- Usuário pode ver suas próprias visualizações
DROP POLICY IF EXISTS visualizacoes_select_owner ON public.visualizacoes;
CREATE POLICY visualizacoes_select_owner ON public.visualizacoes
FOR SELECT USING (auth.uid() = viewer_id OR auth.uid() IS NULL);

-- Dono do anúncio pode ver visualizações do seu anúncio
DROP POLICY IF EXISTS visualizacoes_select_owner_anuncio ON public.visualizacoes;
CREATE POLICY visualizacoes_select_owner_anuncio ON public.visualizacoes
FOR SELECT USING (
  EXISTS (
    SELECT 1
    FROM public.veiculos v
    WHERE v.id::text = anuncio_id
    AND v.usuario_id = auth.uid()
  )
);