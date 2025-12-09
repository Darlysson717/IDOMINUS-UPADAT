import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  static Future<void> initialize() async {
    // Inicializar Firebase
    await Firebase.initializeApp();

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

    // Solicitar permissões para notificações
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Configurar handlers para mensagens FCM
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  static Future<String?> getFCMToken() async {
    return await _firebaseMessaging.getToken();
  }

  static Future<void> saveFCMTokenToSupabase() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final token = await getFCMToken();
    if (token != null) {
      await Supabase.instance.client
          .from('user_fcm_tokens')
          .upsert({
            'user_id': user.id,
            'fcm_token': token,
            'updated_at': DateTime.now().toIso8601String(),
          });
    }
  }

  static Future<void> removeFCMTokenFromSupabase() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final token = await getFCMToken();
    if (token != null) {
      await Supabase.instance.client
          .from('user_fcm_tokens')
          .delete()
          .eq('fcm_token', token);
    }
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

  static void _handleForegroundMessage(RemoteMessage message) {
    showNotification(
      title: message.notification?.title ?? 'Nova notificação',
      body: message.notification?.body ?? '',
    );
  }

  static void _handleBackgroundMessage(RemoteMessage message) {
    // Mensagem tratada quando o app volta do background
    print('Mensagem recebida em background: ${message.notification?.title}');
  }
}

// Handler para mensagens quando o app está completamente fechado
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Mensagem recebida em background: ${message.notification?.title}');
}