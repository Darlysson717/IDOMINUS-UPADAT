import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:workmanager/workmanager.dart'; // Removido temporariamente
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    // Configurar notificações locais
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings();

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(settings);

    // WorkManager removido temporariamente para evitar problemas
    // await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
  }

  static Future<void> showNotification({
    required String title,
    required String body,
    int id = 0,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'channel_id',
      'Notificações',
      importance: Importance.high,
      priority: Priority.high,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(id, title, body, details);
  }

  static Future<void> checkPendingNotifications() async {
    await _checkPendingNotifications();
  }
}

// Função auxiliar para verificar notificações pendentes
Future<void> _checkPendingNotifications() async {
  try {
    // Verificar se há usuário logado
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    // Buscar notificações não lidas
    final notifications = await Supabase.instance.client
        .from('notificacoes')
        .select()
        .eq('user_id', user.id)
        .eq('lida', false)
        .order('criado_em', ascending: false)
        .limit(5); // Últimas 5 não lidas

    if (notifications.isNotEmpty) {
      // Mostrar notificação local com resumo
      final count = notifications.length;
      final latestNotification = notifications.first;

      await NotificationService.showNotification(
        title: 'Você tem $count notificação(ões) nova(s)',
        body: latestNotification['mensagem'],
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      );
    }
  } catch (e) {
    print("Erro ao verificar notificações pendentes: $e");
  }
}