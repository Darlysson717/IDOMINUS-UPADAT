import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'services/favoritos_ranking_service.dart';
import 'services/location_service.dart';

class TopFavoritosPage extends StatefulWidget {
  const TopFavoritosPage({super.key});

  @override
  State<TopFavoritosPage> createState() => _TopFavoritosPageState();
}

class _TopFavoritosPageState extends State<TopFavoritosPage> {
  final TextEditingController _cidadeController = TextEditingController();
  final FocusNode _cidadeFocus = FocusNode();

  bool _loading = true;
  String? _error;
  List<FavoritoRankingItem> _itens = const [];

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    _cidadeController.dispose();
    _cidadeFocus.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final resultados = await FavoritosRankingService.I.fetchTop(
        cidade: _cidadeController.text,
        limit: 15,
      );
      if (!mounted) return;
      setState(() {
        _itens = resultados;
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

  Future<void> _detectarCidade() async {
    final loc = LocationService.I;
    final ok = await loc.requestPermissionWithRationale();
    if (!ok) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permissão de localização negada.')),
      );
      return;
    }
    await loc.fetch();
    if (!mounted) return;
    final cidade = loc.cidade ?? '';
    _cidadeController.text = cidade;
    _cidadeFocus.unfocus();
    await _carregar();
  }

  Future<void> _abrirDetalhes(FavoritoRankingItem item) async {
    try {
      final Map<String, dynamic>? response = await Supabase.instance.client
          .from('veiculos')
          .select()
          .eq('id', item.anuncioId)
          .maybeSingle();
      if (!mounted) return;
      if (response == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível carregar este anúncio.')),
        );
        return;
      }
      Navigator.pushNamed(context, '/detalhes', arguments: response);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao abrir anúncio: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mais favoritados'),
        backgroundColor: Colors.deepPurple,
      ),
      body: RefreshIndicator(
        color: Colors.deepPurple,
        onRefresh: _carregar,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ranking dos anúncios com mais favoritos nos últimos 15 dias.',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _cidadeController,
                            focusNode: _cidadeFocus,
                            decoration: const InputDecoration(
                              labelText: 'Filtrar por cidade',
                              hintText: 'Ex.: Triunfo',
                              border: OutlineInputBorder(),
                            ),
                            textInputAction: TextInputAction.search,
                            onSubmitted: (_) => _carregar(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Tooltip(
                          message: 'Usar minha localização',
                          child: FilledButton.tonalIcon(
                            onPressed: _detectarCidade,
                            icon: const Icon(Icons.my_location),
                            label: const Text('Detectar'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.icon(
                        onPressed: _carregar,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Atualizar ranking'),
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (_error != null)
                      _ErroWidget(mensagem: _error!, onRetry: _carregar)
                    else if (_loading)
                      const _CarregandoWidget()
                    else if (_itens.isEmpty)
                      const _VazioWidget()
                    else
                      _ListaFavoritos(
                        itens: _itens,
                        onAbrir: _abrirDetalhes,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListaFavoritos extends StatelessWidget {
  final List<FavoritoRankingItem> itens;
  final void Function(FavoritoRankingItem item) onAbrir;

  const _ListaFavoritos({required this.itens, required this.onAbrir});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        for (var i = 0; i < itens.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _FavoritoCard(
              item: itens[i],
              posicao: i + 1,
              onTap: () => onAbrir(itens[i]),
            ),
          ),
        const SizedBox(height: 12),
        Text(
          'Atualizado a cada 5 minutos. Apenas anúncios ativos são considerados.',
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _FavoritoCard extends StatelessWidget {
  final FavoritoRankingItem item;
  final int posicao;
  final VoidCallback onTap;

  const _FavoritoCard({required this.item, required this.posicao, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _RankingBadge(posicao: posicao),
              const SizedBox(width: 16),
              _Thumbnail(url: item.thumbnail),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.titulo,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.favorite, size: 16, color: Colors.pink.shade400),
                        const SizedBox(width: 6),
                        Text(
                          '${item.totalFavoritos} favoritos',
                          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (item.cidade != null || item.estado != null)
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              _formatarLocal(item.cidade, item.estado),
                              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    if (item.ultimoFavorito != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Último favorito em ${_formatarData(item.ultimoFavorito!)}',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatarLocal(String? cidade, String? estado) {
    final partes = [
      if (cidade != null && cidade.trim().isNotEmpty) cidade.trim(),
      if (estado != null && estado.trim().isNotEmpty) estado.trim(),
    ];
    if (partes.isEmpty) return 'Local não informado';
    return partes.join(' - ');
  }

  static String _formatarData(DateTime data) {
    return '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';
  }
}

class _RankingBadge extends StatelessWidget {
  final int posicao;

  const _RankingBadge({required this.posicao});

  @override
  Widget build(BuildContext context) {
    final cores = [
      Colors.amber.shade600,
      Colors.grey.shade500,
      Colors.brown.shade400,
    ];
    final Color cor = posicao <= 3 ? cores[posicao - 1] : Colors.deepPurple.shade200;
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: cor,
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: Text(
        '#$posicao',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  final String? url;

  const _Thumbnail({required this.url});

  @override
  Widget build(BuildContext context) {
    const double size = 72;
    final borderRadius = BorderRadius.circular(12);
    return ClipRRect(
      borderRadius: borderRadius,
      child: url == null
          ? Container(
              width: size,
              height: size,
              color: Colors.grey.shade200,
              child: Icon(Icons.directions_car, color: Colors.grey.shade500),
            )
          : Image.network(
              url!,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: size,
                height: size,
                color: Colors.grey.shade200,
                child: Icon(Icons.broken_image, color: Colors.grey.shade400),
              ),
            ),
    );
  }
}

class _CarregandoWidget extends StatelessWidget {
  const _CarregandoWidget();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.only(top: 80, bottom: 40),
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class _VazioWidget extends StatelessWidget {
  const _VazioWidget();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          Icon(Icons.favorite_border, size: 64, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(height: 12),
          Text(
            'Nenhum favorito recente neste filtro.',
            style: theme.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'A lista atualiza com os favoritos registrados nos últimos 15 dias.',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ErroWidget extends StatelessWidget {
  final String mensagem;
  final Future<void> Function() onRetry;

  const _ErroWidget({required this.mensagem, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
          const SizedBox(height: 12),
          Text(
            'Não foi possível carregar o ranking.',
            style: theme.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              mensagem,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }
}
