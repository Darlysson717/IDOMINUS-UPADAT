-- Criar tabela de anúncios de negócio
CREATE TABLE IF NOT EXISTS business_ads (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    plan_type TEXT NOT NULL CHECK (plan_type IN ('basico', 'destaque', 'premium')),
    business_name TEXT,
    category TEXT,
    city TEXT,
    whatsapp TEXT,
    website TEXT,
    creative_text TEXT,
    image_url TEXT,
    amount_paid INTEGER NOT NULL, -- em centavos
    payment_status TEXT NOT NULL DEFAULT 'pending' CHECK (payment_status IN ('pending', 'completed', 'failed', 'cancelled')),
    payment_id TEXT UNIQUE, -- ID do pagamento PIX
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT true,
    views_count INTEGER DEFAULT 0,
    clicks_count INTEGER DEFAULT 0
);

-- Políticas RLS (Row Level Security)
ALTER TABLE business_ads ENABLE ROW LEVEL SECURITY;

-- Política para usuários verem seus próprios anúncios
CREATE POLICY "Users can view own business ads" ON business_ads
    FOR SELECT USING (auth.uid() = user_id);

-- Política para usuários inserirem seus próprios anúncios
CREATE POLICY "Users can insert own business ads" ON business_ads
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Política para usuários atualizarem seus próprios anúncios
CREATE POLICY "Users can update own business ads" ON business_ads
    FOR UPDATE USING (auth.uid() = user_id);

-- Política para admins verem todos os anúncios
CREATE POLICY "Admins can view all business ads" ON business_ads
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE profiles.id = auth.uid()
            AND profiles.role = 'admin'
        )
    );

-- Política para admins atualizarem todos os anúncios
CREATE POLICY "Admins can update all business ads" ON business_ads
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE profiles.id = auth.uid()
            AND profiles.role = 'admin'
        )
    );

-- Política para todos os usuários verem anúncios ativos de outros usuários
CREATE POLICY "Users can view active business ads from others" ON business_ads
    FOR SELECT USING (
        is_active = true
        AND payment_status = 'completed'
        AND expires_at > NOW()
    );

-- Índices para performance
CREATE INDEX IF NOT EXISTS idx_business_ads_user_id ON business_ads(user_id);
CREATE INDEX IF NOT EXISTS idx_business_ads_plan_type ON business_ads(plan_type);
CREATE INDEX IF NOT EXISTS idx_business_ads_is_active ON business_ads(is_active);
CREATE INDEX IF NOT EXISTS idx_business_ads_expires_at ON business_ads(expires_at);
CREATE INDEX IF NOT EXISTS idx_business_ads_city ON business_ads(city);

-- Função para calcular data de expiração baseada no plano
CREATE OR REPLACE FUNCTION calculate_ad_expiry(plan_type TEXT)
RETURNS TIMESTAMP WITH TIME ZONE AS $$
BEGIN
    RETURN CASE
        WHEN plan_type = 'basico' THEN NOW() + INTERVAL '30 days'
        WHEN plan_type = 'destaque' THEN NOW() + INTERVAL '30 days'
        WHEN plan_type = 'premium' THEN NOW() + INTERVAL '30 days'
        ELSE NOW() + INTERVAL '30 days'
    END;
END;
$$ LANGUAGE plpgsql;

-- Trigger para definir expires_at automaticamente
CREATE OR REPLACE FUNCTION set_ad_expiry()
RETURNS TRIGGER AS $$
BEGIN
    NEW.expires_at := calculate_ad_expiry(NEW.plan_type);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_set_ad_expiry
    BEFORE INSERT ON business_ads
    FOR EACH ROW
    EXECUTE FUNCTION set_ad_expiry();

-- Função para verificar anúncios expirados (pode ser chamada por um job)
CREATE OR REPLACE FUNCTION deactivate_expired_ads()
RETURNS INTEGER AS $$
DECLARE
    updated_count INTEGER;
BEGIN
    UPDATE business_ads
    SET is_active = false
    WHERE expires_at < NOW() AND is_active = true;

    GET DIAGNOSTICS updated_count = ROW_COUNT;
    RETURN updated_count;
END;
$$ LANGUAGE plpgsql;