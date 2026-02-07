import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

serve(async (req) => {
  try {
    const { amount_in_cents, plan_type, description, metadata, payer_email } = await req.json()

    const clientId = Deno.env.get('EFIPAY_CLIENT_ID')
    const clientSecret = Deno.env.get('EFIPAY_CLIENT_SECRET')
    const accountId = Deno.env.get('EFIPAY_ACCOUNT_ID')
    const sandbox = Deno.env.get('EFIPAY_SANDBOX') === 'true'

    if (!clientId || !clientSecret || !accountId) {
      throw new Error('Credenciais EFI não configuradas')
    }

    // Obter token de acesso
    const authResponse = await fetch(`https://pix.api.efipay.com.br/oauth/token`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Basic ${btoa(`${clientId}:${clientSecret}`)}`
      },
      body: JSON.stringify({ grant_type: 'client_credentials' })
    })

    if (!authResponse.ok) {
      throw new Error('Falha na autenticação EFI')
    }

    const authData = await authResponse.json()
    const accessToken = authData.access_token

    // Criar cobrança
    const chargeBody = {
      calendario: { expiracao: 3600 },
      valor: { original: (amount_in_cents / 100).toFixed(2) },
      chave: '',
      solicitacaoPagador: description,
      infoAdicionais: [
        { nome: 'Plano', valor: plan_type },
        ...Object.entries(metadata || {}).map(([k, v]) => ({ nome: k, valor: String(v) }))
      ]
    }

    if (payer_email) {
      chargeBody.devedor = { email: payer_email }
    }

    const chargeResponse = await fetch(`https://pix.api.efipay.com.br/v2/cob`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${accessToken}`
      },
      body: JSON.stringify(chargeBody)
    })

    if (!chargeResponse.ok) {
      throw new Error('Falha ao criar cobrança PIX')
    }

    const charge = await chargeResponse.json()

    if (!charge.txid) {
      throw new Error('Resposta inválida da EFI')
    }

    // Gerar QR Code
    const qrResponse = await fetch(`https://pix.api.efipay.com.br/v2/loc/${charge.loc.id}/qrcode`, {
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${accessToken}`
      }
    })

    if (!qrResponse.ok) {
      throw new Error('Falha ao gerar QR Code')
    }

    const qrData = await qrResponse.json()

    return new Response(
      JSON.stringify({
        txid: charge.txid,
        qrcode: qrData.qrcode,
        qrcode_text: qrData.qrcode_text,
        valor: charge.valor.original,
        expiracao: new Date(Date.now() + 3600000).toISOString(),
      }),
      { headers: { 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    )
  }
})