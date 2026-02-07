// @ts-ignore
import { serve } from "https://deno.land/std@0.224.0/http/server.ts";

// Declare Deno for TypeScript in non-Deno environments
declare const Deno: {
  env: {
    get(key: string): string | undefined;
  };
};

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return new Response(
      JSON.stringify({ message: "Method not allowed" }),
      { status: 405, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }

  const accessToken = Deno.env.get("MERCADOPAGO_ACCESS_TOKEN");
  if (!accessToken) {
    return new Response(
      JSON.stringify({ message: "MERCADOPAGO_ACCESS_TOKEN não configurado" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }

  let body: Record<string, unknown> | null = null;
  try {
    body = await req.json();
  } catch (_) {
    // ignore
  }

  if (!body) {
    return new Response(
      JSON.stringify({ message: "Corpo da requisição inválido" }),
      { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }

  const amountInCents = Number(body["amount_in_cents"] ?? 0);
  if (amountInCents <= 0) {
    return new Response(
      JSON.stringify({ message: "amount_in_cents precisa ser maior que zero" }),
      { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }

  const description = (body["description"] as string | undefined) ?? "Pagamento PIX";
  const planType = (body["plan_type"] as string | undefined) ?? "standard";
  const externalReference = (body["external_reference"] as string | undefined) ??
    (typeof crypto.randomUUID === "function" ? crypto.randomUUID() : `${Date.now()}`);
  const payerEmail = (body["payer_email"] as string | undefined) ?? "pagador-teste@domin.us";
  const notificationUrl = (body["notification_url"] as string | undefined) ?? undefined;

  const metadataRaw = body["metadata"] as Record<string, unknown> | undefined;
  const metadata = {
    plan_type: planType,
    public_key: body["public_key"],
    ...(metadataRaw ?? {}),
  };

  const payload = {
    transaction_amount: Number((amountInCents / 100).toFixed(2)),
    description,
    payment_method_id: "pix",
    payer: { email: payerEmail },
    notification_url: notificationUrl,
    external_reference: externalReference,
    metadata,
  };

  // Remove campos vazios/undefined
  const sanitizedPayload = JSON.parse(JSON.stringify(payload));

  const mpResponse = await fetch("https://api.mercadopago.com/v1/payments", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${accessToken}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify(sanitizedPayload),
  });

  let mpData: Record<string, unknown> | null = null;
  try {
    mpData = await mpResponse.json();
  } catch (_) {
    // ignore
  }

  if (!mpResponse.ok || !mpData) {
    return new Response(
      JSON.stringify({
        message: "Falha ao criar pagamento PIX",
        details: mpData,
      }),
      { status: mpResponse.status, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }

  const poi = mpData["point_of_interaction"] as Record<string, unknown> | undefined;
  const transactionData = poi?.["transaction_data"] as Record<string, unknown> | undefined;

  const transactionDetails = mpData["transaction_details"] as Record<string, unknown> | undefined;

  const responseBody = {
    paymentId: mpData["id"],
    status: mpData["status"],
    qrCode: (transactionData?.["qr_code"] as string | undefined) ?? "",
    qrCodeBase64: transactionData?.["qr_code_base64"],
    copyPasteKey: (transactionData?.["qr_code"] as string | undefined) ?? "",
    ticketUrl: transactionData?.["ticket_url"] ?? transactionDetails?.["external_resource_url"],
    expiresAt: mpData["date_of_expiration"] ?? mpData["date_created"],
    transactionAmount: mpData["transaction_amount"],
    reference: mpData["external_reference"],
  };

  return new Response(
    JSON.stringify(responseBody),
    { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } },
  );
});
