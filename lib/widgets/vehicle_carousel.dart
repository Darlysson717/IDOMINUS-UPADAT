import 'package:flutter/material.dart';
import '../veiculo_card.dart';
import 'skeleton_widgets.dart';

class VehicleCarousel extends StatefulWidget {
  final String title;
  final List<Map<String, dynamic>> vehicles;
  final bool isLoading;
  final VoidCallback? onViewAll;
  final String? emptyMessage;
  final double height;
  final bool simpleMode;

  const VehicleCarousel({
    Key? key,
    required this.title,
    required this.vehicles,
    this.isLoading = false,
    this.onViewAll,
    this.emptyMessage,
    this.height = 340,
    this.simpleMode = false,
  }) : super(key: key);

  @override
  State<VehicleCarousel> createState() => _VehicleCarouselState();
}

class _VehicleCarouselState extends State<VehicleCarousel> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Helper method to extract vehicle data (same logic as comprador_home.dart)
  Map<String, String> _extractVehicleData(Map<String, dynamic> veiculo) {
    final String foto = (() {
      final thumbs = veiculo['fotos_thumb'];
      if (thumbs is List && thumbs.isNotEmpty && thumbs.first is String) {
        return thumbs.first as String;
      }
      final f = veiculo['foto'];
      if (f is String && f.isNotEmpty) return f;
      final fotos = veiculo['fotos'];
      if (fotos is List && fotos.isNotEmpty) {
        final first = fotos.first;
        if (first is String) return first;
      }
      return '';
    })();

    final String nome = (() {
      if (veiculo['nome'] is String && (veiculo['nome'] as String).trim().isNotEmpty) {
        return veiculo['nome'];
      }
      if (veiculo['titulo'] is String && (veiculo['titulo'] as String).trim().isNotEmpty) {
        return veiculo['titulo'];
      }
      final parts = [
        veiculo['marca'],
        veiculo['modelo'],
        veiculo['versao'],
      ].whereType<String>().map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      if (parts.isNotEmpty) return parts.join(' ');
      return 'Veículo';
    })();

    final dynamic precoRaw = veiculo['preco'];
    final String preco = (() {
      if (precoRaw == null) return 'Preço a consultar';
      if (precoRaw is num) {
        return precoRaw.toString();
      }
      return precoRaw.toString();
    })();

    final String ano = (() {
      final a = veiculo['ano_modelo'] ?? veiculo['ano_fab'] ?? veiculo['ano'];
      if (a == null) return '-';
      return a.toString();
    })();

    final String quilometragem = (() {
      final q = veiculo['km'] ?? veiculo['quilometragem'];
      if (q == null) return '-';
      return q.toString();
    })();

    final String cidadeEstado = (() {
      final c = veiculo['cidade'];
      final e = veiculo['estado'];
      if (c == null && e == null) return '-';
      final parts = [c, e].whereType<String>().map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      if (parts.isEmpty) return '-';
      return parts.join(' - ');
    })();

    String badge = (veiculo['badge'] ?? '').toString();
    // gera badge 'Novo' automática se veículo tem até 7 dias e não há outra
    if(badge.trim().isEmpty){
      final raw = veiculo['criado_em'];
      DateTime? dt;
      if(raw is DateTime) dt = raw; else if(raw is String){ try { dt = DateTime.parse(raw);} catch(_){} }
      if(dt != null && DateTime.now().difference(dt).inDays <= 7){
        badge = 'Novo';
      }
    }

    return {
      'foto': foto,
      'nome': nome,
      'preco': preco,
      'ano': ano,
      'quilometragem': quilometragem,
      'cidadeEstado': cidadeEstado,
      'badge': badge,
    };
  }

  Widget _buildSimpleCard(Map<String, dynamic> vehicle, Map<String, String> vehicleData) {
    final size = MediaQuery.of(context).size;
    final isSmall = size.width < 400;

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/detalhes', arguments: vehicle);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imagem
          Container(
            height: isSmall ? 200 : 240,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[300],
            ),
            child: vehicleData['foto']!.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      vehicleData['foto']!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(Icons.directions_car, size: 40, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.grey[600]);
                      },
                    ),
                  )
                : Icon(Icons.directions_car, size: 40, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.grey[600]),
          ),

          const SizedBox(height: 8),

          // Nome do veículo
          Text(
            vehicleData['nome']!,
            style: TextStyle(
              fontSize: isSmall ? 16 : 18,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmall = size.width < 400;

    if (widget.isLoading) {
      return _buildLoadingSection();
    }

    if (widget.vehicles.isEmpty && widget.emptyMessage != null) {
      return _buildEmptySection();
    }

    return Container(
      height: widget.height,
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header com título e botão "Ver todos"
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: isSmall ? 18 : 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF4C1D95),
                  ),
                ),
                if (widget.onViewAll != null && !widget.simpleMode)
                  TextButton(
                    onPressed: widget.onViewAll,
                    child: Text(
                      'Ver todos',
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF7C3AED),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Carrossel horizontal
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: widget.vehicles.length,
              itemBuilder: (context, index) {
                final vehicle = widget.vehicles[index];
                final vehicleData = _extractVehicleData(vehicle);

                return Container(
                  width: widget.simpleMode ? (isSmall ? 280 : 350) : (isSmall ? 260 : 300),
                  margin: EdgeInsets.only(
                    right: index == widget.vehicles.length - 1 ? 0 : (widget.simpleMode ? 16 : 20),
                  ),
                  child: widget.simpleMode
                      ? _buildSimpleCard(vehicle, vehicleData)
                      : VeiculoCard(
                          foto: vehicleData['foto']!,
                          nome: vehicleData['nome']!,
                          preco: vehicleData['preco']!,
                          ano: vehicleData['ano']!,
                          quilometragem: vehicleData['quilometragem']!,
                          cidadeEstado: vehicleData['cidadeEstado']!,
                          badge: vehicleData['badge']!,
                          onVerDetalhes: () {
                            Navigator.pushNamed(context, '/detalhes', arguments: vehicle);
                          },
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingSection() {
    return Container(
      height: widget.height,
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              widget.title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF4C1D95),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: 3, // Mostrar 3 skeletons
              itemBuilder: (context, index) {
                return VehicleCardSkeleton(isSmall: widget.simpleMode);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySection() {
    return Container(
      height: widget.height,
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              widget.title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF4C1D95),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.directions_car_outlined,
                    size: 48,
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.4) : const Color(0xFF4C1D95).withOpacity(0.4),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.emptyMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.6) : const Color(0xFF4C1D95).withOpacity(0.6),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Widget para seção de destaques com indicador de página
class FeaturedCarousel extends StatefulWidget {
  final List<Map<String, dynamic>> vehicles;
  final bool isLoading;
  final double height;

  const FeaturedCarousel({
    Key? key,
    required this.vehicles,
    this.isLoading = false,
    this.height = 320,
  }) : super(key: key);

  @override
  State<FeaturedCarousel> createState() => _FeaturedCarouselState();
}

class _FeaturedCarouselState extends State<FeaturedCarousel> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page?.round() ?? 0;
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Helper method to extract vehicle data (same logic as comprador_home.dart)
  Map<String, String> _extractVehicleData(Map<String, dynamic> veiculo) {
    final String foto = (() {
      final thumbs = veiculo['fotos_thumb'];
      if (thumbs is List && thumbs.isNotEmpty && thumbs.first is String) {
        return thumbs.first as String;
      }
      final f = veiculo['foto'];
      if (f is String && f.isNotEmpty) return f;
      final fotos = veiculo['fotos'];
      if (fotos is List && fotos.isNotEmpty) {
        final first = fotos.first;
        if (first is String) return first;
      }
      return '';
    })();

    final String nome = (() {
      if (veiculo['nome'] is String && (veiculo['nome'] as String).trim().isNotEmpty) {
        return veiculo['nome'];
      }
      if (veiculo['titulo'] is String && (veiculo['titulo'] as String).trim().isNotEmpty) {
        return veiculo['titulo'];
      }
      final parts = [
        veiculo['marca'],
        veiculo['modelo'],
        veiculo['versao'],
      ].whereType<String>().map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      if (parts.isNotEmpty) return parts.join(' ');
      return 'Veículo';
    })();

    final dynamic precoRaw = veiculo['preco'];
    final String preco = (() {
      if (precoRaw == null) return 'Preço a consultar';
      if (precoRaw is num) {
        return precoRaw.toString();
      }
      return precoRaw.toString();
    })();

    final String ano = (() {
      final a = veiculo['ano_modelo'] ?? veiculo['ano_fab'] ?? veiculo['ano'];
      if (a == null) return '-';
      return a.toString();
    })();

    final String quilometragem = (() {
      final q = veiculo['km'] ?? veiculo['quilometragem'];
      if (q == null) return '-';
      return q.toString();
    })();

    final String cidadeEstado = (() {
      final c = veiculo['cidade'];
      final e = veiculo['estado'];
      if (c == null && e == null) return '-';
      final parts = [c, e].whereType<String>().map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      if (parts.isEmpty) return '-';
      return parts.join(' - ');
    })();

    String badge = (veiculo['badge'] ?? '').toString();
    // gera badge 'Novo' automática se veículo tem até 7 dias e não há outra
    if(badge.trim().isEmpty){
      final raw = veiculo['criado_em'];
      DateTime? dt;
      if(raw is DateTime) dt = raw; else if(raw is String){ try { dt = DateTime.parse(raw);} catch(_){} }
      if(dt != null && DateTime.now().difference(dt).inDays <= 7){
        badge = 'Novo';
      }
    }

    return {
      'foto': foto,
      'nome': nome,
      'preco': preco,
      'ano': ano,
      'quilometragem': quilometragem,
      'cidadeEstado': cidadeEstado,
      'badge': badge,
    };
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return Container(
        height: widget.height,
        margin: const EdgeInsets.only(bottom: 24),
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7C3AED)),
          ),
        ),
      );
    }

    if (widget.vehicles.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      height: widget.height,
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        children: [
          // Indicadores de página
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.vehicles.length,
              (index) => Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentPage == index
                      ? const Color(0xFF7C3AED)
                      : const Color(0xFF7C3AED).withOpacity(0.3),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // PageView para destaques
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.vehicles.length,
              itemBuilder: (context, index) {
                final vehicle = widget.vehicles[index];
                final vehicleData = _extractVehicleData(vehicle);

                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: VeiculoCard(
                    foto: vehicleData['foto']!,
                    nome: vehicleData['nome']!,
                    preco: vehicleData['preco']!,
                    ano: vehicleData['ano']!,
                    quilometragem: vehicleData['quilometragem']!,
                    cidadeEstado: vehicleData['cidadeEstado']!,
                    badge: vehicleData['badge']!,
                    onVerDetalhes: () {
                      Navigator.pushNamed(context, '/detalhes', arguments: vehicle);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}