-- Script de configuração do sistema de verificação de vendedores (versão simplificada)
-- Este script recria a tabela do zero para garantir a estrutura correta
-- Execute este script no painel do Supabase > SQL Editor

-- ⚠️ REMOVER TABELA ANTIGA (se existir)
DROP TABLE IF EXISTS seller_verifications CASCADE;

-- Criar tabela de administradores
CREATE TABLE administrators (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    email TEXT NOT NULL UNIQUE,
    created_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_super_admin BOOLEAN DEFAULT FALSE
);

-- Inserir o administrador principal
INSERT INTO administrators (email, is_super_admin)
VALUES ('darlison.pires.corporativo@gmail.com', TRUE)
ON CONFLICT (email) DO NOTHING;

-- Habilitar RLS para administradores
ALTER TABLE administrators ENABLE ROW LEVEL SECURITY;

-- Políticas para administradores
-- Todos podem ver administradores (para verificação de permissões)
DROP POLICY IF EXISTS "Anyone can view administrators" ON administrators;
CREATE POLICY "Anyone can view administrators" ON administrators
    FOR SELECT USING (true);

-- Apenas super admin pode inserir novos administradores
DROP POLICY IF EXISTS "Super admin can insert administrators" ON administrators;
CREATE POLICY "Super admin can insert administrators" ON administrators
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM administrators
            WHERE email = auth.email() AND is_super_admin = TRUE
        )
    );

-- Apenas super admin pode deletar administradores
DROP POLICY IF EXISTS "Super admin can delete administrators" ON administrators;
CREATE POLICY "Super admin can delete administrators" ON administrators
    FOR DELETE USING (
        EXISTS (
            SELECT 1 FROM administrators
            WHERE email = auth.email() AND is_super_admin = TRUE
        )
    );

-- Criar tabela com estrutura simplificada
CREATE TABLE seller_verifications (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    cnpj TEXT NOT NULL,
    store_name TEXT NOT NULL, -- Nome da loja (da conta Google)
    documento_url TEXT NOT NULL, -- URL do Alvará de Funcionamento
    status TEXT NOT NULL DEFAULT 'incomplete' CHECK (status IN ('incomplete', 'pending', 'approved', 'rejected')),
    rejection_reason TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    reviewed_at TIMESTAMP WITH TIME ZONE,

    -- Garantir que cada usuário tenha apenas uma verificação ativa
    UNIQUE(user_id)
);

-- Criar índices para melhor performance
CREATE INDEX IF NOT EXISTS idx_seller_verifications_user_id ON seller_verifications(user_id);
CREATE INDEX IF NOT EXISTS idx_seller_verifications_status ON seller_verifications(status);
CREATE INDEX IF NOT EXISTS idx_seller_verifications_created_at ON seller_verifications(created_at);

-- Habilitar RLS (Row Level Security)
ALTER TABLE seller_verifications ENABLE ROW LEVEL SECURITY;

-- Políticas de segurança
-- Usuários podem ver apenas suas próprias verificações
DROP POLICY IF EXISTS "Users can view own verification" ON seller_verifications;
CREATE POLICY "Users can view own verification" ON seller_verifications
    FOR SELECT USING (auth.uid() = user_id);

-- Usuários podem inserir apenas suas próprias verificações
DROP POLICY IF EXISTS "Users can insert own verification" ON seller_verifications;
CREATE POLICY "Users can insert own verification" ON seller_verifications
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Usuários podem atualizar apenas suas próprias verificações
DROP POLICY IF EXISTS "Users can update own verification" ON seller_verifications;
CREATE POLICY "Users can update own verification" ON seller_verifications
    FOR UPDATE USING (auth.uid() = user_id);

-- Admins podem ver todas as verificações
DROP POLICY IF EXISTS "Admins can view all verifications" ON seller_verifications;
CREATE POLICY "Admins can view all verifications" ON seller_verifications
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM administrators
            WHERE email = auth.email()
        )
    );

-- Admins podem atualizar qualquer verificação
DROP POLICY IF EXISTS "Admins can update all verifications" ON seller_verifications;
CREATE POLICY "Admins can update all verifications" ON seller_verifications
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM administrators
            WHERE email = auth.email()
        )
    );

-- Criar bucket para documentos (se não existir)
INSERT INTO storage.buckets (id, name, public)
VALUES ('seller-documents', 'seller-documents', false)
ON CONFLICT (id) DO NOTHING;

-- Políticas para o bucket de documentos
DROP POLICY IF EXISTS "Users can upload own documents" ON storage.objects;
CREATE POLICY "Users can upload own documents" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'seller-documents'
        AND auth.uid()::text = (storage.foldername(name))[1]
    );

DROP POLICY IF EXISTS "Users can view own documents" ON storage.objects;
CREATE POLICY "Users can view own documents" ON storage.objects
    FOR SELECT USING (
        bucket_id = 'seller-documents'
        AND auth.uid()::text = (storage.foldername(name))[1]
    );

-- Função para verificar se usuário está aprovado
CREATE OR REPLACE FUNCTION is_seller_verified(user_uuid UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM seller_verifications
        WHERE user_id = user_uuid
        AND status = 'approved'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;