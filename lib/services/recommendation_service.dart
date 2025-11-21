import 'package:supabase_flutter/supabase_flutter.dart';

class RecommendationService {
  static final RecommendationService _instance = RecommendationService._internal();
  factory RecommendationService() => _instance;
  RecommendationService._internal();

  static RecommendationService get I => _instance;

  // Cache de recomendações
  Map<String, List<Map<String, dynamic>>> _recommendationsCache = {};
  DateTime? _lastCacheUpdate;

  // Obter recomendações personalizadas para o usuário
  Future<List<Map<String, dynamic>>> getPersonalizedRecommendations({
    int limit = 10,
    bool forceRefresh = false,
  }) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return [];

    // Verificar cache (válido por 30 minutos)
    if (!forceRefresh &&
        _recommendationsCache.containsKey(user.id) &&
        _lastCacheUpdate != null &&
        DateTime.now().difference(_lastCacheUpdate!) < const Duration(minutes: 30)) {
      return _recommendationsCache[user.id]!;
    }

    try {
      // 1. Buscar histórico de visualizações do usuário
      final viewsResponse = await Supabase.instance.client
          .from('visualizacoes')
          .select('anuncio_id, created_at')
          .eq('viewer_id', user.id)
          .order('created_at', ascending: false)
          .limit(20);

      final viewedIds = (viewsResponse as List)
          .map((v) => v['anuncio_id']?.toString())
          .where((id) => id != null)
          .toList();

      // 2. Buscar favoritos do usuário
      final favoritesResponse = await Supabase.instance.client
          .from('favoritos')
          .select('veiculo_id')
          .eq('usuario_id', user.id);

      final favoriteIds = (favoritesResponse as List)
          .map((f) => f['veiculo_id']?.toString())
          .where((id) => id != null)
          .toList();

      // 3. Buscar contatos feitos (mais engajamento)
      final contactsResponse = await Supabase.instance.client
          .from('contatos')
          .select('anuncio_id')
          .eq('user_id', user.id);

      final contactedIds = (contactsResponse as List)
          .map((c) => c['anuncio_id']?.toString())
          .where((id) => id != null)
          .toList();

      // 4. Analisar padrões de interesse
      final allInteractedIds = {...viewedIds, ...favoriteIds, ...contactedIds}.toList();
      print('Usuário ${user.id} - Visualizações: ${viewedIds.length}, Favoritos: ${favoriteIds.length}, Contatos: ${contactedIds.length}, Total interagidos: ${allInteractedIds.length}');

      if (allInteractedIds.isEmpty) {
        // Usuário novo - retornar anúncios populares recentes
        print('Usuário novo, retornando anúncios populares recentes');
        return await _getPopularRecentVehicles(limit);
      }

      // Buscar detalhes dos anúncios interagidos para análise de padrões
      List<Map<String, dynamic>> interactedVehicles = [];
      if (allInteractedIds.isNotEmpty) {
        // Para cada ID, fazer uma query separada (não ideal, mas funciona)
        for (final id in allInteractedIds) {
          if (id != null) {
            try {
              final vehicle = await Supabase.instance.client
                  .from('veiculos')
                  .select('marca, modelo, preco, condicao, combustivel, cambio, carroceria')
                  .eq('id', id)
                  .eq('status', 'ativo')
                  .single();
              interactedVehicles.add(vehicle);
            } catch (e) {
              // Ignorar erros para IDs individuais
              continue;
            }
          }
        }
      }

      // 5. Calcular pesos de preferência
      final preferences = _calculatePreferences(interactedVehicles);

      // 6. Buscar recomendações baseadas nas preferências
      final validIds = allInteractedIds.whereType<String>().toList();
      final recommendations = await _getRecommendationsBasedOnPreferences(
        preferences,
        excludeIds: validIds,
        limit: limit,
      );

      // 7. Ordenar por relevância
      recommendations.sort((a, b) => _calculateRelevanceScore(b, preferences)
          .compareTo(_calculateRelevanceScore(a, preferences)));

      // Cache das recomendações
      _recommendationsCache[user.id] = recommendations.take(limit).toList();
      _lastCacheUpdate = DateTime.now();

      return recommendations.take(limit).toList();

    } catch (e) {
      print('Erro ao buscar recomendações: $e');
      // Fallback: retornar anúncios populares
      return await _getPopularRecentVehicles(limit);
    }
  }

  // Calcular preferências do usuário baseado no histórico
  Map<String, dynamic> _calculatePreferences(List<Map<String, dynamic>> vehicles) {
    final preferences = {
      'marcas': <String, int>{},
      'modelos': <String, int>{},
      'faixaPreco': {'min': double.infinity, 'max': 0.0},
      'condicoes': <String, int>{},
      'combustiveis': <String, int>{},
      'cambios': <String, int>{},
      'carrocerias': <String, int>{},
    };

    for (final vehicle in vehicles) {
      // Marcas
      final marca = vehicle['marca']?.toString();
      if (marca != null && marca.isNotEmpty) {
        preferences['marcas']![marca] = (preferences['marcas']![marca] ?? 0) + 1;
      }

      // Modelos
      final modelo = vehicle['modelo']?.toString();
      if (modelo != null && modelo.isNotEmpty) {
        preferences['modelos']![modelo] = (preferences['modelos']![modelo] ?? 0) + 1;
      }

      // Faixa de preço
      final preco = vehicle['preco'];
      if (preco is num) {
        final precoDouble = preco.toDouble();
        preferences['faixaPreco']!['min'] = (preferences['faixaPreco']!['min'] as double).clamp(0, precoDouble);
        preferences['faixaPreco']!['max'] = (preferences['faixaPreco']!['max'] as double) > precoDouble
            ? preferences['faixaPreco']!['max'] as double
            : precoDouble;
      }

      // Condições
      final condicao = vehicle['condicao']?.toString();
      if (condicao != null && condicao.isNotEmpty) {
        preferences['condicoes']![condicao] = (preferences['condicoes']![condicao] ?? 0) + 1;
      }

      // Combustíveis
      final combustivel = vehicle['combustivel']?.toString();
      if (combustivel != null && combustivel.isNotEmpty) {
        preferences['combustiveis']![combustivel] = (preferences['combustiveis']![combustivel] ?? 0) + 1;
      }

      // Câmbios
      final cambio = vehicle['cambio']?.toString();
      if (cambio != null && cambio.isNotEmpty) {
        preferences['cambios']![cambio] = (preferences['cambios']![cambio] ?? 0) + 1;
      }

      // Carrocerias
      final carroceria = vehicle['carroceria']?.toString();
      if (carroceria != null && carroceria.isNotEmpty) {
        preferences['carrocerias']![carroceria] = (preferences['carrocerias']![carroceria] ?? 0) + 1;
      }
    }

    return preferences;
  }

  // Buscar recomendações baseadas nas preferências
  Future<List<Map<String, dynamic>>> _getRecommendationsBasedOnPreferences(
    Map<String, dynamic> preferences, {
    required List<String> excludeIds,
    required int limit,
  }) async {
    try {
      // Aplicar filtros baseados nas preferências mais fortes
      final marcas = preferences['marcas'] as Map<String, int>;
      final marcaMaisFrequente = marcas.entries
          .where((e) => e.value > 1)
          .fold<MapEntry<String, int>?>(null, (prev, curr) =>
              prev == null || curr.value > prev.value ? curr : prev);

      final carrocerias = preferences['carrocerias'] as Map<String, int>;
      final carroceriaMaisFrequente = carrocerias.entries
          .where((e) => e.value > 1)
          .fold<MapEntry<String, int>?>(null, (prev, curr) =>
              prev == null || curr.value > prev.value ? curr : prev);

      var query = Supabase.instance.client
          .from('veiculos')
          .select()
          .eq('status', 'ativo');

      // Excluir IDs já interagidos
      if (excludeIds.isNotEmpty) {
        query = query.not('id', 'in', '(${excludeIds.join(',')})');
      }

      // Aplicar filtros de preferência
      if (marcaMaisFrequente != null) {
        query = query.ilike('marca', '%${marcaMaisFrequente.key}%');
      }

      if (carroceriaMaisFrequente != null) {
        query = query.eq('carroceria', carroceriaMaisFrequente.key);
      }

      // Aplicar paginação e ordenação
      final response = await query
          .order('criado_em', ascending: false)
          .limit(limit * 2); // Buscar mais para ter opções de filtrar

      return List<Map<String, dynamic>>.from(response as List);

    } catch (e) {
      print('Erro ao buscar recomendações baseadas em preferências: $e');
      return [];
    }
  }

  // Fallback: anúncios populares recentes
  Future<List<Map<String, dynamic>>> _getPopularRecentVehicles(int limit) async {
    try {
      // Buscar anúncios recentes (simplificado - sem contagem de visualizações por enquanto)
      print('Buscando anúncios populares recentes, limite: $limit');
      final response = await Supabase.instance.client
          .from('veiculos')
          .select()
          .eq('status', 'ativo')
          .order('criado_em', ascending: false)
          .limit(limit);

      final vehicles = List<Map<String, dynamic>>.from(response as List);
      print('Encontrados ${vehicles.length} anúncios populares recentes');

      // Por enquanto, apenas retornar os veículos mais recentes
      // TODO: Implementar sistema de visualizações se necessário
      return vehicles;

    } catch (e) {
      print('Erro ao buscar veículos populares: $e');
      return [];
    }
  }

  // Calcular score de relevância para um veículo
  double _calculateRelevanceScore(Map<String, dynamic> vehicle, Map<String, dynamic> preferences) {
    double score = 0.0;

    // Preferência por marca (peso alto)
    final marca = vehicle['marca']?.toString();
    if (marca != null && preferences['marcas'].containsKey(marca)) {
      score += (preferences['marcas'][marca] ?? 0) * 10.0;
    }

    // Preferência por carroceria (peso médio)
    final carroceria = vehicle['carroceria']?.toString();
    if (carroceria != null && preferences['carrocerias'].containsKey(carroceria)) {
      score += (preferences['carrocerias'][carroceria] ?? 0) * 5.0;
    }

    // Faixa de preço adequada (peso médio)
    final preco = vehicle['preco'];
    if (preco is num) {
      final faixaPreco = preferences['faixaPreco'];
      final minPrice = faixaPreco['min'] as double;
      final maxPrice = faixaPreco['max'] as double;

      if (preco >= minPrice * 0.7 && preco <= maxPrice * 1.3) {
        score += 5.0;
      }
    }

    // Recência (peso baixo)
    final criadoEm = vehicle['criado_em'];
    if (criadoEm != null) {
      final createdDate = DateTime.tryParse(criadoEm.toString());
      if (createdDate != null) {
        final daysSinceCreation = DateTime.now().difference(createdDate).inDays;
        score += (30 - daysSinceCreation.clamp(0, 30)) * 0.1; // Máximo 3 pontos para anúncios muito recentes
      }
    }

    return score;
  }

  // Limpar cache
  void clearCache() {
    _recommendationsCache.clear();
    _lastCacheUpdate = null;
  }
}