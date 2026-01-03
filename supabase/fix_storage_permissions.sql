-- CORREÇÃO: Tornar bucket 'fotos' público para acesso às imagens
-- Execute este script no Supabase SQL Editor

-- Verificar status atual do bucket
SELECT name, public FROM storage.buckets WHERE name = 'fotos';

-- Tornar o bucket público (se não for)
UPDATE storage.buckets SET public = true WHERE name = 'fotos';

-- Verificar se funcionou
SELECT name, public FROM storage.buckets WHERE name = 'fotos';

-- Verificar objetos recentes para confirmar que existem
SELECT name, created_at FROM storage.objects
WHERE bucket_id = (SELECT id FROM storage.buckets WHERE name = 'fotos')
AND name LIKE 'anuncios/business_%'
ORDER BY created_at DESC LIMIT 5;