-- Script para verificar anúncios de negócio no banco de dados

-- Ver todos os anúncios
SELECT
    id,
    user_id,
    plan_type,
    business_name,
    payment_status,
    is_active,
    created_at
FROM business_ads
ORDER BY created_at DESC;

-- Contar por plan_type
SELECT
    plan_type,
    COUNT(*) as quantidade
FROM business_ads
GROUP BY plan_type;

-- Ver anúncios por usuário
SELECT
    user_id,
    COUNT(*) as total_ads,
    COUNT(CASE WHEN plan_type = 'basico' THEN 1 END) as basico,
    COUNT(CASE WHEN plan_type = 'destaque' THEN 1 END) as destaque,
    COUNT(CASE WHEN plan_type = 'premium' THEN 1 END) as premium
FROM business_ads
GROUP BY user_id;

-- CORREÇÃO: Se o user_id do app for diferente, atualize os anúncios
-- Substitua 'SEU_USER_ID_ATUAL_DO_APP' pelo user_id que aparece nos logs do Flutter
-- UPDATE business_ads
-- SET user_id = 'SEU_USER_ID_ATUAL_DO_APP'
-- WHERE user_id = '899b6cea-0841-432d-a561-1738526a4518';