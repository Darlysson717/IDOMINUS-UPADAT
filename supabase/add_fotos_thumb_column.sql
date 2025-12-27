-- Adicionar coluna fotos_thumb à tabela veiculos (se não existir)
-- Esta coluna deveria existir segundo o schema documentado

-- Verificar se a coluna já existe
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_name = 'veiculos'
        AND column_name = 'fotos_thumb'
        AND table_schema = 'public'
    ) THEN
        -- Adicionar a coluna fotos_thumb
        ALTER TABLE public.veiculos ADD COLUMN fotos_thumb TEXT[];

        -- Criar índice para performance (opcional)
        CREATE INDEX IF NOT EXISTS idx_veiculos_fotos_thumb ON public.veiculos USING GIN (fotos_thumb);

        RAISE NOTICE 'Coluna fotos_thumb adicionada à tabela veiculos';
    ELSE
        RAISE NOTICE 'Coluna fotos_thumb já existe na tabela veiculos';
    END IF;
END $$;