import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:csv/csv.dart';
import 'package:share_plus/share_plus.dart';

import 'services/analytics_service.dart';

class VisualizacoesPage extends StatefulWidget {
  const VisualizacoesPage({super.key});

  @override
  State<VisualizacoesPage> createState() => _VisualizacoesPageState();
}

class _VisualizacoesPageState extends State<VisualizacoesPage> {
  static const _periodOptions = [7, 30, 90];

  int _selectedDays = _periodOptions.first;
  bool _loading = true;
  AnalyticsSummary? _summary;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final summary = await AnalyticsService.I.fetchSummary(days: _selectedDays);
      if (!mounted) return;
      setState(() {
        _summary = summary;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  void _onPeriodChanged(int? value) {
    if (value == null || value == _selectedDays) return;
    setState(() => _selectedDays = value);
    _load();
  }

  Future<void> _exportData(AnalyticsSummary summary) async {
    if (!summary.hasData || summary.perAdStats.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não há dados suficientes para exportar')),
        );
      }
      return;
    }

    final csvData = [
      ['Métrica', 'Valor'],
      ['Período', 'Últimos $_selectedDays dias'],
      ['Total de visualizações', summary.totalViews.toString()],
      ['Visitantes únicos', summary.uniqueViewers.toString()],
      ['Média por anúncio', summary.averagePerAd.toStringAsFixed(1)],
      ['Cliques em contato', summary.totalContacts.toString()],
      ['Taxa de conversão', '${(summary.overallConversionRate * 100).toStringAsFixed(1)}%'],
      [],
      ['Anúncio', 'Localização', 'Visualizações', 'Únicos', 'Contatos', 'Conversão (%)'],
      ...summary.perAdStats.map((stat) => [
            stat.title,
            stat.location ?? '',
            stat.total.toString(),
            stat.uniqueViews.toString(),
            stat.contacts.toString(),
            (stat.conversionRate * 100).toStringAsFixed(1),
          ]),
    ];

    final csvString = const ListToCsvConverter().convert(csvData);
    final fileName = 'analytics_${DateFormat('yyyy-MM-dd').format(DateTime.now())}.csv';

    try {
      final bytes = Uint8List.fromList(csvString.codeUnits);
      await Share.shareXFiles([
        XFile.fromData(
          bytes,
          name: fileName,
          mimeType: 'text/csv',
        ),
      ], subject: 'Dados de Analytics - Dominus');
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao exportar: $error')),
        );
      }
    }
  }

  List<String> _getAlerts(AnalyticsSummary summary) {
    final alerts = <String>[];
    if (summary.overallConversionRate < 0.01) { // Menos de 1%
      alerts.add('Taxa de conversão baixa (${(summary.overallConversionRate * 100).toStringAsFixed(1)}%). Considere melhorar as descrições dos anúncios.');
    }
    if (summary.totalViews > 1000 && summary.overallConversionRate < 0.05) { // Muitas views, baixa conversão
      alerts.add('Muitas visualizações mas baixa conversão. Verifique se os preços estão competitivos.');
    }
    if (summary.totalContacts == 0 && summary.totalViews > 10) {
      alerts.add('Nenhum contato registrado ainda. Incentive os compradores a entrarem em contato.');
    }
    return alerts;
  }

  @override
  Widget build(BuildContext context) {
    final summary = _summary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Visualizações'),
        backgroundColor: Colors.deepPurple,
      ),
      body: RefreshIndicator(
        color: Colors.deepPurple,
        onRefresh: _load,
        child: Builder(
          builder: (context) {
            if (_error != null) {
              return _ErrorState(message: _error!, onRetry: _load);
            }

            if ((summary == null || !summary.hasData) && _loading) {
              return _LoadingState();
            }

            if (summary == null || summary.perAdStats.isEmpty) {
              return _EmptyState(days: _selectedDays);
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Últimos $_selectedDays dias',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                    DropdownButton<int>(
                      value: _selectedDays,
                      onChanged: _onPeriodChanged,
                      underline: const SizedBox.shrink(),
                      items: _periodOptions
                          .map(
                            (days) => DropdownMenuItem<int>(
                              value: days,
                              child: Text('$days dias'),
                            ),
                          )
                          .toList(),
                    ),
                    IconButton(
                      onPressed: () => _exportData(summary),
                      icon: const Icon(Icons.download),
                      tooltip: 'Exportar dados',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    const spacing = 12.0;
                    final maxWidth = constraints.maxWidth;
                    int columns;
                    if (maxWidth >= 720) {
                      columns = 3;
                    } else if (maxWidth >= 480) {
                      columns = 2;
                    } else {
                      columns = 1;
                    }
                    final totalSpacing = spacing * (columns - 1);
                    final availableWidth = maxWidth - totalSpacing;
                    final cardWidth = availableWidth / columns;

                    return Wrap(
                      spacing: spacing,
                      runSpacing: spacing,
                      children: [
                        SizedBox(
                          width: cardWidth,
                          child: _KpiCard(
                            label: 'Total de visualizações',
                            value: summary.totalViews.toString(),
                            icon: Icons.visibility,
                            color: Colors.deepPurple,
                          ),
                        ),
                        SizedBox(
                          width: cardWidth,
                          child: _KpiCard(
                            label: 'Visitantes únicos',
                            value: summary.uniqueViewers.toString(),
                            icon: Icons.people_alt,
                            color: Colors.indigo,
                          ),
                        ),
                        SizedBox(
                          width: cardWidth,
                          child: _KpiCard(
                            label: 'Média por anúncio',
                            value: summary.averagePerAd.toStringAsFixed(1),
                            icon: Icons.insights,
                            color: Colors.teal,
                          ),
                        ),
                        SizedBox(
                          width: cardWidth,
                          child: _KpiCard(
                            label: 'Cliques em contato',
                            value: summary.totalContacts.toString(),
                            icon: Icons.contact_phone,
                            color: Colors.green,
                          ),
                        ),
                        SizedBox(
                          width: cardWidth,
                          child: _KpiCard(
                            label: 'Taxa de conversão',
                            value: '${(summary.overallConversionRate * 100).toStringAsFixed(1)}%',
                            icon: Icons.trending_up,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),
                ..._getAlerts(summary).map((alert) => _AlertCard(message: alert)).toList(),
                if (_getAlerts(summary).isNotEmpty) const SizedBox(height: 16),
                _TimelineCard(summary: summary),
                const SizedBox(height: 28),
                Text(
                  'Desempenho por anúncio',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                ...summary.perAdStats.map((stat) => _AnuncioStatTile(stat: stat)).toList(),
                if (_loading) ...[
                  const SizedBox(height: 20),
                  const Center(child: CircularProgressIndicator()),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(10),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 14),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineCard extends StatelessWidget {
  final AnalyticsSummary summary;

  const _TimelineCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (summary.timeline.isEmpty) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: Text(
              'Ainda não há visualizações registradas no período selecionado.',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final maxCount = summary.timeline.map((e) => e.count).reduce((a, b) => a > b ? a : b).toDouble();
    final formatter = DateFormat('dd/MM');

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Evolução diária',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 190,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: summary.timeline.map((item) {
                          final double heightFactor = maxCount == 0 ? 0 : (item.count / maxCount).clamp(0.0, 1.0);
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: SizedBox(
                              width: 50,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    height: 130.0 * heightFactor,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      gradient: LinearGradient(
                                        begin: Alignment.bottomCenter,
                                        end: Alignment.topCenter,
                                        colors: [
                                          theme.colorScheme.primary,
                                          theme.colorScheme.primary.withOpacity(0.45),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    item.count.toString(),
                                    style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    formatter.format(item.date),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                          color: theme.colorScheme.onSurfaceVariant,
                                          fontSize: 11,
                                        ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 1,
                    width: double.infinity,
                    color: theme.colorScheme.surfaceVariant.withOpacity(0.6),
                  ),
                  if (summary.timeline.length > 7)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          Icon(Icons.swipe_right_alt, size: 16, color: theme.colorScheme.onSurfaceVariant),
                          const SizedBox(width: 6),
                          Text(
                            'Arraste para ver mais dias',
                            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ],
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
}

class _AnuncioStatTile extends StatelessWidget {
  final AnuncioViewStats stat;

  const _AnuncioStatTile({required this.stat});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Thumbnail(url: stat.thumbnail),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stat.title,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  if (stat.location != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      stat.location!,
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      _InfoPill(icon: Icons.visibility, label: '${stat.total} total'),
                      _InfoPill(icon: Icons.person, label: '${stat.uniqueViews} únicos'),
                      if (stat.last24h > 0)
                        _InfoPill(icon: Icons.bolt, label: '+${stat.last24h} nas últimas 24h', color: Colors.orange),
                      _InfoPill(icon: Icons.contact_phone, label: '${stat.contacts} contatos', color: Colors.green),
                      _InfoPill(icon: Icons.trending_up, label: '${(stat.conversionRate * 100).toStringAsFixed(1)}% conv.', color: Colors.blue),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _InfoPill({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = color ?? theme.colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: effectiveColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: effectiveColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(color: effectiveColor, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  final String? url;

  const _Thumbnail({this.url});

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(12);
    return ClipRRect(
      borderRadius: borderRadius,
      child: Container(
        width: 72,
        height: 72,
        color: Colors.grey.shade200,
        child: url == null || url!.isEmpty
            ? Icon(Icons.directions_car, color: Colors.grey.shade500)
            : Image.network(
                url!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Icon(Icons.image_not_supported, color: Colors.grey.shade500),
              ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final int days;

  const _EmptyState({required this.days});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(32),
      children: [
        const SizedBox(height: 120),
        Icon(Icons.visibility_off, size: 72, color: Colors.grey.shade400),
        const SizedBox(height: 18),
        Text(
          'Nenhuma visualização registrada nos últimos $days dias.',
          style: Theme.of(context).textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Divulgue seus anúncios e acompanhe aqui o desempenho em tempo real.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
        ),
      ],
    );
  }
}

class _LoadingState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: const [
        SizedBox(height: 220),
        Center(child: CircularProgressIndicator()),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      children: [
        Icon(Icons.error_outline, size: 72, color: Colors.red.shade300),
        const SizedBox(height: 16),
        Text(
          'Não foi possível carregar os dados.',
          style: Theme.of(context).textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 18),
        Center(
          child: ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Tentar novamente'),
          ),
        ),
      ],
    );
  }
}

class _AlertCard extends StatelessWidget {
  final String message;

  const _AlertCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.orange.shade50,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange.shade700),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: Colors.orange.shade900),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
