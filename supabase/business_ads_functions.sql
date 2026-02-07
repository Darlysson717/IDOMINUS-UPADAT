-- Funções RPC para gerenciar contadores de anúncios

-- Função para incrementar visualizações
CREATE OR REPLACE FUNCTION increment_ad_views(ad_id UUID)
RETURNS VOID AS $$
BEGIN
    UPDATE business_ads
    SET views_count = views_count + 1
    WHERE id = ad_id AND is_active = true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Função para incrementar cliques
CREATE OR REPLACE FUNCTION increment_ad_clicks(ad_id UUID)
RETURNS VOID AS $$
BEGIN
    UPDATE business_ads
    SET clicks_count = clicks_count + 1
    WHERE id = ad_id AND is_active = true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Função para obter anúncios ativos por localização
CREATE OR REPLACE FUNCTION get_active_ads_by_location(
    user_city TEXT DEFAULT NULL,
    user_lat DOUBLE PRECISION DEFAULT NULL,
    user_lng DOUBLE PRECISION DEFAULT NULL,
    radius_km INTEGER DEFAULT 50
)
RETURNS TABLE (
    id UUID,
    plan_type TEXT,
    business_name TEXT,
    category TEXT,
    city TEXT,
    whatsapp TEXT,
    website TEXT,
    creative_text TEXT,
    image_url TEXT,
    views_count INTEGER,
    clicks_count INTEGER,
    created_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        ba.id,
        ba.plan_type,
        ba.business_name,
        ba.category,
        ba.city,
        ba.whatsapp,
        ba.website,
        ba.creative_text,
        ba.image_url,
        ba.views_count,
        ba.clicks_count,
        ba.created_at
    FROM business_ads ba
    WHERE ba.is_active = true
      AND ba.payment_status = 'completed'
      AND ba.expires_at > NOW()
    ORDER BY
        CASE
            WHEN ba.plan_type = 'premium' THEN 1
            WHEN ba.plan_type = 'destaque' THEN 2
            WHEN ba.plan_type = 'basico' THEN 3
        END,
        ba.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Função para obter estatísticas gerais dos anúncios (para admins)
CREATE OR REPLACE FUNCTION get_business_ads_stats()
RETURNS TABLE (
    total_ads BIGINT,
    active_ads BIGINT,
    total_revenue BIGINT,
    ads_by_plan JSON,
    recent_ads JSON
) AS $$
DECLARE
    stats_record RECORD;
    recent_ads_json JSON;
BEGIN
    -- Estatísticas gerais
    SELECT
        COUNT(*) as total,
        COUNT(*) FILTER (WHERE is_active = true AND expires_at > NOW()) as active,
        COALESCE(SUM(amount_paid), 0) as revenue
    INTO stats_record
    FROM business_ads;

    -- Obter anúncios recentes separadamente
    SELECT COALESCE(
        json_agg(
            json_build_object(
                'id', id,
                'business_name', business_name,
                'plan_type', plan_type,
                'created_at', created_at,
                'is_active', is_active
            )
        ),
        '[]'::json
    )
    INTO recent_ads_json
    FROM (
        SELECT id, business_name, plan_type, created_at, is_active
        FROM business_ads
        ORDER BY created_at DESC
        LIMIT 10
    ) recent;

    -- Retornar estatísticas
    RETURN QUERY SELECT
        stats_record.total,
        stats_record.active,
        stats_record.revenue,
        json_build_object(
            'basico', COUNT(*) FILTER (WHERE plan_type = 'basico'),
            'destaque', COUNT(*) FILTER (WHERE plan_type = 'destaque'),
            'premium', COUNT(*) FILTER (WHERE plan_type = 'premium')
        ),
        recent_ads_json
    FROM business_ads
    LIMIT 1;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Função para deletar anúncio de negócio (com verificação de ownership)
-- Primeiro dropar a função existente se ela existir
DROP FUNCTION IF EXISTS delete_business_ad(UUID, UUID);

CREATE OR REPLACE FUNCTION delete_business_ad(
    ad_id UUID,
    p_user_id UUID
)
RETURNS BOOLEAN AS $$
DECLARE
    ad_record RECORD;
BEGIN
    -- Verificar se o anúncio existe e pertence ao usuário
    SELECT * INTO ad_record
    FROM business_ads
    WHERE id = ad_id AND user_id = p_user_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Anúncio não encontrado ou você não tem permissão para excluí-lo';
    END IF;

    -- Deletar o anúncio do banco (a imagem será deletada pelo código Dart)
    DELETE FROM business_ads
    WHERE id = ad_id AND user_id = p_user_id;

    -- Verificar se foi realmente deletado
    IF NOT EXISTS (SELECT 1 FROM business_ads WHERE id = ad_id) THEN
        RETURN TRUE;
    ELSE
        RETURN FALSE;
    END IF;

END;
$$ LANGUAGE plpgsql SECURITY DEFINER;