import 'package:flutter/material.dart';
import 'widgets/business_ad_card.dart';
import 'services/business_ads_service.dart';

class MyBusinessAdsPage extends StatefulWidget {
  const MyBusinessAdsPage({super.key});

  @override
  State<MyBusinessAdsPage> createState() => _MyBusinessAdsPageState();
}

class _MyBusinessAdsPageState extends State<MyBusinessAdsPage> {
  List<Map<String, dynamic>> _userAds = [];
  bool _isLoading = true;
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadUserAds();
  }

  Future<void> _loadUserAds() async {
    try {
      final ads = await BusinessAdsService().getUserAds();
      final stats = await BusinessAdsService().getAdsStats();

      if (mounted) {
        setState(() {
          _userAds = ads;
          _stats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar anúncios: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Anúncios'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: 'Ver Estatísticas',
            onPressed: () {
              Navigator.of(context).pushNamed('/ads-statistics');
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadUserAds,
              child: _userAds.isEmpty
                  ? _buildEmptyState()
                  : _buildAdsList(),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.campaign_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'Nenhum anúncio encontrado',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Crie seu primeiro anúncio para aparecer na plataforma',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pushNamed('/business-ads');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF667EEA),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: const Text('Criar Anúncio'),
          ),
        ],
      ),
    );
  }

  Widget _buildAdsList() {
    return ListView(
      children: [
        // Estatísticas
        if (_stats.isNotEmpty) _buildStatsCard(),

        // Lista de anúncios
        ..._userAds.map((ad) => BusinessAdCard(
          ad: ad,
          showStats: true,
          onTap: () => _showAdDetails(ad),
        )),

        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildStatsCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Estatísticas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Total de Anúncios',
                    '${_stats['total_ads'] ?? 0}',
                    Icons.campaign,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Anúncios Ativos',
                    '${_stats['active_ads'] ?? 0}',
                    Icons.check_circle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Visualizações',
                    '${_stats['total_views'] ?? 0}',
                    Icons.visibility,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Cliques',
                    '${_stats['total_clicks'] ?? 0}',
                    Icons.touch_app,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: const Color(0xFF667EEA),
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF667EEA),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  void _showAdDetails(Map<String, dynamic> ad) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(20),
          child: ListView(
            controller: scrollController,
            children: [
              Text(
                ad['business_name'] ?? 'Anúncio',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Status
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: ad['is_active'] == true ? Colors.green[100] : Colors.red[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  ad['is_active'] == true ? 'Ativo' : 'Inativo',
                  style: TextStyle(
                    color: ad['is_active'] == true ? Colors.green[800] : Colors.red[800],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Detalhes
              _buildDetailRow('Plano', _getPlanLabel(ad['plan_type'])),
              _buildDetailRow('Categoria', ad['category'] ?? 'Não informado'),
              _buildDetailRow('Cidade', ad['city'] ?? 'Não informado'),
              _buildDetailRow('WhatsApp', ad['whatsapp'] ?? 'Não informado'),
              if (ad['website'] != null) _buildDetailRow('Website', ad['website']),

              const SizedBox(height: 16),

              // Estatísticas detalhadas
              const Text(
                'Estatísticas',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Visualizações',
                      '${ad['views_count'] ?? 0}',
                      Icons.visibility,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Cliques',
                      '${ad['clicks_count'] ?? 0}',
                      Icons.touch_app,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Datas
              _buildDetailRow('Criado em', _formatDate(ad['created_at'])),
              if (ad['expires_at'] != null)
                _buildDetailRow('Expira em', _formatDate(ad['expires_at'])),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(
              icon,
              color: const Color(0xFF667EEA),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getPlanLabel(String? planType) {
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
    if (dateString == null) return 'Não informado';

    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}/'
             '${date.month.toString().padLeft(2, '0')}/'
             '${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}