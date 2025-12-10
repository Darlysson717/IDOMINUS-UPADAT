# 🚨 ERRO: Tabela antiga detectada!

## ❌ Problema:
Você tem uma tabela `seller_verifications` antiga com a estrutura completa (razao_social, nome_fantasia, etc.) em vez da versão simplificada.

## ✅ Solução: Recriar a Tabela

### 📋 Script SQL Atualizado:

O script foi modificado para **dropar a tabela antiga** e criar a nova estrutura simplificada.

### 🚀 Como Executar:

1. **Acesse Supabase Dashboard:**
   - https://supabase.com/dashboard
   - Selecione seu projeto

2. **SQL Editor:**
   - Menu lateral → "SQL Editor"
   - "New Query"

3. **Cole o Script Atualizado:**
   - Abra `supabase_setup.sql` (foi atualizado)
   - Copie tudo
   - Cole no editor SQL

4. **Execute:**
   - Botão "Run" ou Ctrl+Enter

### ⚠️ IMPORTANTE:
**Este script vai apagar dados existentes!** Se você tinha dados importantes na tabela antiga, faça backup primeiro.

### ✅ Verificar se funcionou:

Após executar, teste esta query:

```sql
SELECT column_name
FROM information_schema.columns
WHERE table_name = 'seller_verifications'
ORDER BY ordinal_position;
```

**Resultado esperado (versão simplificada):**
- ✅ id
- ✅ user_id
- ✅ cnpj
- ✅ **documento_url** ← Agora deve aparecer!
- ✅ status
- ✅ rejection_reason
- ✅ created_at
- ✅ reviewed_at

**NÃO deve ter:**
- ❌ razao_social
- ❌ nome_fantasia
- ❌ endereco
- ❌ telefone
- ❌ horario_funcionamento
- ❌ documentos_urls

### 🎯 Próximos Passos:

1. Execute o script atualizado
2. Verifique as colunas
3. Feche e reabra o app Flutter
4. Teste novamente - deve funcionar!

**Agora a tabela terá a estrutura correta!** 🔧✨</content>
<parameter name="filePath">c:\Users\darly\Desktop\triunvirato car\triunvirato_car_marketplace\ERRO_SQL_FIX.md