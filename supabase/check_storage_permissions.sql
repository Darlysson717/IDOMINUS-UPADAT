-- Verificar políticas do bucket 'fotos' no Supabase Storage
-- Execute estes comandos no painel do Supabase (SQL Editor) para verificar permissões

-- Verificar se o bucket 'fotos' existe e suas configurações
SELECT * FROM storage.buckets WHERE name = 'fotos';

-- Verificar objetos no bucket 'fotos' (para ver se as imagens estão lá)
SELECT * FROM storage.objects WHERE bucket_id = (SELECT id FROM storage.buckets WHERE name = 'fotos') LIMIT 10;

-- Verificar políticas RLS no bucket
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual
FROM pg_policies
WHERE schemaname = 'storage' AND tablename = 'objects';

-- Verificar se há políticas específicas para o bucket 'fotos'
SELECT * FROM storage.bucket_policies WHERE bucket_name = 'fotos';