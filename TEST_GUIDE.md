# 🧪 Guia de Teste - Sistema de Verificação de Vendedores

## 🎯 Como Testar o Sistema (Com Painel Administrativo)

### 📋 Dados de Teste

#### CNPJ Válido para Teste:
```
12.345.678/0001-95
```
**Este CNPJ é válido** e pode ser usado para testar o sistema.

### 🚀 Passos para Teste Completo:

1. **Execute o script SQL** no Supabase (se ainda não fez)
2. **Inicie o app:**
   ```bash
   flutter run -d chrome --debug
   ```

3. **Como Vendedor:**
   - Faça login como vendedor
   - Vá para Perfil → "Verificar Loja"
   - Use CNPJ: `12.345.678/0001-95`
   - Clique "Selecionar Documento"
   - Envie a solicitação

4. **Como Administrador:**
   - No menu lateral (Perfil), clique em **"Painel Admin"**
   - Veja a solicitação pendente
   - Clique **"Aprovar"** ou **"Rejeitar"**

### 🔧 Modo Desenvolvimento Ativo

O sistema está configurado em **modo desenvolvimento**:
- ✅ **Upload de documento é simulado** (não requer arquivo real)
- ✅ **CNPJ de teste é aceito**
- ✅ **Painel admin mostra todas as solicitações**

### 📊 Status de Teste

Após enviar:
- ✅ Formulário aceito
- ✅ Dados salvos no Supabase
- ✅ Status: "Pendente"
- ✅ Aparece no Painel Admin

### 🎯 Funcionalidades do Painel Admin:

- ✅ **Listar todas as verificações** (não apenas as próprias)
- ✅ **Ver detalhes**: CNPJ, documento, data, status
- ✅ **Aprovar solicitações** com 1 clique
- ✅ **Rejeitar solicitações** com motivo obrigatório
- ✅ **Atualizar lista** automaticamente
- ✅ **Feedback visual** das ações

### 🔄 Para Produção:
Quando quiser usar dados reais, siga as instruções no `TEST_GUIDE.md` para remover o modo desenvolvimento.

### 📝 Comandos Úteis:

```sql
-- Ver todas as solicitações
SELECT * FROM seller_verifications ORDER BY created_at DESC;

-- Aprovar teste
UPDATE seller_verifications
SET status = 'approved', reviewed_at = NOW()
WHERE cnpj = '12345678000195';

-- Verificar status
SELECT status, reviewed_at FROM seller_verifications WHERE user_id = 'user-id';
```

**🎉 Agora você tem um sistema completo de verificação com painel administrativo!** 🚗✨</content>
<parameter name="filePath">c:\Users\darly\Desktop\triunvirato car\triunvirato_car_marketplace\TEST_GUIDE.md