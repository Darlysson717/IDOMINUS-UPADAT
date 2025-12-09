import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/seller_verification.dart';
import 'dart:convert';
import 'dart:io';
import 'admin_service.dart';

class SellerVerificationService {
  static final SellerVerificationService _instance = SellerVerificationService._internal();
  factory SellerVerificationService() => _instance;
  SellerVerificationService._internal();

  final _supabase = Supabase.instance.client;

  // Submeter solicitação de verificação
  Future<void> submitVerification(SellerVerification verification) async {
    await _supabase.from('seller_verifications').upsert(
      verification.toJson(),
      onConflict: 'user_id',
    );

    // Notificar administradores sobre nova solicitação
    try {
      final admins = await AdminService.getAllAdministrators();
      for (var admin in admins) {
        if (admin.userId != null) {
          await _supabase.from('notificacoes').insert({
            'user_id': admin.userId,
            'tipo': 'nova_solicitacao_verificacao',
            'mensagem': 'Nova solicitação de verificação de vendedor recebida.',
          });
        }
      }
    } catch (e) {
      // Error notifying admins
    }
  }

  // Buscar verificação do usuário atual
  Future<SellerVerification?> getCurrentUserVerification() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    final response = await _supabase
        .from('seller_verifications')
        .select()
        .eq('user_id', user.id)
        .single();

    if (response.isEmpty) return null;
    return SellerVerification.fromJson(response);
  }

  // Buscar todas as verificações (para admin)
  Future<List<SellerVerification>> getAllVerifications() async {
    final response = await _supabase
        .from('seller_verifications')
        .select()
        .order('created_at', ascending: false);

    return response.map((json) => SellerVerification.fromJson(json)).toList();
  }

  // Aprovar verificação
  Future<void> approveVerification(String userId) async {
    await _supabase
        .from('seller_verifications')
        .update({
          'status': 'approved',
          'reviewed_at': DateTime.now().toIso8601String(),
        })
        .eq('user_id', userId);

    // Notificar o vendedor sobre aprovação
    try {
      await _supabase.from('notificacoes').insert({
        'user_id': userId,
        'tipo': 'verificacao_aprovada',
        'mensagem': 'Sua solicitação de verificação de vendedor foi aprovada!',
      });
    } catch (e) {
      // Error notifying seller
    }
  }

  // Rejeitar verificação
  Future<void> rejectVerification(String userId, String reason) async {
    await _supabase
        .from('seller_verifications')
        .update({
          'status': 'rejected',
          'rejection_reason': reason,
          'reviewed_at': DateTime.now().toIso8601String(),
        })
        .eq('user_id', userId);

    // Notificar o vendedor sobre rejeição
    try {
      await _supabase.from('notificacoes').insert({
        'user_id': userId,
        'tipo': 'verificacao_rejeitada',
        'mensagem': 'Sua solicitação de verificação de vendedor foi rejeitada. Motivo: $reason',
      });
    } catch (e) {
      // Error notifying seller
    }
  }

  // Upload de documento (Alvará de Funcionamento) - MODO DESENVOLVIMENTO
  Future<String> uploadDocumento(String filePath, String fileName) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Usuário não autenticado');

    print('=== DEBUG: uploadDocumento ===');
    print('File path: $filePath');
    print('File name: $fileName');

    // MODO DESENVOLVIMENTO: Converter imagem para base64
    try {
      final file = File(filePath);
      final bytes = await file.readAsBytes();
      final base64Image = base64Encode(bytes);
      final mimeType = _getMimeType(fileName);

      print('File size: ${bytes.length} bytes');
      print('MIME type: $mimeType');
      print('Base64 length: ${base64Image.length}');

      // Retornar dados da imagem em base64
      final result = 'data:$mimeType;base64,$base64Image';
      print('Final URL length: ${result.length}');
      print('Final URL preview: ${result.substring(0, 100)}...');

      return result;
    } catch (e) {
      print('❌ Erro no upload: $e');
      // Fallback: retornar uma imagem base64 hardcoded para desenvolvimento
      print('🔄 Usando fallback com imagem de teste');
      return 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==';
    }
  }

  String _getMimeType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      default:
        return 'image/jpeg';
    }
  }

  // Verificar se usuário está aprovado
  Future<bool> isUserApproved(String userId) async {
    final verification = await getCurrentUserVerification();
    return verification?.status == VerificationStatus.approved;
  }
}