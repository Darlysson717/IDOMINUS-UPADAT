-- Edge Function do Supabase para processar notificações push
-- Esta função deve ser criada no painel do Supabase em Edge Functions

-- Código TypeScript para a Edge Function (exemplo)
-- Arquivo: supabase/functions/send-push-notifications/index.ts

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Handle CORS
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      {
        global: {
          headers: { Authorization: req.headers.get('Authorization')! },
        },
      }
    )

    // Buscar notificações pendentes
    const { data: notifications, error } = await supabaseClient
      .from('push_notifications_queue')
      .select(`
        *,
        user_fcm_tokens!inner(fcm_token)
      `)
      .eq('status', 'pending')
      .limit(10)

    if (error) throw error

    // Para cada notificação, enviar via FCM
    for (const notification of notifications) {
      try {
        // Aqui você implementaria a chamada para FCM
        // Usando o Firebase Admin SDK ou HTTP request

        const fcmResponse = await fetch('https://fcm.googleapis.com/v1/projects/YOUR_PROJECT_ID/messages:send', {
          method: 'POST',
          headers: {
            'Authorization': `Bearer ${Deno.env.get('FCM_SERVER_KEY')}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            message: {
              token: notification.user_fcm_tokens.fcm_token,
              notification: {
                title: notification.title,
                body: notification.body,
              },
              data: notification.data || {},
            },
          }),
        })

        if (fcmResponse.ok) {
          // Marcar como enviada
          await supabaseClient
            .from('push_notifications_queue')
            .update({
              status: 'sent',
              sent_at: new Date().toISOString()
            })
            .eq('id', notification.id)
        } else {
          // Marcar como falha
          await supabaseClient
            .from('push_notifications_queue')
            .update({
              status: 'failed',
              error_message: `FCM error: ${fcmResponse.status}`
            })
            .eq('id', notification.id)
        }
      } catch (err) {
        // Marcar como falha
        await supabaseClient
          .from('push_notifications_queue')
          .update({
            status: 'failed',
            error_message: err.message
          })
          .eq('id', notification.id)
      }
    }

    return new Response(JSON.stringify({ success: true }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})