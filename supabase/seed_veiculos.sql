-- Verificar e popular tabela veiculos com dados de exemplo
-- Execute este script no Supabase SQL Editor

-- Primeiro, verificar quantos veículos existem
SELECT COUNT(*) as total_veiculos FROM veiculos;

-- Se não houver veículos, inserir alguns dados de exemplo
INSERT INTO veiculos (
    titulo, descricao, preco, marca, modelo, versao, ano_fab, km, cidade, estado,
    cor, combustivel, cambio, portas, direcao, carroceria, status, user_id
) VALUES
    ('Honda Civic 2020', 'Carro em excelente estado, único dono', 85000.00, 'Honda', 'Civic', 'EXL', 2020, 45000, 'São Paulo', 'SP', 'Prata', 'Flex', 'Automático', 4, 'Hidráulica', 'Sedan', 'ativo', '00000000-0000-0000-0000-000000000001'),
    ('Toyota Corolla 2019', 'Muito econômico e confiável', 78000.00, 'Toyota', 'Corolla', 'XEI', 2019, 55000, 'Rio de Janeiro', 'RJ', 'Branco', 'Flex', 'Manual', 4, 'Hidráulica', 'Sedan', 'ativo', '00000000-0000-0000-0000-000000000001'),
    ('Volkswagen Golf 2018', 'Esportivo e confortável', 65000.00, 'Volkswagen', 'Golf', 'Highline', 2018, 62000, 'Belo Horizonte', 'MG', 'Preto', 'Gasolina', 'Automático', 4, 'Elétrica', 'Hatchback', 'ativo', '00000000-0000-0000-0000-000000000001'),
    ('Ford Fiesta 2021', 'Compacto e moderno', 55000.00, 'Ford', 'Fiesta', 'Titanium', 2021, 35000, 'Porto Alegre', 'RS', 'Azul', 'Flex', 'Manual', 4, 'Elétrica', 'Hatchback', 'ativo', '00000000-0000-0000-0000-000000000001'),
    ('Chevrolet Onix 2022', 'O carro mais vendido do Brasil', 62000.00, 'Chevrolet', 'Onix', 'LTZ', 2022, 28000, 'Salvador', 'BA', 'Vermelho', 'Flex', 'Automático', 4, 'Elétrica', 'Sedan', 'ativo', '00000000-0000-0000-0000-000000000001')
ON CONFLICT DO NOTHING;

-- Verificar novamente após inserção
SELECT COUNT(*) as total_veiculos_apos_seed FROM veiculos;