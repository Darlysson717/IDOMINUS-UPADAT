import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class PaginatedVehicleService {
  static const int PAGE_SIZE = 20;

  // Cache de páginas carregadas
  final Map<String, List<Map<String, dynamic>>> _pageCache = {};
  final Map<String, bool> _hasMorePages = {};
  final Map<String, int> _totalCounts = {};

  // Limpar cache
  void clearCache() {
    _pageCache.clear();
    _hasMorePages.clear();
    _totalCounts.clear();
  }

  // Gerar chave única para cache baseada nos filtros
  String _generateCacheKey(Map<String, String?> filters, String searchText, String cidadeFiltro) {
    final sortedFilters = filters.entries
        .where((e) => e.value != null && e.value!.isNotEmpty)
        .map((e) => '${e.key}:${e.value}')
        .toList()
      ..sort();

    return '${sortedFilters.join('|')}|$searchText|$cidadeFiltro'.hashCode.toString();
  }

  // Carregar página específica
  Future<List<Map<String, dynamic>>> loadPage({
    required int page,
    Map<String, String?> filters = const {},
    String searchText = '',
    String cidadeFiltro = '',
    bool forceRefresh = false,
  }) async {
    final cacheKey = _generateCacheKey(filters, searchText, cidadeFiltro);

    // Verificar cache se não for refresh forçado
    if (!forceRefresh && _pageCache.containsKey('$cacheKey$page')) {
      return _pageCache['$cacheKey$page']!;
    }

    try {
      var query = Supabase.instance.client.from('veiculos').select();

      // Apenas anúncios ativos
      query = query.eq('status', 'ativo');

      // Aplicar filtros de busca
      if (searchText.isNotEmpty) {
        final escaped = searchText.replaceAll('%', '\\%');
        query = query.or("titulo.ilike.%$escaped% , modelo.ilike.%$escaped% , marca.ilike.%$escaped% ");
      }

      // Aplicar filtros avançados
      void addIlike(String key, String? value) {
        if (value != null && value.trim().isNotEmpty) {
          final v = value.trim();
          query = query.ilike(key, '%$v%');
        }
      }

      addIlike('marca', filters['marca']);
      addIlike('modelo', filters['modelo']);
      addIlike('cor', filters['cor']);
      addIlike('carroceria', filters['carroceria']);
      addIlike('direcao', filters['direcao']);
      addIlike('farois', filters['farois']);
      addIlike('situacao_veiculo', filters['situacaoVeiculo']);

      // Filtros exatos
      if (filters['combustivel'] != null && filters['combustivel']!.isNotEmpty) {
        query = query.eq('combustivel', filters['combustivel']!);
      }
      if (filters['cambio'] != null && filters['cambio']!.isNotEmpty) {
        query = query.eq('cambio', filters['cambio']!);
      }
      if (filters['motorizacao'] != null && filters['motorizacao']!.isNotEmpty) {
        query = query.eq('versao', filters['motorizacao']!);
      }
      if (filters['condicao'] != null && filters['condicao']!.isNotEmpty) {
        query = query.eq('condicao', filters['condicao']!);
      }
      if (filters['numPortas'] != null && filters['numPortas']!.isNotEmpty) {
        final p = int.tryParse(filters['numPortas']!);
        if (p != null) query = query.eq('num_portas', p);
      }

      // Filtros numéricos
      if (filters['anoMin'] != null && filters['anoMin']!.isNotEmpty) {
        final a = int.tryParse(filters['anoMin']!);
        if (a != null) query = query.gte('ano_fab', a);
      }
      if (filters['anoMax'] != null && filters['anoMax']!.isNotEmpty) {
        final a = int.tryParse(filters['anoMax']!);
        if (a != null) query = query.lte('ano_fab', a);
      }
      if (filters['precoMin'] != null && filters['precoMin']!.isNotEmpty) {
        final p = double.tryParse(filters['precoMin']!.replaceAll(',', '.'));
        if (p != null) query = query.gte('preco', p);
      }
      if (filters['precoMax'] != null && filters['precoMax']!.isNotEmpty) {
        final p = double.tryParse(filters['precoMax']!.replaceAll(',', '.'));
        if (p != null) query = query.lte('preco', p);
      }
      if (filters['kmMin'] != null && filters['kmMin']!.isNotEmpty) {
        final k = int.tryParse(filters['kmMin']!);
        if (k != null) query = query.gte('km', k);
      }
      if (filters['kmMax'] != null && filters['kmMax']!.isNotEmpty) {
        final k = int.tryParse(filters['kmMax']!);
        if (k != null) query = query.lte('km', k);
      }

      // Paginação
      final from = page * PAGE_SIZE;
      final to = from + PAGE_SIZE - 1;

      final response = await query.range(from, to).order('criado_em', ascending: false);
      final vehicles = List<Map<String, dynamic>>.from(response as List);

      // Verificar se há mais páginas
      _hasMorePages[cacheKey] = vehicles.length == PAGE_SIZE;

      // Cache da página
      _pageCache['$cacheKey$page'] = vehicles;

      return vehicles;

    } catch (e) {
      debugPrint('Erro ao carregar página $page: $e');
      return [];
    }
  }

  // Verificar se há mais páginas para carregar
  bool hasMorePages({
    Map<String, String?> filters = const {},
    String searchText = '',
    String cidadeFiltro = '',
  }) {
    final cacheKey = _generateCacheKey(filters, searchText, cidadeFiltro);
    return _hasMorePages[cacheKey] ?? true;
  }

  // Obter todas as páginas carregadas em cache
  List<Map<String, dynamic>> getCachedVehicles({
    Map<String, String?> filters = const {},
    String searchText = '',
    String cidadeFiltro = '',
  }) {
    final cacheKey = _generateCacheKey(filters, searchText, cidadeFiltro);
    final vehicles = <Map<String, dynamic>>[];

    for (int page = 0; ; page++) {
      final pageKey = '$cacheKey$page';
      if (_pageCache.containsKey(pageKey)) {
        vehicles.addAll(_pageCache[pageKey]!);
      } else {
        break;
      }
    }

    return vehicles;
  }

  // Invalidar cache para filtros específicos
  void invalidateCache({
    Map<String, String?> filters = const {},
    String searchText = '',
    String cidadeFiltro = '',
  }) {
    final cacheKey = _generateCacheKey(filters, searchText, cidadeFiltro);

    // Remover todas as páginas deste cache
    _pageCache.removeWhere((key, _) => key.startsWith(cacheKey));
    _hasMorePages.remove(cacheKey);
    _totalCounts.remove(cacheKey);
  }
}