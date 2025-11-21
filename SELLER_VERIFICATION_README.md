# Sistema de Verificação de Vendedores (Versão Simplificada)

Este sistema implementa validação mínima para vendedores que precisam comprovar que possuem uma loja física, respeitando a LGPD ao coletar apenas dados essenciais.

## 🚀 Funcionalidades Implementadas

### ✅ Validação de CNPJ
- Algoritmo brasileiro completo para validação de CNPJ
- Formatação automática durante digitação
- Verificação de dígitos verificadores

### ✅ Formulário Simplificado
- **Apenas 2 campos obrigatórios:**
  - CNPJ da empresa
  - Alvará de Funcionamento (upload de imagem)

### ✅ Status de Verificação
- **Incompleto**: Formulário não preenchido
- **Pendente**: Aguardando análise
- **Aprovado**: Verificado e liberado
- **Rejeitado**: Solicitação negada com motivo

### ✅ Controle de Acesso
- Bloqueio de publicação até aprovação
- Tela explicativa com status atual
- Redirecionamento automático para verificação

## 🛠️ Configuração no Supabase

Execute o script `supabase_setup.sql` no seu painel do Supabase para criar:

1. **Tabela `seller_verifications`** (estrutura simplificada)
2. **Bucket `seller-documents`** para upload de arquivos
3. **Políticas de segurança RLS**
4. **Função `is_seller_verified()`**

## 📋 Dados Coletados (Mínimo Possível)

### Obrigatórios:
- **CNPJ**: Para identificação da empresa (exemplo: 12.345.678/0001-95)
- **Alvará de Funcionamento**: Documento comprobatório

### Dados Derivados:
- **Status da verificação**
- **Data de criação/análise**
- **Motivo de rejeição** (se aplicável)

## 🔒 Privacidade e LGPD

### ✅ Dados Mínimos
- Coletamos apenas o essencial para validação
- Não solicitamos dados pessoais desnecessários
- Não armazenamos informações sensíveis

### ✅ Segurança
- **Row Level Security (RLS)** ativado
- Usuários só veem suas próprias verificações
- Uploads restritos ao próprio usuário
- Dados criptografados em trânsito e repouso

### ✅ Transparência
- Usuário sabe exatamente quais dados são coletados
- Finalidade clara: validação para venda no marketplace
- Dados retidos apenas enquanto necessário

## 📱 Como Usar

### Para Vendedores:
1. Acesse "Verificar Loja" no perfil
2. Digite o CNPJ da empresa (exemplo para teste: 12.345.678/0001-95)
3. Faça upload do Alvará de Funcionamento
4. Aguarde aprovação (até 48h)

### Para Administradores:
```sql
-- Ver todas as solicitações pendentes
SELECT * FROM seller_verifications WHERE status = 'pending';

-- Aprovar vendedor
UPDATE seller_verifications SET status = 'approved', reviewed_at = NOW() WHERE user_id = 'uuid-aqui';

-- Rejeitar com motivo
UPDATE seller_verifications SET status = 'rejected', rejection_reason = 'Motivo da rejeição', reviewed_at = NOW() WHERE user_id = 'uuid-aqui';
```

## 🎯 Benefícios

- ✅ **LGPD Compliance**: Coleta mínima de dados
- ✅ **Rapidez**: Processo simples e rápido
- ✅ **Confiança**: Usuários sabem que estão comprando de lojistas reais
- ✅ **Qualidade**: Vendedores verificados são mais sérios
- ✅ **Conformidade**: Atende requisitos legais com mínimo impacto

## 🔄 Próximos Passos (Opcionais)

Se precisar expandir no futuro:
- Integração com Receita Federal para validação automática
- Múltiplos documentos por tipo de negócio
- Sistema de notificações por email
- Dashboard administrativo completo

## 📊 Estrutura da Tabela

```sql
seller_verifications:
- id (UUID, PK)
- user_id (UUID, FK para auth.users)
- cnpj (TEXT)
- documento_url (TEXT) -- URL do Alvará
- status (ENUM: incomplete/pending/approved/rejected)
- rejection_reason (TEXT, opcional)
- created_at (TIMESTAMP)
- reviewed_at (TIMESTAMP, opcional)
```

O sistema está **100% funcional** e **respeita a LGPD** ao coletar apenas o mínimo necessário! 🎉