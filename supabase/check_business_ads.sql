-- Verificar anúncios de negócio no banco de dados
-- Execute este script para ver se os anúncios existem e têm imagens

-- Ver anúncios ativos COM URLs de imagem
SELECT id, business_name, image_url, created_at, plan_type
FROM business_ads
WHERE is_active = true AND payment_status = 'completed'
AND image_url IS NOT NULL AND image_url != ''
ORDER BY created_at DESC;

-- Ver anúncios ativos SEM imagem
SELECT id, business_name, image_url, created_at, plan_type
FROM business_ads
WHERE is_active = true AND payment_status = 'completed'
AND (image_url IS NULL OR image_url = '')
ORDER BY created_at DESC;

-- Verificar se as imagens existem no storage
SELECT name, created_at, size
FROM storage.objects
WHERE bucket_id = (SELECT id FROM storage.buckets WHERE name = 'fotos')
AND name LIKE 'anuncios/business_%'
ORDER BY created_at DESC;