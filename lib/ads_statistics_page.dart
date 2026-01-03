import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/business_ads_service.dart';

class AdsStatisticsPage extends StatefulWidget {
  const AdsStatisticsPage({super.key});

  @override
  State<AdsStatisticsPage> createState() => _AdsStatisticsPageState();
}

class _AdsStatisticsPageState extends State<AdsStatisticsPage> {
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _userAds = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    try {
      final stats = await BusinessAdsService().getAdsStats();
      var userAds = await BusinessAdsService().getUserAds();

      // Se não encontrou anúncios para o usuário atual, tentar buscar todos (debug)
      if (userAds.isEmpty) {
        print('⚠️ Nenhum anúncio encontrado para o usuário atual. Tentando buscar todos os anúncios...');
        // Buscar todos os anúncios para debug (remover depois)
        final allAdsResponse = await Supabase.instance.client
            .from('business_ads')
            .select('*')
            .order('created_at', ascending: false);
        final allAds = List<Map<String, dynamic>>.from(allAdsResponse);
        print('📊 Total de anúncios no banco: ${allAds.length}');
        for (var ad in allAds) {
          print('  - ${ad['business_name']}: user_id=${ad['user_id']}, plan_type=${ad['plan_type']}');
        }

        // Usar todos os anúncios como fallback para exibir algo
        if (allAds.isNotEmpty) {
          print('ℹ️ Usando todos os anúncios como fallback temporário para exibição.');
          userAds = allAds;
        }
      }

      print('📊 Estatísticas carregadas: $stats');
      print('📋 Anúncios do usuário carregados: ${userAds.length}');

      if (mounted) {
        setState(() {
          _stats = stats;
          _userAds = userAds;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Erro ao carregar dados: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar estatísticas: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _fixAdsUserId() async {
    try {
      await BusinessAdsService().fixAdsUserId();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ User ID dos anúncios corrigido! Recarregando dados...'),
          backgroundColor: Colors.green,
        ),
      );
      // Recarregar estatísticas e anúncios após correção
      await _loadStatistics();
    } catch (e) {
      print('❌ Erro na correção: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erro ao corrigir user_id: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estatísticas dos Anúncios'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStatistics,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    _buildHeader(),

                    const SizedBox(height: 24),

                    // Estatísticas Gerais
                    _buildGeneralStats(),

                    const SizedBox(height: 24),

                    // Estatísticas por Plano
                    _buildPlanStats(),

                    const SizedBox(height: 24),

                    // Gráfico de Performance (placeholder)
                    _buildAdsList(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.analytics,
            color: Colors.white,
            size: 48,
          ),
          SizedBox(height: 12),
          Text(
            'Análise de Performance',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Acompanhe o desempenho dos seus anúncios',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneralStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Estatísticas Gerais',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total de Visualizações',
                _stats['total_views']?.toString() ?? '0',
                Icons.visibility,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Total de Cliques',
                _stats['total_clicks']?.toString() ?? '0',
                Icons.touch_app,
                Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Taxa de Cliques',
                _calculateCTR(),
                Icons.trending_up,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Anúncios Ativos',
                _stats['active_ads']?.toString() ?? '0',
                Icons.campaign,
                Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPlanStats() {
    final planStats =
        (_stats['ads_by_plan'] as Map<String, dynamic>? ?? <String, dynamic>{});

    int planCount(String key) {
      final value = planStats[key];
      if (value is int) return value;
      if (value is num) return value.toInt();
      return 0;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Estatísticas por Plano',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildPlanCard('Premium', planCount('premium'), Colors.purple),
        const SizedBox(height: 8),
        _buildPlanCard('Destaque', planCount('destaque'), Colors.orange),
        const SizedBox(height: 8),
        _buildPlanCard('Básico', planCount('basico'), Colors.blue),
      ],
    );
  }

  Widget _buildPlanCard(String planName, int count, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.campaign,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    planName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '$count anúncio${count != 1 ? 's' : ''}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdsList() {
    if (_userAds.isEmpty) {
      return Card(
        elevation: 2,
        child: Container(
          padding: const EdgeInsets.all(16),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.campaign,
                  size: 48,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'Nenhum anúncio encontrado',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Se você tem anúncios criados, clique no botão\n"🔧 Corrigir User ID dos Anúncios" acima',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Seus Anúncios',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ..._userAds.map((ad) => Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        ad['business_name'] ?? 'Nome não informado',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getPlanColor(ad['plan_type']).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getPlanName(ad['plan_type']),
                        style: TextStyle(
                          color: _getPlanColor(ad['plan_type']),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (ad['category'] != null)
                  Text(
                    ad['category'],
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.visibility,
                      size: 16,
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${ad['views_count'] ?? 0} visualizações',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.touch_app,
                      size: 16,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${ad['clicks_count'] ?? 0} cliques',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      ad['is_active'] == true ? Icons.check_circle : Icons.pause_circle,
                      size: 16,
                      color: ad['is_active'] == true ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      ad['is_active'] == true ? 'Ativo' : 'Inativo',
                      style: TextStyle(
                        fontSize: 12,
                        color: ad['is_active'] == true ? Colors.green : Colors.orange,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _formatDate(ad['created_at']),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        )),
      ],
    );
  }

  Color _getPlanColor(String? planType) {
    switch (planType) {
      case 'premium':
        return Colors.purple;
      case 'destaque':
        return Colors.orange;
      case 'basico':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getPlanName(String? planType) {
    switch (planType) {
      case 'premium':
        return 'Premium';
      case 'destaque':
        return 'Destaque';
      case 'basico':
        return 'Básico';
      default:
        return 'Desconhecido';
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return '';
    }
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: color,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _calculateCTR() {
    final views = _stats['total_views'] ?? 0;
    final clicks = _stats['total_clicks'] ?? 0;

    if (views == 0) return '0%';

    final ctr = (clicks / views) * 100;
    return '${ctr.toStringAsFixed(1)}%';
  }
}