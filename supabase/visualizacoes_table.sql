-- Estrutura da tabela visualizacoes
-- Tabela para armazenar visualizações de anúncios

-- Criar tabela se não existir
CREATE TABLE IF NOT EXISTS public.visualizacoes (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    anuncio_id TEXT NOT NULL,
    viewer_id UUID REFERENCES auth.users(id) ON DELETE SET NULL
);

-- Alterar coluna anuncio_id para TEXT se necessário
DO $$
BEGIN
    -- Dropar políticas que dependem da coluna
    DROP POLICY IF EXISTS visualizacoes_select_owner_anuncio ON public.visualizacoes;
    
    -- Alterar tipo da coluna se for UUID
    IF EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_name = 'visualizacoes' AND column_name = 'anuncio_id' AND data_type = 'uuid') THEN
        ALTER TABLE public.visualizacoes ALTER COLUMN anuncio_id TYPE TEXT;
    END IF;
    
    -- Recriar política
    CREATE POLICY visualizacoes_select_owner_anuncio ON public.visualizacoes
    FOR SELECT USING (
      EXISTS (
        SELECT 1
        FROM public.veiculos v
        WHERE v.id::text = anuncio_id
        AND v.usuario_id = auth.uid()
      )
    );
END $$;

-- Adicionar coluna criado_em se não existir
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'visualizacoes' AND column_name = 'criado_em') THEN
        ALTER TABLE public.visualizacoes ADD COLUMN criado_em TIMESTAMP WITH TIME ZONE DEFAULT NOW();
    END IF;
END $$;

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

-- Dono do anúncio pode ver visualizações do seu anúncio (já recriada acima)
-- DROP POLICY IF EXISTS visualizacoes_select_owner_anuncio ON public.visualizacoes;
-- CREATE POLICY visualizacoes_select_owner_anuncio ON public.visualizacoes
-- FOR SELECT USING (
--   EXISTS (
--     SELECT 1
--     FROM public.veiculos v
--     WHERE v.id::text = anuncio_id
--     AND v.usuario_id = auth.uid()
--   )
-- );