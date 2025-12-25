import 'package:supabase_flutter/supabase_flutter.dart';

class AnalyticsService {
  AnalyticsService._();

  static final AnalyticsService I = AnalyticsService._();

  final SupabaseClient _client = Supabase.instance.client;

  Future<void> logView({required String anuncioId}) async {
    print('🔍 LOGVIEW: Iniciando logView para anuncioId: $anuncioId');
    if (anuncioId.isEmpty) {
      print('❌ LOGVIEW: anuncioId vazio');
      return;
    }

    // REMOVIDO: Cooldown que impedia múltiplas visualizações do mesmo usuário
    // final now = DateTime.now();
    // final last = _viewCooldown[anuncioId];
    // if (last != null && now.difference(last) < const Duration(minutes: 10)) {
    //     print('⏰ LOGVIEW: Cooldown ativo, pulando');
    //     return;
    // }
    // _viewCooldown[anuncioId] = now;

    print('📝 LOGVIEW: Tentando inserir visualização');

    final user = _client.auth.currentUser;
    try {
      final result = await _client.from('visualizacoes').insert({
        'anuncio_id': anuncioId,
        if (user != null) 'viewer_id': user.id,
      });
      print('✅ LOGVIEW: Inserção bem-sucedida: $result');
    } catch (e) {
      print('💥 LOGVIEW: Erro ao inserir: $e');
    }
  }

  Future<void> logContact({required String anuncioId}) async {
    if (anuncioId.isEmpty) return;

    final user = _client.auth.currentUser;
    try {
      await _client.from('contatos').insert({
        'anuncio_id': anuncioId,
        if (user != null) 'user_id': user.id,
      });
    } catch (_) {
      // Falha silenciosa
    }
  }

  Future<AnalyticsSummary> fetchSummary({required int days}) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      return AnalyticsSummary.empty(days);
    }

    final now = DateTime.now();
    final since = now.subtract(Duration(days: days));

    List<dynamic> rawVeiculos;
    try {
      rawVeiculos = await _client
          .from('veiculos')
          .select()
          .eq('user_id', user.id);
    } catch (error) {
      throw Exception('Não foi possível carregar seus anúncios: $error');
    }

    final metas = <String, _AnuncioMeta>{};
    for (final item in rawVeiculos) {
      if (item is Map<String, dynamic>) {
        final id = item['id']?.toString();
        if (id == null) continue;
        metas[id] = _AnuncioMeta(
          id: id,
          titulo: _resolveTitulo(item),
          thumb: _resolveThumb(item),
          local: _resolveLocal(item),
        );
      }
    }

    if (metas.isEmpty) {
      return AnalyticsSummary.empty(days, referenceNow: now);
    }

    List<dynamic> rawViews = [];
    try {
      final viewBuilder = _client
          .from('visualizacoes')
          .select('anuncio_id, viewer_id, created_at')
          .gte('created_at', since.toIso8601String());

      if (metas.length == 1) {
        rawViews = await viewBuilder.eq('anuncio_id', metas.keys.first);
      } else {
        final quotedIds = metas.keys.map((id) => '"$id"').join(',');
        rawViews = await viewBuilder.filter('anuncio_id', 'in', '($quotedIds)');
      }
    } catch (error) {
      throw Exception('Não foi possível carregar as visualizações: $error');
    }

    List<dynamic> rawContacts = [];
    try {
      final contactBuilder = _client
          .from('contatos')
          .select('anuncio_id, created_at')
          .gte('created_at', since.toIso8601String());

      if (metas.length == 1) {
        rawContacts = await contactBuilder.eq('anuncio_id', metas.keys.first);
      } else {
        final quotedIds = metas.keys.map((id) => '"$id"').join(',');
        rawContacts = await contactBuilder.filter('anuncio_id', 'in', '($quotedIds)');
      }
    } catch (error) {
      // Se a tabela não existir ainda, continua sem contatos
    }

    final events = <_ViewEvent>[];
    for (final row in rawViews) {
      if (row is Map<String, dynamic>) {
        final anuncioId = row['anuncio_id']?.toString();
        final createdAtRaw = row['created_at']?.toString();
        if (anuncioId == null || createdAtRaw == null) continue;
        DateTime? createdAt;
        try {
          createdAt = DateTime.parse(createdAtRaw).toLocal();
        } catch (_) {
          continue;
        }
        events.add(_ViewEvent(
          anuncioId: anuncioId,
          createdAt: createdAt,
          viewerId: row['viewer_id']?.toString(),
        ));
      }
    }

    final contactEvents = <_ContactEvent>[];
    for (final row in rawContacts) {
      if (row is Map<String, dynamic>) {
        final anuncioId = row['anuncio_id']?.toString();
        final createdAtRaw = row['created_at']?.toString();
        if (anuncioId == null || createdAtRaw == null) continue;
        DateTime? createdAt;
        try {
          createdAt = DateTime.parse(createdAtRaw).toLocal();
        } catch (_) {
          continue;
        }
        contactEvents.add(_ContactEvent(
          anuncioId: anuncioId,
          createdAt: createdAt,
        ));
      }
    }

    final byAnuncio = <String, List<_ViewEvent>>{};
    final byDay = <DateTime, int>{};
    final viewers = <String>{};
    for (final event in events) {
      byAnuncio.putIfAbsent(event.anuncioId, () => []).add(event);

      final day = DateTime(event.createdAt.year, event.createdAt.month, event.createdAt.day);
      byDay[day] = (byDay[day] ?? 0) + 1;

      final viewerId = event.viewerId;
      if (viewerId != null && viewerId.isNotEmpty) {
        viewers.add(viewerId);
      }
    }

    final contactsByAnuncio = <String, List<_ContactEvent>>{};
    for (final event in contactEvents) {
      contactsByAnuncio.putIfAbsent(event.anuncioId, () => []).add(event);
    }

    final timeline = byDay.entries
        .map((entry) => DailyViews(date: entry.key, count: entry.value))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    final perAnuncio = <AnuncioViewStats>[];
    for (final meta in metas.values) {
      final list = byAnuncio[meta.id] ?? const <_ViewEvent>[];
      final uniqueViewers = <String>{
        for (final e in list)
          if (e.viewerId != null && e.viewerId!.isNotEmpty) e.viewerId!,
      };
      final contactList = contactsByAnuncio[meta.id] ?? const <_ContactEvent>[];
      final contacts = contactList.length;
      final conversionRate = list.isNotEmpty ? contacts / list.length : 0.0;
      final last24hCutoff = now.subtract(const Duration(hours: 24));
      final last24h = list.where((e) => e.createdAt.isAfter(last24hCutoff)).length;
      perAnuncio.add(AnuncioViewStats(
        id: meta.id,
        title: meta.titulo,
        location: meta.local,
        thumbnail: meta.thumb,
        total: list.length,
        uniqueViews: uniqueViewers.isNotEmpty ? uniqueViewers.length : list.length,
        last24h: last24h,
        contacts: contacts,
        conversionRate: conversionRate,
      ));
    }

    perAnuncio.sort((a, b) => b.total.compareTo(a.total));

    final totalViews = events.length;
    final uniqueViewersCount = viewers.isNotEmpty ? viewers.length : totalViews;
    final double averagePerAd = metas.isEmpty ? 0 : totalViews / metas.length;
    final totalContacts = contactEvents.length;
    final double overallConversionRate = totalViews > 0 ? totalContacts / totalViews : 0.0;

    return AnalyticsSummary(
      totalViews: totalViews,
      uniqueViewers: uniqueViewersCount,
      averagePerAd: averagePerAd,
      timeline: timeline,
      perAdStats: perAnuncio,
      periodDays: days,
      since: since,
      until: now,
      totalContacts: totalContacts,
      overallConversionRate: overallConversionRate,
    );
  }

  static String _resolveTitulo(Map<String, dynamic> row) {
    final candidatos = [
      row['titulo'],
      [row['marca'], row['modelo'], row['versao']]
          .whereType<String>()
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .join(' '),
    ];
    return candidatos
        .whereType<String>()
        .map((e) => e.trim())
        .firstWhere((element) => element.isNotEmpty, orElse: () => 'Anúncio');
  }

  static String? _resolveThumb(Map<String, dynamic> row) {
    final thumbs = row['fotos_thumb'];
    if (thumbs is List && thumbs.isNotEmpty && thumbs.first is String) {
      return thumbs.first as String;
    }
    final foto = row['foto'];
    if (foto is String && foto.isNotEmpty) return foto;
    final fotos = row['fotos'];
    if (fotos is List && fotos.isNotEmpty && fotos.first is String) {
      return fotos.first as String;
    }
    return null;
  }

  static String? _resolveLocal(Map<String, dynamic> row) {
    final cidade = row['cidade']?.toString().trim();
    final estado = row['estado']?.toString().trim();
    if (cidade == null || cidade.isEmpty) {
      return estado == null || estado.isEmpty ? null : estado;
    }
    if (estado == null || estado.isEmpty) return cidade;
    return '$cidade - $estado';
  }
}

