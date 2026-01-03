import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

class BusinessAdsService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Upload de imagem para anúncio de negócio
  Future<String?> uploadBusinessAdImage(XFile imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();

      // Processar imagem (redimensionar se necessário)
      Uint8List uploadBytes = bytes;
      final decoded = img.decodeImage(bytes);
      if (decoded != null) {
        img.Image processed = decoded;
        // Redimensionar se for muito grande (máximo 1200px de largura)
        if (processed.width > 1200) {
          processed = img.copyResize(processed, width: 1200);
        }
        uploadBytes = Uint8List.fromList(img.encodeJpg(processed, quality: 85));
      }

      // Criar nome único para o arquivo
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = imageFile.name;
      final storagePath = 'anuncios/business_${timestamp}_$fileName';

      // Upload para Supabase Storage
      await _supabase.storage.from('fotos').uploadBinary(
        storagePath,
        uploadBytes,
        fileOptions: const FileOptions(contentType: 'image/jpeg'),
      );

      // Obter URL pública
      final publicUrl = _supabase.storage.from('fotos').getPublicUrl(storagePath);
      return publicUrl;
    } catch (e) {
      print('Erro ao fazer upload da imagem: $e');
      return null;
    }
  }

  // Salvar anúncio após pagamento confirmado
  Future<void> saveBusinessAd({
    required String planType,
    required int amountPaid,
    required String paymentId,
    String? businessName,
    String? category,
    String? city,
    String? whatsapp,
    String? website,
    String? creativeText,
    String? imageUrl,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Usuário não autenticado');

    print('💾 Salvando anúncio - User ID: $userId, Plan Type: $planType');

    await _supabase.from('business_ads').insert({
      'user_id': userId,
      'plan_type': planType,
      'business_name': businessName,
      'category': category,
      'city': city,
      'whatsapp': whatsapp,
      'website': website,
      'creative_text': creativeText,
      'image_url': imageUrl,
      'amount_paid': amountPaid,
      'payment_status': 'completed',
      'payment_id': paymentId,
    });

    print('✅ Anúncio salvo com sucesso');
  }

  // Buscar anúncios ativos por cidade
  Future<List<Map<String, dynamic>>> getActiveAdsByCity(String city) async {
    final response = await _supabase
        .from('business_ads')
        .select('*')
        .eq('is_active', true)
        .eq('payment_status', 'completed')
        .ilike('city', '%$city%') // Busca parcial na cidade
        .order('plan_type', ascending: false) // Premium primeiro
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  // Buscar anúncios ativos (todos)
  Future<List<Map<String, dynamic>>> getAllActiveAds() async {
    final response = await _supabase
        .from('business_ads')
        .select('*')
        .eq('is_active', true)
        .eq('payment_status', 'completed')
        .gt('expires_at', DateTime.now().toIso8601String()) // Anúncios não expirados
        .order('plan_type', ascending: false) // Premium primeiro
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  // Buscar anúncios do usuário atual
  Future<List<Map<String, dynamic>>> getUserAds() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      print('❌ getUserAds: Usuário não autenticado');
      return [];
    }

    print('👤 getUserAds: Buscando anúncios para user_id: $userId');

    final response = await _supabase
        .from('business_ads')
        .select('*')
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    final ads = List<Map<String, dynamic>>.from(response);
    print('📋 getUserAds: Encontrados ${ads.length} anúncios para o usuário');

    return ads;
  }

  // Incrementar contador de visualizações
  Future<void> incrementViews(String adId) async {
    await _supabase.rpc('increment_ad_views', params: {'ad_id': adId});
  }

  // Incrementar contador de cliques
  Future<void> incrementClicks(String adId) async {
    await _supabase.rpc('increment_ad_clicks', params: {'ad_id': adId});
  }

  // Desativar anúncio (para admins)
  Future<void> deactivateAd(String adId) async {
    await _supabase
        .from('business_ads')
        .update({'is_active': false})
        .eq('id', adId);
  }

  // Reativar anúncio (para admins)
  Future<void> reactivateAd(String adId) async {
    await _supabase
        .from('business_ads')
        .update({'is_active': true})
        .eq('id', adId);
  }

  // Buscar estatísticas dos anúncios
  Future<Map<String, dynamic>> getAdsStats() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      print('❌ ERRO: Usuário não autenticado!');
      return {};
    }

    print('👤 User ID atual do app: $userId');

    // Buscar anúncios do usuário atual
    final response = await _supabase
        .from('business_ads')
        .select('id, plan_type, views_count, clicks_count, is_active, user_id')
        .eq('user_id', userId);

    final ads = List<Map<String, dynamic>>.from(response);

    print('📊 Total de anúncios encontrados: ${ads.length}');

    final basicoCount = ads.where((ad) => (ad['plan_type'] ?? '').toString().toLowerCase().trim() == 'basico').length;
    final destaqueCount = ads.where((ad) => (ad['plan_type'] ?? '').toString().toLowerCase().trim() == 'destaque').length;
    final premiumCount = ads.where((ad) => (ad['plan_type'] ?? '').toString().toLowerCase().trim() == 'premium').length;

    print('📈 Contagem por plano (com trim e lowercase):');
    print('  - Básico: $basicoCount');
    print('  - Destaque: $destaqueCount');
    print('  - Premium: $premiumCount');

    return {
      'total_ads': ads.length,
      'active_ads': ads.where((ad) => ad['is_active'] == true).length,
      'total_views': ads.fold<int>(0, (sum, ad) => sum + ((ad['views_count'] ?? 0) as int)),
      'total_clicks': ads.fold<int>(0, (sum, ad) => sum + ((ad['clicks_count'] ?? 0) as int)),
      'ads_by_plan': {
        'basico': basicoCount,
        'destaque': destaqueCount,
        'premium': premiumCount,
      },
    };
  }

  // Função para corrigir user_id dos anúncios (usar uma vez para migrar dados)
  Future<void> fixAdsUserId() async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) {
      print('❌ fixAdsUserId: Usuário não autenticado');
      throw Exception('Usuário não autenticado');
    }

    final oldUserId = '899b6cea-0841-432d-a561-1738526a4518';

    print('🔧 fixAdsUserId: Corrigindo user_id dos anúncios...');
    print('  - De: $oldUserId');
    print('  - Para: $currentUserId');

    final response = await _supabase
        .from('business_ads')
        .update({'user_id': currentUserId})
        .eq('user_id', oldUserId)
        .select();

    print('✅ fixAdsUserId: ${response.length} anúncios corrigidos');
  }
}