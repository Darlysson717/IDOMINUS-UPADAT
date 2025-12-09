# Configuração de Notificações Push

Este guia explica como configurar notificações push que funcionam mesmo quando o usuário não está logado no app.

## 📋 Pré-requisitos

1. **Conta Firebase**: Crie um projeto no [Firebase Console](https://console.firebase.google.com/)
2. **Configuração Android/iOS**: Adicione o Firebase ao seu app Flutter
3. **Supabase Edge Functions**: Configure as Edge Functions no Supabase

## 🚀 Passos de Configuração

### 1. Firebase Setup

1. Acesse [Firebase Console](https://console.firebase.google.com/)
2. Crie um novo projeto ou selecione um existente
3. Adicione o app Android/iOS ao projeto
4. Baixe o `google-services.json` (Android) e `GoogleService-Info.plist` (iOS)
5. Coloque os arquivos na pasta apropriada do Flutter

### 2. Supabase Tables

Execute estes SQLs no seu painel Supabase (SQL Editor):

```sql
-- Tabela para tokens FCM
\i supabase/user_fcm_tokens_table.sql

-- Tabela para fila de notificações push
\i supabase/push_notifications_queue_table.sql
```

### 3. Edge Function

1. No painel Supabase, vá para **Edge Functions**
2. Crie uma nova função chamada `send-push-notifications`
3. Use o código do arquivo `supabase/edge_function_send_push_notifications.sql`
4. Configure as variáveis de ambiente:
   - `FCM_SERVER_KEY`: Sua chave do servidor FCM (Firebase Console → Project Settings → Cloud Messaging)

### 4. Configuração do App

O app já está configurado com:
- ✅ Firebase Core e Messaging
- ✅ Token FCM salvo automaticamente no login
- ✅ Notificações push enfileiradas
- ✅ Interface local mantida

## 🔧 Como Funciona

1. **Login**: Token FCM é salvo no Supabase
2. **Ação**: Notificação é inserida na fila
3. **Processamento**: Edge Function envia via FCM
4. **Recebimento**: Push notification aparece no dispositivo

## 🧪 Testando

1. Execute o app em um dispositivo/emulador
2. Faça login com uma conta
3. De outra conta, favorite um anúncio
4. A notificação deve aparecer mesmo se o app estiver fechado

## 📝 Notas Importantes

- As notificações locais ainda funcionam quando o usuário está logado
- O sistema de fila garante que nenhuma notificação seja perdida
- Tokens FCM são automaticamente atualizados quando mudam
- Edge Functions processam notificações em background

## 🔍 Troubleshooting

- **Notificações não chegam**: Verifique se o token FCM foi salvo corretamente
- **Edge Function falha**: Verifique logs no painel Supabase
- **FCM rejeita**: Confirme a chave do servidor e configuração do Firebase