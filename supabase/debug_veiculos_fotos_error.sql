-- Investigar o erro 42703 (column does not exist) relacionado à coluna 'veiculos_fotos'
-- Execute este script no painel do Supabase > SQL Editor

-- 1. Verificar todas as colunas da tabela veiculos
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_name = 'veiculos'
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 2. Verificar se existe alguma tabela ou view chamada 'veiculos_fotos'
SELECT table_type, table_name
FROM information_schema.tables
WHERE table_name LIKE '%veiculos_fotos%'
AND table_schema = 'public';

-- 3. Verificar todas as views que referenciam a tabela veiculos
SELECT viewname, definition
FROM pg_views
WHERE definition ILIKE '%veiculos%'
AND schemaname = 'public';

-- 4. Verificar triggers na tabela veiculos
SELECT trigger_name, event_manipulation, event_object_table, action_statement
FROM information_schema.triggers
WHERE event_object_table = 'veiculos'
AND trigger_schema = 'public';

-- 5. Verificar funções que podem referenciar 'veiculos_fotos'
SELECT routine_name, routine_definition
FROM information_schema.routines
WHERE routine_definition ILIKE '%veiculos_fotos%'
AND routine_schema = 'public';

-- 6. Verificar políticas RLS que podem ter referências incorretas
SELECT schemaname, tablename, policyname, cmd, qual
FROM pg_policies
WHERE tablename = 'veiculos'
AND schemaname = 'public';