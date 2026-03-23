import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static const String _taskName = 'check_notifications';
  static const String _taskId = 'periodic_check_notifications';

  static Future<void> initialize() async {
    if (kIsWeb) return; // Notificações locais não funcionam na web

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

    if (Platform.isAndroid) {
      await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
      await Workmanager().registerPeriodicTask(
        _taskId,
        _taskName,
        frequency: const Duration(minutes: 15),
        initialDelay: const Duration(minutes: 1),
      );
    }
  }

  static Future<void> showNotification({
    required String title,
    required String body,
    int id = 0,
  }) async {
    if (kIsWeb) return; // Notificações locais não funcionam na web

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

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    await _ensureSupabaseInitialized();
    await NotificationService.initialize();
    await NotificationService.checkPendingNotifications();
    return true;
  });
}

// Função auxiliar para verificar notificações pendentes
Future<void> _checkPendingNotifications() async {
  try {
    // Verificar se há usuário logado
    final userId = await _getNotificationUserId();
    if (userId == null) return;

    // Buscar notificações não lidas
    final notifications = await Supabase.instance.client
        .from('notificacoes')
        .select()
        .eq('user_id', userId)
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

        final ids = notifications
          .map((n) => n['id']?.toString())
          .where((id) => id != null && id!.isNotEmpty)
          .cast<String>()
          .toList();
        if (ids.isNotEmpty) {
        await Supabase.instance.client
            .from('notificacoes')
            .update({'lida': true})
          .filter('id', 'in', _buildInFilter(ids));
      }
    }
  } catch (e) {
    print("Erro ao verificar notificações pendentes: $e");
  }
}

Future<void> _ensureSupabaseInitialized() async {
  if (Supabase.instance.client.auth.currentSession != null) return;
  if (Supabase.instance.client.auth.currentUser != null) return;
  try {
    await Supabase.initialize(
      url: 'https://xwusadbehasobjzkqsgk.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inh3dXNhZGJlaGFzb2Jqemtxc2drIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTY1OTAzMzgsImV4cCI6MjA3MjE2NjMzOH0.oupGPTAuMGkpdZkWZFd2wA5c5Jx22yMcdBAJaoJqJoE',
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
        autoRefreshToken: true,
      ),
      debug: false,
    );
  } catch (_) {
    // Ignorar erro de init duplicada
  }
}

Future<String?> _getNotificationUserId() async {
  final currentUser = Supabase.instance.client.auth.currentUser;
  if (currentUser != null) return currentUser.id;
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('notif_user_id');
}

String _buildInFilter(List<String> values) {
  final sanitized = values
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty)
      .map((value) => '"$value"')
      .join(',');
  return '($sanitized)';
}