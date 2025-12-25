import 'package:supabase_flutter/supabase_flutter.dart';

class FavoritosRankingService {
  FavoritosRankingService._();

  static final FavoritosRankingService I = FavoritosRankingService._();

  final SupabaseClient _client = Supabase.instance.client;
  DateTime? _lastFetch;
  List<FavoritoRankingItem> _cache = const [];
  String _cacheCidade = '';
  String _cacheUserId = '';
  String _cacheCidadeCrit = '';

  Future<List<FavoritoRankingItem>> fetchTop({required String cidade, int limit = 15}) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      return const [];
    }

    final normalizedCidade = cidade.trim();

    final cidadeCrit = normalizedCidade.toLowerCase();
    final now = DateTime.now();
  final bool cacheHit =
    _lastFetch != null &&
        _cacheCidade == normalizedCidade &&
    _cacheUserId == user.id &&
        _cacheCidadeCrit == cidadeCrit &&
    now.difference(_lastFetch!) < const Duration(minutes: 5);
    if (cacheHit) {
      return _cache;
    }

    try {
  var query = _client.from('v_top_favoritos_15d').select();

      if (cidadeCrit.isNotEmpty) {
        query = query.ilike('cidade', '%$cidadeCrit%');
      }

      final List<dynamic> response = await query
          .order('total_favoritos', ascending: false)
          .limit(limit);

      final parsed = <FavoritoRankingItem>[];
      for (final row in response.cast<Map<String, dynamic>>()) {
        final item = FavoritoRankingItem.fromMap(row);
        if (item != null) {
          parsed.add(item);
        }
      }

      _cache = parsed;
      _cacheCidade = normalizedCidade;
  _cacheUserId = user.id;
      _cacheCidadeCrit = cidadeCrit;
      _lastFetch = DateTime.now();
      return parsed;
    } on PostgrestException catch (error) {
      throw Exception('Não foi possível carregar ranking de favoritos: ${error.message}');
    } catch (error) {
      throw Exception('Não foi possível carregar ranking de favoritos: $error');
    }
  }

  void invalidateCache() {
    _cache = const [];
    _lastFetch = null;
    _cacheCidade = '';
    _cacheUserId = '';
    _cacheCidadeCrit = '';
  }
}

class FavoritoRankingItem {
  final String anuncioId;
  final String userId;
  final String? cidade;
  final String? estado;
  final String titulo;
  final String? thumbnail;
  final int totalFavoritos;
  final DateTime? primeiroFavorito;
  final DateTime? ultimoFavorito;

  const FavoritoRankingItem({
    required this.anuncioId,
    required this.userId,
    required this.cidade,
    required this.estado,
    required this.titulo,
    required this.thumbnail,
    required this.totalFavoritos,
    required this.primeiroFavorito,
    required this.ultimoFavorito,
  });

  static FavoritoRankingItem? fromMap(Map<String, dynamic> map) {
    final anuncioId = map['veiculo_id']?.toString();
    final userId = map['user_id']?.toString();
    final tituloRaw = map['titulo']?.toString();
    if (anuncioId == null || userId == null || tituloRaw == null) {
      return null;
    }

    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      try {
        return DateTime.parse(value.toString()).toLocal();
      } catch (_) {
        return null;
      }
    }

    return FavoritoRankingItem(
      anuncioId: anuncioId,
      userId: userId,
      cidade: map['cidade']?.toString(),
      estado: map['estado']?.toString(),
      titulo: tituloRaw,
      thumbnail: map['thumbnail']?.toString(),
      totalFavoritos: (map['total_favoritos'] as num?)?.toInt() ?? 0,
      primeiroFavorito: parseDate(map['primeiro_favorito']),
      ultimoFavorito: parseDate(map['ultimo_favorito']),
    );
  }
}
