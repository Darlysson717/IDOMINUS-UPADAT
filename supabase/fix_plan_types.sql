-- Script para diagnosticar e corrigir problemas com plan_type nos anúncios

-- 1. Verificar todos os anúncios e seus plan_types
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

-- 2. Contar anúncios por plan_type (incluindo nulos)
SELECT
    plan_type,
    COUNT(*) as quantidade
FROM business_ads
GROUP BY plan_type
ORDER BY plan_type;

-- 3. Verificar se há anúncios com plan_type null ou vazio
SELECT
    id,
    business_name,
    plan_type,
    created_at
FROM business_ads
WHERE plan_type IS NULL OR plan_type = '';

-- 4. CORREÇÃO: Atualizar anúncios com plan_type incorreto
-- (Descomente e ajuste conforme necessário)

-- UPDATE business_ads
-- SET plan_type = 'basico'
-- WHERE plan_type IS NULL OR plan_type = '';

-- Ou se quiser definir baseado em alguma lógica:
-- UPDATE business_ads
-- SET plan_type = 'basico'
-- WHERE id = 'ID_ESPECIFICO';

-- 5. Verificar novamente após correção
-- SELECT plan_type, COUNT(*) FROM business_ads GROUP BY plan_type;