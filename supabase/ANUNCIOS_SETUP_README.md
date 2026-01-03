-- ORDEM DE EXECUÇÃO DOS SCRIPTS PARA CORREÇÃO DO ERRO DE ANÚNCIOS
-- Execute estes scripts no Supabase SQL Editor nesta ordem:

1. create_profiles_table.sql
   - Cria a tabela profiles com a coluna role

2. add_role_to_profiles.sql
   - Adiciona a coluna role se a tabela já existir

3. sync_admin_roles.sql
   - Sincroniza roles entre administrators e profiles

4. create_business_ads_table.sql
   - Cria a tabela business_ads (agora deve funcionar)

5. business_ads_functions.sql
   - Cria as funções RPC para anúncios

-- VERIFICAÇÃO
-- Após executar todos os scripts, teste com:
SELECT * FROM get_business_ads_stats();