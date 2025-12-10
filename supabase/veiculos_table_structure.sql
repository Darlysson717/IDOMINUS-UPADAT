-- Estrutura completa da tabela veiculos
-- Este script documenta a estrutura atual da tabela para referência

-- ⚠️ IMPORTANTE: Esta é uma documentação da estrutura EXISTENTE
-- Não execute este script se a tabela já existe!

/*
CREATE TABLE public.veiculos (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    titulo TEXT NOT NULL,
    descricao TEXT,
    preco DECIMAL(10,2),
    marca TEXT,
    modelo TEXT,
    versao TEXT,
    ano_fab INTEGER,
    km INTEGER,
    cidade TEXT,
    estado TEXT,
    cor TEXT,
    combustivel TEXT,
    cambio TEXT,
    portas INTEGER,
    direcao TEXT,
    carroceria TEXT,
    farois TEXT,
    ar_condicionado BOOLEAN DEFAULT FALSE,
    vidros_dianteiros BOOLEAN DEFAULT FALSE,
    vidros_traseiros BOOLEAN DEFAULT FALSE,
    travas_eletricas BOOLEAN DEFAULT FALSE,
    bancos_couro BOOLEAN DEFAULT FALSE,
    multimidia BOOLEAN DEFAULT FALSE,
    rodas_liga BOOLEAN DEFAULT FALSE,
    airbags INTEGER DEFAULT 0,
    abs BOOLEAN DEFAULT FALSE,
    controle_estabilidade BOOLEAN DEFAULT FALSE,
    sensor_estacionamento BOOLEAN DEFAULT FALSE,
    manual_chave BOOLEAN DEFAULT FALSE,
    ipva_pago BOOLEAN DEFAULT FALSE,
    whatsapp TEXT,
    fotos TEXT[],
    fotos_thumb TEXT[],
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    status TEXT DEFAULT 'ativo' CHECK (status IN ('ativo', 'inativo', 'vendido')),
    criado_em TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    atualizado_em TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices para performance
CREATE INDEX IF NOT EXISTS idx_veiculos_user_id ON public.veiculos(user_id);
CREATE INDEX IF NOT EXISTS idx_veiculos_status ON public.veiculos(status);
CREATE INDEX IF NOT EXISTS idx_veiculos_marca ON public.veiculos(marca);
CREATE INDEX IF NOT EXISTS idx_veiculos_cidade ON public.veiculos(cidade);
CREATE INDEX IF NOT EXISTS idx_veiculos_estado ON public.veiculos(estado);
CREATE INDEX IF NOT EXISTS idx_veiculos_criado_em ON public.veiculos(criado_em);

-- Habilitar RLS
ALTER TABLE public.veiculos ENABLE ROW LEVEL SECURITY;

-- Políticas de segurança
CREATE POLICY "Anyone can view active vehicles" ON public.veiculos
    FOR SELECT USING (status = 'ativo');

CREATE POLICY "Users can insert own vehicles" ON public.veiculos
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own vehicles" ON public.veiculos
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own vehicles" ON public.veiculos
    FOR DELETE USING (auth.uid() = user_id);
*/