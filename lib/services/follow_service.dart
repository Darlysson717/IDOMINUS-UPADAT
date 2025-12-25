import 'package:supabase_flutter/supabase_flutter.dart';

class FollowService {
  FollowService._internal();
  static final FollowService I = FollowService._internal();

  final SupabaseClient _client = Supabase.instance.client;

  User? get _currentUser => _client.auth.currentUser;

  User _requireUser() {
    final user = _currentUser;
    if (user == null) {
      throw Exception('Usuário não autenticado');
    }
    return user;
  }

  Future<bool> isFollowing(String sellerId) async {
    final user = _currentUser;
    if (user == null) return false;

    final response = await _client
        .from('vendedores_seguidos')
        .select('id')
        .eq('user_id', user.id)
        .eq('vendedor_id', sellerId)
        .limit(1);

    return (response as List).isNotEmpty;
  }

  Future<void> followSeller(String sellerId) async {
    final user = _requireUser();

    await _client.from('vendedores_seguidos').insert({
      'user_id': user.id,
      'vendedor_id': sellerId,
    });
  }

  Future<void> unfollowSeller(String sellerId) async {
    final user = _requireUser();

    await _client
        .from('vendedores_seguidos')
        .delete()
        .eq('user_id', user.id)
        .eq('vendedor_id', sellerId);
  }
}
