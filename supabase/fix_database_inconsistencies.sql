-- Script de correção das inconsistências no banco de dados
-- Execute este script no Supabase SQL Editor para corrigir os problemas identificados

-- ===========================================
-- CORREÇÃO 1: Padronizar nome da coluna user_id
-- ===========================================

-- Verificar se existe coluna usuario_id na tabela veiculos
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'veiculos' AND column_name = 'usuario_id'
    ) THEN
        -- Renomear coluna usuario_id para user_id
        ALTER TABLE public.veiculos RENAME COLUMN usuario_id TO user_id;
        RAISE NOTICE 'Coluna usuario_id renomeada para user_id na tabela veiculos';
    ELSE
        RAISE NOTICE 'Coluna usuario_id não encontrada ou já foi corrigida';
    END IF;
END $$;

-- ===========================================
-- CORREÇÃO 2: Recriar políticas RLS com nomes corretos
-- ===========================================

-- Remover política antiga se existir
DROP POLICY IF EXISTS "favoritos_select_owner" ON public.favoritos;

-- Recriar política com nome correto da coluna
CREATE POLICY "favoritos_select_owner" ON public.favoritos
FOR SELECT
USING (
  auth.uid() = user_id
  OR EXISTS (
    SELECT 1
    FROM public.veiculos v
    WHERE v.id = veiculo_id
    AND v.user_id = auth.uid()
  )
);

-- ===========================================
-- CORREÇÃO 3: Recriar view com coluna correta
-- ===========================================

DROP VIEW IF EXISTS public.v_top_favoritos_15d;

CREATE OR REPLACE VIEW public.v_top_favoritos_15d AS
SELECT
    f.veiculo_id,
    v.user_id,
    v.cidade,
    v.estado,
    COALESCE(
      NULLIF(MIN(v.titulo) FILTER (WHERE v.titulo IS NOT NULL AND v.titulo <> ''), ''),
      CONCAT_WS(' ',
        MIN(v.marca) FILTER (WHERE v.marca IS NOT NULL AND v.marca <> ''),
        MIN(v.modelo) FILTER (WHERE v.modelo IS NOT NULL AND v.modelo <> ''),
        MIN(v.versao) FILTER (WHERE v.versao IS NOT NULL AND v.versao <> '')
      )
    ) AS titulo,
    (
      CASE
        WHEN v.fotos IS NOT NULL AND ARRAY_LENGTH(v.fotos, 1) > 0
        THEN v.fotos[1]
        ELSE NULL
      END
    ) AS thumbnail,
    COUNT(f.*)::INT AS total_favoritos,
    MIN(f.created_at) AS primeiro_favorito,
    MAX(f.created_at) AS ultimo_favorito
FROM public.favoritos f
JOIN public.veiculos v ON v.id = f.veiculo_id
WHERE f.created_at >= (NOW() - INTERVAL '15 days')
  AND COALESCE(v.status, 'ativo') = 'ativo'
GROUP BY f.veiculo_id, v.user_id, v.cidade, v.estado, thumbnail;

-- ===========================================
-- CORREÇÃO 4: Recriar política da tabela contatos
-- ===========================================

DROP POLICY IF EXISTS "Vendedores veem contatos dos proprios anuncios" ON public.contatos;

CREATE POLICY "Vendedores veem contatos dos proprios anuncios" ON public.contatos
FOR SELECT USING (
    EXISTS (
        SELECT 1 FROM public.veiculos
        WHERE veiculos.id::TEXT = contatos.anuncio_id
        AND veiculos.user_id = auth.uid()
    )
);

-- ===========================================
-- VERIFICAÇÃO FINAL
-- ===========================================

-- Verificar se todas as correções foram aplicadas
SELECT
    'veiculos.user_id exists: ' || EXISTS(
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'veiculos' AND column_name = 'user_id'
    )::TEXT AS check_1,
    'favoritos.user_id exists: ' || EXISTS(
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'favoritos' AND column_name = 'user_id'
    )::TEXT AS check_2,
    'view v_top_favoritos_15d exists: ' || EXISTS(
        SELECT 1 FROM information_schema.views
        WHERE table_name = 'v_top_favoritos_15d'
    )::TEXT AS check_3;