import 'package:supabase_flutter/supabase_flutter.dart';

class Administrator {
  final String id;
  final String? userId;
  final String email;
  final bool isSuperAdmin;
  final DateTime createdAt;

  Administrator({
    required this.id,
    required this.userId,
    required this.email,
    required this.isSuperAdmin,
    required this.createdAt,
  });

  factory Administrator.fromJson(Map<String, dynamic> json) {
    return Administrator(
      id: json['id'],
      userId: json['user_id'],
      email: json['email'],
      isSuperAdmin: json['is_super_admin'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class AdminService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  static Future<bool> isCurrentUserAdmin() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return false;

    final userEmail = user.email;
    if (userEmail == null) return false;

    try {
      final response = await _supabase
          .from('administrators')
          .select('email')
          .eq('email', userEmail.toLowerCase())
          .limit(1);

      return response.isNotEmpty;
    } catch (e) {
      print('Erro ao verificar admin: $e');
      return false;
    }
  }

  static Future<bool> isCurrentUserSuperAdmin() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return false;

    final userEmail = user.email;
    if (userEmail == null) return false;

    try {
      final response = await _supabase
          .from('administrators')
          .select('is_super_admin')
          .eq('email', userEmail.toLowerCase())
          .eq('is_super_admin', true)
          .limit(1);

      return response.isNotEmpty;
    } catch (e) {
      print('Erro ao verificar super admin: $e');
      return false;
    }
  }

  static Future<List<Administrator>> getAllAdministrators() async {
    try {
      final response = await _supabase
          .from('administrators')
          .select()
          .order('created_at', ascending: false);

      return response.map((json) => Administrator.fromJson(json)).toList();
    } catch (e) {
      print('Erro ao buscar administradores: $e');
      return [];
    }
  }

  static Future<bool> addAdministrator(String email) async {
    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) return false;

      // Buscar user_id do email
      final userResponse = await _supabase
          .from('auth.users')
          .select('id')
          .eq('email', email.toLowerCase())
          .single();

      final userId = userResponse['id'];

      await _supabase.from('administrators').insert({
        'email': email.toLowerCase(),
        'user_id': userId,
        'created_by': currentUser.id,
        'is_super_admin': false,
      });

      return true;
    } catch (e) {
      print('Erro ao adicionar administrador: $e');
      return false;
    }
  }

  static Future<bool> removeAdministrator(String adminId) async {
    try {
      await _supabase
          .from('administrators')
          .delete()
          .eq('id', adminId);

      return true;
    } catch (e) {
      print('Erro ao remover administrador: $e');
      return false;
    }
  }
}