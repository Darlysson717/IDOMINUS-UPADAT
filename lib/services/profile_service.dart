import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileService {
  static final ProfileService _instance = ProfileService._internal();
  factory ProfileService() => _instance;
  ProfileService._internal();

  final _supabase = Supabase.instance.client;

  /// Busca o perfil de um usuário pelo ID
  Future<Map<String, dynamic>?> getProfile(String userId) async {
    try {
      print('DEBUG ProfileService: Buscando perfil para userId: $userId');
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      print('DEBUG ProfileService: Response: $response');
      return response;
    } catch (e) {
      print('DEBUG ProfileService: Erro ao buscar perfil: $e');
      // Perfil não encontrado
      return null;
    }
  }

  /// Cria ou atualiza o perfil do usuário atual
  Future<void> upsertProfile({
    required String name,
    String? avatarUrl,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Usuário não autenticado');

    await _supabase.from('profiles').upsert({
      'id': user.id,
      'name': name,
      'avatar_url': avatarUrl,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  /// Sincroniza metadados do auth com o perfil
  Future<void> syncProfileFromAuth() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final meta = user.userMetadata ?? {};
    final name = meta['name'] as String?;
    final avatarUrl = meta['avatar_url'] as String?;

    if (name != null || avatarUrl != null) {
      await upsertProfile(name: name ?? '', avatarUrl: avatarUrl);
    }
  }
}