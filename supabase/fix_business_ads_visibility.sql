-- Política para permitir que todos os usuários vejam anúncios ativos de outros usuários
-- Execute este script no painel do Supabase (SQL Editor) para corrigir o problema dos anúncios não aparecerem

CREATE POLICY "Users can view active business ads from others" ON business_ads
    FOR SELECT USING (
        is_active = true
        AND payment_status = 'completed'
        AND expires_at > NOW()
    );