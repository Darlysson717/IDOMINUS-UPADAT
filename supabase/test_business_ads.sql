-- Script para testar criação de anúncio manualmente
-- Execute este script no Supabase SQL Editor para testar

-- Primeiro, verifique se há anúncios existentes
SELECT * FROM business_ads ORDER BY created_at DESC LIMIT 5;

-- Criar um anúncio de teste (substitua o user_id por um ID válido)
-- INSERT INTO business_ads (
--     user_id,
--     plan_type,
--     business_name,
--     category,
--     city,
--     whatsapp,
--     creative_text,
--     amount_paid,
--     payment_status
-- ) VALUES (
--     'SEU_USER_ID_AQUI', -- Substitua por um user_id válido
--     'basico',
--     'Oficina de Teste',
--     'Oficina mecânica',
--     'São Paulo - SP',
--     '11999999999',
--     'Anúncio de teste para verificar se aparece na home',
--     5000, -- 50 reais em centavos
--     'completed'
-- );

-- Verificar se o anúncio foi criado com expires_at correto
-- SELECT id, business_name, plan_type, is_active, payment_status, expires_at, created_at
-- FROM business_ads
-- WHERE business_name = 'Oficina de Teste'
-- ORDER BY created_at DESC LIMIT 1;

-- Verificar anúncios ativos (que devem aparecer na home)
-- SELECT id, business_name, plan_type, is_active, payment_status, expires_at
-- FROM business_ads
-- WHERE is_active = true
--   AND payment_status = 'completed'
--   AND expires_at > NOW()
-- ORDER BY created_at DESC;