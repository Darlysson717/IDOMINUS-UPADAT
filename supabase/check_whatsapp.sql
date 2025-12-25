-- Verificar se a coluna whatsapp existe
SELECT column_name FROM information_schema.columns
WHERE table_name = 'veiculos' AND column_name = 'whatsapp';

-- Ver anúncios que têm WhatsApp cadastrado
SELECT id, titulo, whatsapp FROM veiculos
WHERE whatsapp IS NOT NULL AND whatsapp != '';

-- Inserir um anúncio de teste com WhatsApp (se quiser testar)
-- Substitua os valores pelos seus dados
/*
INSERT INTO veiculos (
    titulo, descricao, preco, whatsapp, cidade, estado,
    user_id, status, criado_em
) VALUES (
    'Carro de Teste WhatsApp',
    'Anúncio para testar funcionalidade do WhatsApp',
    50000.00,
    '11999999999', -- Seu número de WhatsApp
    'São Paulo',
    'SP',
    (SELECT auth.uid()), -- Substitua pelo seu user ID
    'ativo',
    NOW()
);
*/