# create-mercadopago-pix

Função Edge responsável por criar cobranças PIX através da API do Mercado Pago usando o access token seguro no ambiente do Supabase.

## Configuração

1. Defina o token de acesso (nunca commit) nas secrets do Supabase:
   ```bash
   supabase secrets set MERCADOPAGO_ACCESS_TOKEN=APP_USR-7268646702366031-010217-21d260f1d0fb7f01525f219e417bd479-3107430440
   ```
2. (Opcional) Configure uma URL de notificação no app usando `--dart-define=PIX_NOTIFICATION_URL="https://seu-endpoint"` para que o backend envie webhooks.
3. Suba a função:
   ```bash
   supabase functions deploy create-mercadopago-pix
   ```
4. Localmente, use:
   ```bash
   supabase functions serve create-mercadopago-pix
   ```

## Entrada esperada

```json
{
  "amount_in_cents": 9900,
  "plan_type": "premium",
  "description": "Prioridade + topo",
  "payer_email": "comprador-teste@domin.us",
  "public_key": "APP_USR-9675e84a-034d-4edf-8da9-afc35a442193",
  "metadata": {
    "business_name": "Lava Rápido Dominus"
  }
}
```

## Resposta

```json
{
  "paymentId": 123456789,
  "status": "pending",
  "qrCode": "000201010212...",
  "copyPasteKey": "000201010212...",
  "qrCodeBase64": "data:image/png;base64,...",
  "ticketUrl": "https://www.mercadopago.com.br/...",
  "expiresAt": "2026-01-03T22:10:00.000-03:00",
  "transactionAmount": 99,
  "reference": "<uuid>"
}
```

O app móvel consome este endpoint através do `PixPaymentService`, garantindo que apenas o public key fique no cliente e o access token permaneça protegido na infraestrutura do Supabase.
