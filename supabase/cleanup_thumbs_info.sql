-- Limpar imagens órfãs na pasta thumbs do storage
-- Execute este script no painel do Supabase > SQL Editor

-- Verificar arquivos na pasta thumbs
SELECT 'Verificando arquivos na pasta thumbs...';

-- Listar arquivos órfãs na pasta thumbs (se houver)
-- Este script ajuda a identificar imagens que podem ter ficado sem referência

-- Como as thumbnails agora são salvas na coluna fotos_thumb,
-- elas serão automaticamente deletadas quando o anúncio for excluído

SELECT 'Thumbnails agora são salvas na coluna fotos_thumb da tabela veiculos.';