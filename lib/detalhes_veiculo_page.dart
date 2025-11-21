import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'favorites_service.dart';
import 'services/analytics_service.dart';

class DetalhesVeiculoPage extends StatefulWidget {
  const DetalhesVeiculoPage({super.key});
  @override
  State<DetalhesVeiculoPage> createState() => _DetalhesVeiculoPageState();
}

class _DetalhesVeiculoPageState extends State<DetalhesVeiculoPage> {
  final FavoritesService _fav = FavoritesService();
  bool _viewLogged = false;
  late final String veiculoId;
  Map<String, dynamic> veiculo = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    veiculo = (ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?) ?? {};
    veiculoId = (veiculo['id'] ?? veiculo['uuid'] ?? veiculo['codigo'] ?? veiculo.hashCode).toString();
    WidgetsBinding.instance.addPostFrameCallback((_) => _logVisualizacao());
  }

  void _logVisualizacao() {
    if (_viewLogged) return;
    final Map<String, dynamic> veiculo =
        (ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?) ?? {};
    veiculoId = (veiculo['id'] ?? veiculo['uuid'] ?? veiculo['codigo'] ?? veiculo.hashCode).toString();
    final anuncioId = veiculoId;
    if (anuncioId.isEmpty) return;
    _viewLogged = true;
    AnalyticsService.I.logView(anuncioId: anuncioId);
  }
  @override
  Widget build(BuildContext context) {
  final isFavorito = _fav.isFavorited(veiculoId);

    List<String> fotos = [];
    if (veiculo['fotos'] is List) {
      fotos = List<String>.from(veiculo['fotos'].whereType<String>());
    }
    if (fotos.isEmpty && veiculo['fotos_thumb'] is List) {
      fotos = List<String>.from(veiculo['fotos_thumb'].whereType<String>());
    }

    String preco = '-';
    final precoRaw = veiculo['preco'];
    if (precoRaw is num) {
      preco = 'R\$ ' + precoRaw.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m)=>'.');
    } else if (precoRaw != null) {
      preco = precoRaw.toString();
    }

    String km = '-';
    final kmRaw = veiculo['km'];
    if (kmRaw is num) {
      km = kmRaw.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m)=>'.');
    }

    String titulo = (veiculo['titulo'] ?? '') as String;
    if (titulo.trim().isEmpty) {
      final parts = [veiculo['marca'], veiculo['modelo'], veiculo['versao']]
          .whereType<String>()
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      if (parts.isNotEmpty) titulo = parts.join(' ');
    }

    final specItems = <_InfoItem>[
      _InfoItem('Marca', veiculo['marca']),
      _InfoItem('Modelo', veiculo['modelo']),
      _InfoItem('Versão', veiculo['versao']),
      _InfoItem('Ano Fab.', veiculo['ano_fab']),
      _InfoItem('KM', km),
      _InfoItem('Cor', veiculo['cor']),
      _InfoItem('Carroceria', veiculo['carroceria']),
      _InfoItem('Condição', veiculo['condicao']),
      _InfoItem('Combustível', veiculo['combustivel']),
      _InfoItem('Câmbio', veiculo['cambio']),
      _InfoItem('Portas', veiculo['num_portas']),
      _InfoItem('Direção', veiculo['direcao']),
      _InfoItem('Faróis', veiculo['farois']),
      _InfoItem('Situação', veiculo['situacao_veiculo']),
      _InfoItem('Garantia', veiculo['garantia']),
      _InfoItem('Airbags', veiculo['airbags']),
    ];

    final boolFlags = <_FlagItem>[
      _FlagItem('Ar-condicionado', veiculo['ar_condicionado']),
      _FlagItem('Vidros dianteiros', veiculo['vidros_dianteiros']),
      _FlagItem('Vidros traseiros', veiculo['vidros_traseiros']),
      _FlagItem('Travas elétricas', veiculo['travas_eletricas']),
      _FlagItem('Bancos couro', veiculo['bancos_couro']),
      _FlagItem('Multimídia', veiculo['multimidia']),
      _FlagItem('Rodas liga', veiculo['rodas_liga']),
      _FlagItem('ABS', veiculo['abs']),
      _FlagItem('Estabilidade', veiculo['controle_estabilidade']),
      _FlagItem('Sensor/Câmera', veiculo['sensor_estacionamento']),
      _FlagItem('Manual+Chave', veiculo['manual_chave']),
      _FlagItem('IPVA pago', veiculo['ipva_pago']),
    ];

    final pagamentos = <String>[];
    if (veiculo['pagamentos'] is List) {
      pagamentos.addAll(veiculo['pagamentos'].whereType<String>());
    } else if (veiculo['pagamento'] is String) {
      final raw = (veiculo['pagamento'] as String).trim();
      if(raw.contains(',')) {
        pagamentos.addAll(raw.split(',').map((e)=>e.trim()).where((e)=>e.isNotEmpty));
      } else if(raw.isNotEmpty) {
        pagamentos.add(raw);
      }
    }

  @override
  Widget build(BuildContext context) {
    final isFavorito = _fav.isFavorited(veiculoId);

    List<String> fotos = [];
    if (veiculo['fotos'] is List) {
      fotos = List<String>.from(veiculo['fotos'].whereType<String>());
    }
    if (fotos.isEmpty && veiculo['fotos_thumb'] is List) {
      fotos = List<String>.from(veiculo['fotos_thumb'].whereType<String>());
    }

    String preco = '-';
    final precoRaw = veiculo['preco'];
    if (precoRaw is num) {
      preco = 'R\$ ' + precoRaw.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m)=>'.');
    } else if (precoRaw != null) {
      preco = precoRaw.toString();
    }

    String km = '-';
    final kmRaw = veiculo['km'];
    if (kmRaw is num) {
      km = kmRaw.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m)=>'.');
    }

    String titulo = (veiculo['titulo'] ?? '') as String;
    if (titulo.trim().isEmpty) {
      final parts = [veiculo['marca'], veiculo['modelo'], veiculo['versao']]
          .whereType<String>()
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      if (parts.isNotEmpty) titulo = parts.join(' ');
    }

    final specItems = <_InfoItem>[
      _InfoItem('Marca', veiculo['marca']),
      _InfoItem('Modelo', veiculo['modelo']),
      _InfoItem('Versão', veiculo['versao']),
      _InfoItem('Ano Fab.', veiculo['ano_fab']),
      _InfoItem('KM', km),
      _InfoItem('Cor', veiculo['cor']),
      _InfoItem('Carroceria', veiculo['carroceria']),
      _InfoItem('Condição', veiculo['condicao']),
      _InfoItem('Combustível', veiculo['combustivel']),
      _InfoItem('Câmbio', veiculo['cambio']),
      _InfoItem('Portas', veiculo['num_portas']),
      _InfoItem('Direção', veiculo['direcao']),
      _InfoItem('Faróis', veiculo['farois']),
      _InfoItem('Situação', veiculo['situacao_veiculo']),
      _InfoItem('Garantia', veiculo['garantia']),
      _InfoItem('Airbags', veiculo['airbags']),
    ];

    final boolFlags = <_FlagItem>[
      _FlagItem('Ar-condicionado', veiculo['ar_condicionado']),
      _FlagItem('Vidros dianteiros', veiculo['vidros_dianteiros']),
      _FlagItem('Vidros traseiros', veiculo['vidros_traseiros']),
      _FlagItem('Travas elétricas', veiculo['travas_eletricas']),
      _FlagItem('Bancos couro', veiculo['bancos_couro']),
      _FlagItem('Multimídia', veiculo['multimidia']),
      _FlagItem('Rodas liga', veiculo['rodas_liga']),
      _FlagItem('ABS', veiculo['abs']),
      _FlagItem('Estabilidade', veiculo['controle_estabilidade']),
      _FlagItem('Sensor/Câmera', veiculo['sensor_estacionamento']),
      _FlagItem('Manual+Chave', veiculo['manual_chave']),
      _FlagItem('IPVA pago', veiculo['ipva_pago']),
    ];

    final pagamentos = <String>[];
    if (veiculo['pagamentos'] is List) {
      pagamentos.addAll(veiculo['pagamentos'].whereType<String>());
    } else if (veiculo['pagamento'] is String) {
      final raw = (veiculo['pagamento'] as String).trim();
      if(raw.contains(',')) {
        pagamentos.addAll(raw.split(',').map((e)=>e.trim()).where((e)=>e.isNotEmpty));
      } else if(raw.isNotEmpty) {
        pagamentos.add(raw);
      }
    }

    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Detalhes do Veículo'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(isFavorito ? Icons.favorite : Icons.favorite_border),
            onPressed: () async {
              try {
                if(isFavorito){
                  await _fav.removeRemote(veiculoId);
                } else {
                  await _fav.addRemote(veiculoId, veiculo);
                }
                if(mounted) setState((){});
              } catch (error) {
                if(mounted){
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Falha ao atualizar favoritos: $error')),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Header com imagem e preço overlay
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                backgroundColor: theme.colorScheme.primary,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (fotos.isNotEmpty)
                        Image.network(
                          fotos.first,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey[300],
                            child: const Icon(Icons.directions_car, size: 80, color: Colors.grey),
                          ),
                        )
                      else
                        Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.directions_car, size: 80, color: Colors.grey),
                        ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 20,
                        left: 20,
                        right: 20,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              titulo,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              preco,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (pagamentos.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 6,
                                children: pagamentos.map((p) => Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    p,
                                    style: const TextStyle(color: Colors.white, fontSize: 12),
                                  ),
                                )).toList(),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Galeria de imagens (se múltiplas)
              if (fotos.length > 1)
                SliverToBoxAdapter(
                  child: Container(
                    height: 100,
                    margin: const EdgeInsets.symmetric(vertical: 16),
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: fotos.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) => GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => _FullScreenGallery(fotos: fotos, initialIndex: index),
                          ));
                        },
                        child: Container(
                          width: 120,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              fotos[index],
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: Colors.grey[300],
                                child: const Icon(Icons.image, size: 40),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              // Conteúdo principal
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Descrição
                    if (veiculo['descricao'] != null && (veiculo['descricao'] as String).trim().isNotEmpty)
                      _ModernCard(
                        title: 'Descrição',
                        icon: Icons.description,
                        child: Text(
                          veiculo['descricao'],
                          style: const TextStyle(fontSize: 16, height: 1.5),
                        ),
                      ),
                    const SizedBox(height: 16),
                    // Especificações
                    _ModernCard(
                      title: 'Especificações',
                      icon: Icons.settings,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: specItems
                            .where((i) => i.value != null && i.value.toString().trim().isNotEmpty && i.value.toString() != 'null')
                            .map((i) => _SpecChip(item: i))
                            .toList(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Equipamentos
                    _ModernCard(
                      title: 'Equipamentos',
                      icon: Icons.build,
                      child: boolFlags.any((f) => f.value == true)
                          ? Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: boolFlags.where((f) => f.value == true).map((f) => Chip(
                          avatar: const Icon(Icons.check, size: 16, color: Colors.white),
                          label: Text(f.label),
                          backgroundColor: Colors.green.shade600,
                          labelStyle: const TextStyle(color: Colors.white),
                        )).toList(),
                      )
                          : const Text('Nenhum equipamento informado', style: TextStyle(color: Colors.grey)),
                    ),
                    const SizedBox(height: 16),
                    // Localização
                    _ModernCard(
                      title: 'Localização',
                      icon: Icons.location_on,
                      child: Text(
                        _formatLocal(veiculo['cidade'], veiculo['estado'], veiculo['cep']),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Data de publicação
                    if (veiculo['criado_em'] != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Publicado em: ${veiculo['criado_em']}',
                          style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ),
                    const SizedBox(height: 100), // Espaço para botões flutuantes
                  ]),
                ),
              ),
            ],
          ),
          // Botões flutuantes
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final anuncioId = (veiculo['id'] ?? veiculo['uuid'] ?? veiculo['codigo'])?.toString();
                      if (anuncioId != null && anuncioId.isNotEmpty) {
                        await AnalyticsService.I.logContact(anuncioId: anuncioId);
                      }

                      final whatsapp = veiculo['whatsapp']?.toString();

                      if (whatsapp != null && whatsapp.isNotEmpty) {
                        final cleanNumber = whatsapp.replaceAll(RegExp(r'[^0-9]'), '');
                        final formattedNumber = cleanNumber.startsWith('55') ? cleanNumber : '55$cleanNumber';
                        final whatsappUrl = 'https://wa.me/$formattedNumber';

                        try {
                          final uri = Uri.parse(whatsappUrl);
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        } catch (e) {
                          try {
                            final uri = Uri.parse(whatsappUrl);
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri, mode: LaunchMode.externalApplication);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('WhatsApp não está instalado'))
                              );
                            }
                          } catch (e2) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Erro ao abrir WhatsApp: $e2'))
                            );
                          }
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Contato do vendedor não disponível'))
                        );
                      }
                    },
                    icon: const FaIcon(FontAwesomeIcons.whatsapp, size: 20),
                    label: const Text('Contato'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                FloatingActionButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Compartilhar (implementar share_plus)'))
                    );
                  },
                  backgroundColor: theme.colorScheme.primary,
                  child: const Icon(Icons.share),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  }

  String _formatLocal(dynamic cidade, dynamic estado, dynamic cep) {
    final parts = <String>[];
    if (cidade is String && cidade.trim().isNotEmpty) parts.add(cidade.trim());
    if (estado is String && estado.trim().isNotEmpty) parts.add(estado.trim());
    if (cep is String && cep.trim().isNotEmpty) parts.add('CEP: '+cep.trim());
    if (parts.isEmpty) return '-';
    return parts.join(' - ');
  }
}

