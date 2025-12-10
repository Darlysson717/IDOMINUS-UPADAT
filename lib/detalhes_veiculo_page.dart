import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'favorites_service.dart';
import 'services/analytics_service.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

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
    
    // Priorizar campos que podem ser UUID
    String rawId = (veiculo['id'] ?? veiculo['uuid'] ?? veiculo['codigo'] ?? '').toString();
    
    // Se não for UUID válido, gerar um baseado no hash
    if (!isValidUUID(rawId)) {
      rawId = generateUUIDFromString(rawId);
    }
    
    veiculoId = rawId;
    WidgetsBinding.instance.addPostFrameCallback((_) => _logVisualizacao());
  }

  void _logVisualizacao() {
    print('👁️ LOGVISUALIZACAO: Chamado para veiculoId: $veiculoId');
    if (_viewLogged) {
      print('🚫 LOGVISUALIZACAO: Já logado');
      return;
    }
    final anuncioId = veiculoId;
    if (anuncioId.isEmpty) return;
    _viewLogged = true;
    print('📞 LOGVISUALIZACAO: Chamando AnalyticsService');
    AnalyticsService.I.logView(anuncioId: anuncioId);
  }

  // Função auxiliar para validar UUID
  bool isValidUUID(String? str) {
    if (str == null || str.isEmpty) return false;
    final uuidRegex = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$', caseSensitive: false);
    return uuidRegex.hasMatch(str);
  }

  // Função para gerar UUID consistente de uma string
  String generateUUIDFromString(String input) {
    // Usar hash da string para gerar UUID consistente
    // Isso garante que a mesma string sempre gera o mesmo UUID
    final bytes = utf8.encode(input);
    final hash = sha256.convert(bytes);
    final hashStr = hash.toString();
    
    // Formatar como UUID: 8-4-4-4-12
    return '${hashStr.substring(0, 8)}-${hashStr.substring(8, 12)}-${hashStr.substring(12, 16)}-${hashStr.substring(16, 20)}-${hashStr.substring(20, 32)}';
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
        title: const Text('Detalhes'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _GalleryHeader(fotos: fotos, titulo: titulo, onOpen: (i){
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => _FullScreenGallery(fotos: fotos, initialIndex: i),
                        ));
                      }),
                      const SizedBox(height: 16),
                      _PriceHeader(titulo: titulo, preco: preco, pagamentos: pagamentos),
                      const SizedBox(height: 16),
                      _ActionButtons(
                        favorito: isFavorito,
                        onToggleFavorito: () async {
                          try {
                            if(isFavorito){
                              await _fav.removeRemote(veiculoId);
                            } else {
                              await _fav.addRemote(veiculoId, veiculo);
                            }
                            if(mounted) setState((){}); // força rebuild estado ícone
                          } catch (error) {
                            if(mounted){
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Falha ao atualizar favoritos: $error')),
                              );
                            }
                          }
                        },
                        onContato: () async {
                          final anuncioId = (veiculo['id'] ?? veiculo['uuid'] ?? veiculo['codigo'])?.toString();
                          if (anuncioId != null && anuncioId.isNotEmpty) {
                            await AnalyticsService.I.logContact(anuncioId: anuncioId);
                          }
                          
                          final whatsapp = veiculo['whatsapp']?.toString();
                          
                          if (whatsapp != null && whatsapp.isNotEmpty) {
                            // Remove caracteres não numéricos
                            final cleanNumber = whatsapp.replaceAll(RegExp(r'[^0-9]'), '');
                            
                            // Para Brasil, remove o 0 do DDD se existir
                            final formattedNumber = cleanNumber.startsWith('55') 
                              ? cleanNumber 
                              : '55$cleanNumber';
                            
                            final whatsappUrl = 'https://wa.me/$formattedNumber';
                            
                            try {
                              final uri = Uri.parse(whatsappUrl);
                              // Tenta abrir diretamente sem verificar canLaunchUrl
                              await launchUrl(uri, mode: LaunchMode.externalApplication);
                            } catch (e) {
                              print('Erro ao abrir WhatsApp: $e'); // Debug
                              // Se falhar, tenta com canLaunchUrl como fallback
                              try {
                                final uri = Uri.parse(whatsappUrl);
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('WhatsApp não está instalado ou não pode ser aberto'))
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
                        onCompartilhar: () async {
                          final titulo = veiculo['titulo'] ?? 'Veículo';
                          final link = 'https://domin.us/vehicle/$veiculoId'; // Link direto para o anúncio
                          final mensagem = 'Confira este anúncio: $titulo\n$link';
                          
                          try {
                            await Share.share(mensagem, subject: titulo);
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Erro ao compartilhar: $e'))
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 20),
                      if (veiculo['descricao'] != null && (veiculo['descricao'] as String).trim().isNotEmpty)
                        _SectionCard(
                          title: 'Descrição',
                          child: Text(veiculo['descricao'], style: const TextStyle(fontSize: 14, height: 1.4)),
                        ),
                      _SectionCard(
                        title: 'Especificações',
                        child: Wrap(
                          spacing: 12,
                          runSpacing: 10,
                          children: specItems.where((i) => i.value != null && i.value.toString().trim().isNotEmpty && i.value.toString()!='null')
                              .map((i) => _SpecChip(item: i)).toList(),
                        ),
                      ),
                      _SectionCard(
                        title: 'Itens / Equipamentos',
                        child: boolFlags.any((f) => f.value == true)
                            ? Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: boolFlags.where((f) => f.value == true).map((f) => _ItemChip(item: f)).toList(),
                        )
                            : const Text('Nenhum item informado', style: TextStyle(color: Colors.grey)),
                      ),
                      _SectionCard(
                        title: 'Localização',
                        child: Text(_formatLocal(veiculo['cidade'], veiculo['estado'], veiculo['cep']), style: const TextStyle(fontSize: 14)),
                      ),
                      if (veiculo['criado_em'] != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text('Publicado em: ' + veiculo['criado_em'].toString(), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
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

  IconData _getIcon(String label) {
    switch (label) {
      case 'Marca':
      case 'Modelo':
      case 'Versão':
      case 'Carroceria':
      case 'Direção':
      case 'Portas':
        return FontAwesomeIcons.car;
      case 'Ano Fab.':
        return FontAwesomeIcons.calendar;
      case 'KM':
        return FontAwesomeIcons.tachometerAlt;
      case 'Cor':
        return FontAwesomeIcons.palette;
      case 'Condição':
        return FontAwesomeIcons.checkCircle;
      case 'Combustível':
        return FontAwesomeIcons.gasPump;
      case 'Câmbio':
        return FontAwesomeIcons.cogs;
      case 'Faróis':
        return FontAwesomeIcons.lightbulb;
      case 'Situação':
        return FontAwesomeIcons.infoCircle;
      case 'Garantia':
      case 'Airbags':
        return FontAwesomeIcons.shieldAlt;
      default:
        return FontAwesomeIcons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.deepPurple.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.deepPurple.shade100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(_getIcon(item.label), size: 16, color: Colors.deepPurple),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              '${item.label}: ${item.value}',
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemChip extends StatelessWidget {
  final _FlagItem item;
  const _ItemChip({required this.item});

  IconData _getIcon(String label) {
    switch (label) {
      case 'Ar-condicionado':
        return FontAwesomeIcons.snowflake;
      case 'Vidros dianteiros':
      case 'Vidros traseiros':
        return FontAwesomeIcons.windowMaximize;
      case 'Travas elétricas':
        return FontAwesomeIcons.lock;
      case 'Bancos couro':
        return FontAwesomeIcons.couch;
      case 'Multimídia':
        return FontAwesomeIcons.music;
      case 'Rodas liga':
        return FontAwesomeIcons.circle;
      case 'ABS':
        return FontAwesomeIcons.shieldAlt;
      case 'Estabilidade':
        return FontAwesomeIcons.balanceScale;
      case 'Sensor/Câmera':
        return FontAwesomeIcons.camera;
      case 'Manual+Chave':
        return FontAwesomeIcons.key;
      case 'IPVA pago':
        return FontAwesomeIcons.checkCircle;
      default:
        return FontAwesomeIcons.check;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: FaIcon(_getIcon(item.label), size: 16, color: Colors.white),
      label: Text(item.label),
      backgroundColor: Colors.deepPurple.shade600,
      labelStyle: const TextStyle(color: Colors.white),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

// ---------- UI Auxiliares estilizadas ----------
class _SectionCard extends StatelessWidget {
  final String title; final Widget child;
  const _SectionCard({required this.title, required this.child});
  @override
  Widget build(BuildContext context){
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
  padding: const EdgeInsets.fromLTRB(16,14,16,16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:[
          Row(
            children: [
              Container(width:4,height:18, decoration: BoxDecoration(color: theme.colorScheme.primary, borderRadius: BorderRadius.circular(4))),
              const SizedBox(width:8),
              Text(title, style: TextStyle(fontSize:16,fontWeight: FontWeight.w600,color: theme.colorScheme.onSurface)),
            ],
          ),
          const SizedBox(height:12),
          child,
        ],
      ),
    );
  }
}

class _PriceHeader extends StatelessWidget {
  final String titulo; final String preco; final List<String> pagamentos;
  const _PriceHeader({required this.titulo, required this.preco, required this.pagamentos});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            Color.lerp(theme.colorScheme.primary, theme.colorScheme.primaryContainer, 0.55)!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.fromLTRB(18,16,18,18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height:10),
          Text(preco, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height:12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: pagamentos.map((p)=> Container(
              padding: const EdgeInsets.symmetric(horizontal:10, vertical:6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white24),
              ),
              child: Text(p, style: const TextStyle(color: Colors.white, fontSize: 12,fontWeight: FontWeight.w500)),
            )).toList(),
          )
        ],
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
