-- Função RPC para buscar user_id pelo email
-- Execute este script no Supabase SQL Editor

CREATE OR REPLACE FUNCTION get_user_id_by_email(user_email TEXT)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    found_user_id UUID;
BEGIN
    -- Busca o user_id na tabela auth.users pelo email
    SELECT id INTO found_user_id
    FROM auth.users
    WHERE email = LOWER(user_email);

    -- Retorna o user_id se encontrado, senão null
    RETURN found_user_id;
END;
$$;

-- Conceder permissão para usuários autenticados chamarem a função
GRANT EXECUTE ON FUNCTION get_user_id_by_email(TEXT) TO authenticated;