class _InfoItem {
  final String label;
  final dynamic value;
  _InfoItem(this.label, this.value);
}

class _FlagItem {
  final String label;
  final dynamic value;
  _FlagItem(this.label, this.value);
}

class _SpecChip extends StatelessWidget {
  final _InfoItem item;
  const _SpecChip({required this.item});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.deepPurple.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.deepPurple.shade100),
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 13, color: Colors.black87),
          children: [
            TextSpan(text: item.label+': ', style: const TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: item.value.toString()),
          ],
        ),
      ),
    );
  }
}

// ---------- UI Auxiliares estilizadas ----------
class _ModernCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  const _ModernCard({required this.title, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: theme.colorScheme.primary, size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}



class _GalleryHeader extends StatefulWidget {
  final List<String> fotos; final void Function(int index) onOpen; final String titulo;
  const _GalleryHeader({required this.fotos, required this.onOpen, required this.titulo});
  @override
  State<_GalleryHeader> createState() => _GalleryHeaderState();
}

class _GalleryHeaderState extends State<_GalleryHeader> {
  int _current = 0;
  final PageController _controller = PageController();
  @override
  Widget build(BuildContext context) {
    if(widget.fotos.isEmpty){
      return Container(
        height: 240,
        decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.directions_car, size: 80, color: Colors.grey),
      );
    }
    return Column(
      children: [
        SizedBox(
          height: 260,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.fotos.length,
            onPageChanged: (i)=> setState(()=> _current = i),
            itemBuilder: (_, i) => GestureDetector(
              onTap: () => widget.onOpen(i),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  color: Colors.black,
                  child: Center(
                    child: Image.network(
                      widget.fotos[i],
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.white54, size: 70),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        if (widget.fotos.length > 1)
          SizedBox(
            height: 64,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemBuilder: (_, i){
                final selected = i == _current;
                return GestureDetector(
                  onTap: () {
                    _controller.animateToPage(i, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: 80,
                    decoration: BoxDecoration(
                      border: Border.all(color: selected? Colors.deepPurple : Colors.transparent, width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(widget.fotos[i], fit: BoxFit.cover,
                        errorBuilder: (_, __, ___)=> Container(color: Colors.grey[300], child: const Icon(Icons.image, size: 24)),
                      ),
                    ),
                  ),
                );
              },
              separatorBuilder: (_, __)=> const SizedBox(width: 8),
              itemCount: widget.fotos.length,
            ),
          ),
      ],
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final bool favorito;
  final VoidCallback onToggleFavorito;
  final VoidCallback onContato;
  final VoidCallback onCompartilhar;
  const _ActionButtons({
    required this.favorito,
    required this.onToggleFavorito,
    required this.onContato,
    required this.onCompartilhar,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget buildBtn({required IconData icon, required String label, required VoidCallback onTap, Color? color, Color? bg}){
      return Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            decoration: BoxDecoration(
              color: bg ?? theme.colorScheme.primary.withOpacity(.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: (bg ?? theme.colorScheme.primary.withOpacity(.15)).withOpacity(.25)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 22, color: color ?? theme.colorScheme.primary),
                const SizedBox(height: 4),
                Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color ?? theme.colorScheme.primary)),
              ],
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        buildBtn(
          icon: favorito ? Icons.favorite : Icons.favorite_border,
          label: favorito ? 'Favorito' : 'Favoritar',
          onTap: onToggleFavorito,
          color: favorito ? Colors.red : null,
          bg: favorito ? Colors.red.withOpacity(.10) : null,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onContato,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(.10),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.green.withOpacity(.25)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  FaIcon(FontAwesomeIcons.whatsapp, size: 22, color: Colors.green),
                  SizedBox(height: 4),
                  Text('Contato', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.green)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        buildBtn(
          icon: Icons.ios_share,
          label: 'Compartilhar',
          onTap: onCompartilhar,
        ),
      ],
    );
  }
}

class _FullScreenGallery extends StatefulWidget {
  final List<String> fotos;
  final int initialIndex;
  const _FullScreenGallery({required this.fotos, this.initialIndex = 0});

  @override
  State<_FullScreenGallery> createState() => _FullScreenGalleryState();
}

class _FullScreenGalleryState extends State<_FullScreenGallery> {
  late PageController _controller;
  int _current = 0;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text('${_current+1}/${widget.fotos.length}', style: const TextStyle(color: Colors.white)),
      ),
      body: PageView.builder(
        controller: _controller,
        onPageChanged: (i)=> setState(()=> _current = i),
        itemCount: widget.fotos.length,
        itemBuilder: (_, i) {
          final url = widget.fotos[i];
          return Hero(
            tag: url,
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4,
              child: Center(
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.white54, size: 80),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
