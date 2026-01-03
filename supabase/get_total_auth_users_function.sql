-- Função RPC para contar usuários autenticados
-- Execute este script no Supabase SQL Editor

CREATE OR REPLACE FUNCTION get_total_auth_users()
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    user_count INTEGER;
BEGIN
    -- Conta todos os usuários na tabela auth.users
    SELECT COUNT(*) INTO user_count FROM auth.users;
    RETURN user_count;
END;
$$;

-- Conceder permissão para usuários autenticados chamarem a função
GRANT EXECUTE ON FUNCTION get_total_auth_users() TO authenticated;