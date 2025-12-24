import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Serviço que gerencia presença do usuário e conta de usuários online
class PresenceService {
  PresenceService._();
  static final PresenceService _i = PresenceService._();
  factory PresenceService() => _i;

  final _onlineCount = ValueNotifier<int>(0);
  ValueNotifier<int> get onlineCount => _onlineCount;

  Timer? _heartbeatTimer;
  Timer? _countPollTimer;
  Timer? _messageTimer;
  bool _started = false;

  /// Start presence service. Idempotent.
  Future<void> start({int heartbeatSeconds = 30, int pollSeconds = 30}) async {
    if (_started) return;
    _started = true;

    // Primeiro passo: consultar contagem inicial
    await _refreshCount();

    // Poll counts periodicamente (fallback quando Realtime não estiver ativado)
    _countPollTimer = Timer.periodic(
      Duration(seconds: pollSeconds),
      (_) => _refreshCount(),
    );

    // Heartbeat para atualizar last_seen do usuário
    _heartbeatTimer = Timer.periodic(
      Duration(seconds: heartbeatSeconds),
      (_) => _sendHeartbeat(),
    );

    // Timer para mostrar mensagem a cada 20 minutos se houver +50 usuários
    _messageTimer = Timer.periodic(
      const Duration(minutes: 20),
      (_) => _checkAndShowMessage(),
    );

    // Enviar imediatamente
    await _sendHeartbeat();
  }

  Future<void> stop() async {
    if (!_started) return;
    _started = false;
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _countPollTimer?.cancel();
    _countPollTimer = null;
    _messageTimer?.cancel();
    _messageTimer = null;
  }

  Future<void> _refreshCount() async {
    try {
      final since = DateTime.now()
          .toUtc()
          .subtract(const Duration(minutes: 10))
          .toIso8601String();
      final res = await Supabase.instance.client
          .from('user_presence')
          .select('user_id')
          .gt('last_seen', since);
      final list = (res as List?) ?? [];
      _onlineCount.value = list.length;
    } catch (e) {
      // Não bloquear por erro; manter contador anterior
    }
  }

  Future<void> _sendHeartbeat() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      // upsert (inserir ou atualizar last_seen)
      await Supabase.instance.client.from('user_presence').upsert({
        'user_id': user.id,
        'last_seen': DateTime.now().toIso8601String(),
        'meta': {
          'platform': ThemeMode.system
              .toString(), // placeholder: você pode enviar platform, locale etc.
        },
      });
    } catch (e) {
      // ignora falhas
    }
  }

  void _checkAndShowMessage() {
    final count = _onlineCount.value;
    if (count > 50) {
      _showGlobalMessage(count);
    }
  }

  void _showGlobalMessage(int count) {
    // Usar um navigator key global para mostrar a mensagem em qualquer tela
    final context = navigatorKey.currentContext;
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🔥 Mais de $count usuários ativos nos últimos 10 minutos! 🔥'),
          duration: const Duration(seconds: 5),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  /// Método público para mostrar mensagem manualmente (para testes)
  void showTestMessage(BuildContext context, int count) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🔥 Mais de $count usuários ativos nos últimos 10 minutos! 🔥'),
        duration: const Duration(seconds: 5),
        backgroundColor: Colors.green,
      ),
    );
  }
}

/// Chave global do navigator para mostrar mensagens em qualquer tela
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