class AnalyticsSummary {
  final int totalViews;
  final int uniqueViewers;
  final double averagePerAd;
  final List<DailyViews> timeline;
  final List<AnuncioViewStats> perAdStats;
  final int periodDays;
  final DateTime since;
  final DateTime until;
  final int totalContacts;
  final double overallConversionRate;

  const AnalyticsSummary({
    required this.totalViews,
    required this.uniqueViewers,
    required this.averagePerAd,
    required this.timeline,
    required this.perAdStats,
    required this.periodDays,
    required this.since,
    required this.until,
    required this.totalContacts,
    required this.overallConversionRate,
  });

  factory AnalyticsSummary.empty(int days, {DateTime? referenceNow}) {
    final now = referenceNow ?? DateTime.now();
    return AnalyticsSummary(
      totalViews: 0,
      uniqueViewers: 0,
      averagePerAd: 0,
      timeline: const [],
      perAdStats: const [],
      periodDays: days,
      since: now.subtract(Duration(days: days)),
      until: now,
      totalContacts: 0,
      overallConversionRate: 0.0,
    );
  }

  bool get hasData => totalViews > 0;
}

class DailyViews {
  final DateTime date;
  final int count;

  const DailyViews({required this.date, required this.count});
}

class AnuncioViewStats {
  final String id;
  final String title;
  final String? location;
  final String? thumbnail;
  final int total;
  final int uniqueViews;
  final int last24h;
  final int contacts;
  final double conversionRate;

  const AnuncioViewStats({
    required this.id,
    required this.title,
    required this.location,
    required this.thumbnail,
    required this.total,
    required this.uniqueViews,
    required this.last24h,
    required this.contacts,
    required this.conversionRate,
  });
}

class _AnuncioMeta {
  final String id;
  final String titulo;
  final String? thumb;
  final String? local;

  const _AnuncioMeta({
    required this.id,
    required this.titulo,
    required this.thumb,
    required this.local,
  });
}

class _ViewEvent {
  final String anuncioId;
  final DateTime createdAt;
  final String? viewerId;

  const _ViewEvent({
    required this.anuncioId,
    required this.createdAt,
    required this.viewerId,
  });
}

class _ContactEvent {
  final String anuncioId;
  final DateTime createdAt;

  const _ContactEvent({
    required this.anuncioId,
    required this.createdAt,
  });
}
