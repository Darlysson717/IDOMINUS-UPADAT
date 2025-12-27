-- Verificar se a coluna 'veiculos_fotos' existe na tabela veiculos
-- Execute este script no painel do Supabase > SQL Editor

-- Verificar colunas da tabela veiculos
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'veiculos'
AND table_schema = 'public'
ORDER BY ordinal_position;

-- Verificar se existe uma tabela chamada 'veiculos_fotos'
SELECT table_name
FROM information_schema.tables
WHERE table_name = 'veiculos_fotos'
AND table_schema = 'public';

-- Se a coluna 'veiculos_fotos' não existir, pode ser necessário criá-la ou ajustar o código
-- A tabela veiculos atualmente tem as colunas 'fotos' e 'fotos_thumb' como arrays de texto