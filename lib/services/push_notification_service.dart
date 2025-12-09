import 'package:supabase_flutter/supabase_flutter.dart';

class PushNotificationService {
  static final _supabase = Supabase.instance.client;

  // Enviar notificação push para um usuário específico
  static Future<void> sendPushNotification({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Buscar tokens FCM do usuário
      final tokensResponse = await _supabase
          .from('user_fcm_tokens')
          .select('fcm_token')
          .eq('user_id', userId);

      if (tokensResponse.isEmpty) {
        print('Nenhum token FCM encontrado para o usuário $userId');
        return;
      }

      // Aqui seria chamada uma Edge Function do Supabase para enviar FCM
      // Por enquanto, vamos simular inserindo na tabela de notificações
      // que será processada por uma Edge Function

      await _supabase.from('push_notifications_queue').insert({
        'user_id': userId,
        'title': title,
        'body': body,
        'data': data,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      });

      print('Notificação push enfileirada para usuário $userId');
    } catch (e) {
      print('Erro ao enviar notificação push: $e');
    }
  }

  // Método auxiliar para enviar notificação de favorito
  static Future<void> sendFavoriteNotification(String vehicleOwnerId, String vehicleTitle) async {
    await sendPushNotification(
      userId: vehicleOwnerId,
      title: 'Novo favorito!',
      body: 'Seu anúncio "$vehicleTitle" foi favoritado!',
      data: {
        'type': 'favorite',
        'vehicle_title': vehicleTitle,
      },
    );
  }

  // Método auxiliar para enviar notificação de verificação aprovada
  static Future<void> sendVerificationApprovedNotification(String userId) async {
    await sendPushNotification(
      userId: userId,
      title: 'Verificação aprovada!',
      body: 'Sua solicitação de verificação de vendedor foi aprovada!',
      data: {
        'type': 'verification_approved',
      },
    );
  }

  // Método auxiliar para enviar notificação de verificação rejeitada
  static Future<void> sendVerificationRejectedNotification(String userId, String reason) async {
    await sendPushNotification(
      userId: userId,
      title: 'Verificação rejeitada',
      body: 'Sua solicitação de verificação foi rejeitada. Motivo: $reason',
      data: {
        'type': 'verification_rejected',
        'reason': reason,
      },
    );
  }
}