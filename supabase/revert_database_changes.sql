-- Script para REVERTER as correções do banco de dados
-- Execute este script no Supabase SQL Editor para voltar ao estado anterior

-- ===========================================
-- REVERTER: Restaurar coluna usuario_id
-- ===========================================

DO $$
BEGIN
    -- Verificar se a coluna user_id existe e usuario_id não existe
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'veiculos' AND column_name = 'user_id'
    ) AND NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'veiculos' AND column_name = 'usuario_id'
    ) THEN
        -- Renomear user_id de volta para usuario_id
        ALTER TABLE public.veiculos RENAME COLUMN user_id TO usuario_id;
        RAISE NOTICE 'Coluna user_id renomeada de volta para usuario_id na tabela veiculos';
    ELSE
        RAISE NOTICE 'Não foi necessário reverter a coluna (já está no estado original ou inexistente)';
    END IF;
END $$;

-- ===========================================
-- REVERTER: Restaurar políticas RLS antigas
-- ===========================================

-- Remover política nova se existir
DROP POLICY IF EXISTS "favoritos_select_owner" ON public.favoritos;

-- Recriar política antiga
CREATE POLICY "favoritos_select_owner" ON public.favoritos
FOR SELECT
USING (
  auth.uid() = user_id
  OR EXISTS (
    SELECT 1
    FROM public.veiculos v
    WHERE v.id = veiculo_id
    AND v.usuario_id = auth.uid()
  )
);

-- ===========================================
-- REVERTER: Restaurar view antiga
-- ===========================================

DROP VIEW IF EXISTS public.v_top_favoritos_15d;

CREATE OR REPLACE VIEW public.v_top_favoritos_15d AS
SELECT
    f.veiculo_id,
    v.usuario_id,
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
GROUP BY f.veiculo_id, v.usuario_id, v.cidade, v.estado, thumbnail;

-- ===========================================
-- REVERTER: Restaurar política da tabela contatos
-- ===========================================

DROP POLICY IF EXISTS "Vendedores veem contatos dos proprios anuncios" ON public.contatos;

CREATE POLICY "Vendedores veem contatos dos proprios anuncios" ON public.contatos
FOR SELECT USING (
    EXISTS (
        SELECT 1 FROM public.veiculos
        WHERE veiculos.id::TEXT = contatos.anuncio_id
        AND veiculos.usuario_id = auth.uid()
    )
);

-- ===========================================
-- VERIFICAÇÃO FINAL DO REVERT
-- ===========================================

SELECT
    'veiculos.usuario_id exists: ' || EXISTS(
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'veiculos' AND column_name = 'usuario_id'
    )::TEXT AS revert_check_1,
    'favoritos.user_id exists: ' || EXISTS(
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'favoritos' AND column_name = 'user_id'
    )::TEXT AS revert_check_2,
    'view v_top_favoritos_15d exists: ' || EXISTS(
        SELECT 1 FROM information_schema.views
        WHERE table_name = 'v_top_favoritos_15d'
    )::TEXT AS revert_check_3;