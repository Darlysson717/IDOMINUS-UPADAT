import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'veiculo_card.dart';
import 'comprador_home.dart';

class LojistasSeguidosPage extends StatefulWidget {
  const LojistasSeguidosPage({super.key});

  @override
  State<LojistasSeguidosPage> createState() => _LojistasSeguidosPageState();
}

class _LojistasSeguidosPageState extends State<LojistasSeguidosPage> {
  List<Map<String, dynamic>> _lojistasSeguidos = [];
  List<Map<String, dynamic>> _veiculosDosLojistas = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _carregarLojistasSeguidos();
  }

  Future<void> _carregarLojistasSeguidos() async {
    if (mounted) {
      setState(() => _loading = true);
    }

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        if (mounted) {
          setState(() => _loading = false);
        }
        return;
      }

      // Buscar vendedores seguidos
      final response = await Supabase.instance.client
          .from('vendedores_seguidos')
          .select('vendedor_id')
          .eq('user_id', user.id);

      final vendedorIds = (response as List)
          .map((item) => item['vendedor_id'] as String)
          .toList();

      if (vendedorIds.isEmpty) {
        if (mounted) {
          setState(() {
            _lojistasSeguidos = [];
            _loading = false;
          });
        }
        return;
      }

      // Buscar informações dos vendedores (usando dados dos veículos)
      final vendedoresResponse = await Supabase.instance.client
          .from('veiculos')
          .select('user_id, titulo, marca, modelo, cidade, estado')
          .eq('status', 'ativo')
          .order('criado_em', ascending: false);

      // Agrupar por user_id para ter info única por vendedor (apenas os que o usuário segue)
      final Map<String, Map<String, dynamic>> vendedoresMap = {};
      for (final veiculo in vendedoresResponse as List) {
        final userId = veiculo['user_id'] as String;
        // Só incluir vendedores que o usuário segue
        if (vendedorIds.contains(userId) && !vendedoresMap.containsKey(userId)) {
          vendedoresMap[userId] = {
            'user_id': userId,
            'nome_loja': _extrairNomeLoja(veiculo),
            'cidade': veiculo['cidade'] ?? '',
            'estado': veiculo['estado'] ?? '',
            'total_anuncios': 0, // Será calculado depois
          };
        }
      }

      // Contar total de anúncios por vendedor
      for (final vendedorId in vendedorIds) {
        final countResponse = await Supabase.instance.client
            .from('veiculos')
            .select('id')
            .eq('user_id', vendedorId)
            .eq('status', 'ativo');

        if (vendedoresMap.containsKey(vendedorId)) {
          vendedoresMap[vendedorId]!['total_anuncios'] = (countResponse as List).length;
        }
      }

      if (mounted) {
        setState(() {
          _lojistasSeguidos = vendedoresMap.values.toList();
          _loading = false;
        });
      }

      // Carregar veículos dos lojistas seguidos
      await _carregarVeiculosDosLojistas();

    } catch (e) {
      print('Erro ao carregar lojistas seguidos: $e');
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  String _extrairNomeLoja(Map<String, dynamic> veiculo) {
    // Tentar extrair nome da loja do título do anúncio
    final titulo = veiculo['titulo'] as String? ?? '';
    if (titulo.isNotEmpty) {
      // Se o título contém palavras como "Loja", "Concessionária", etc.
      if (titulo.toLowerCase().contains('loja') ||
          titulo.toLowerCase().contains('concessionária') ||
          titulo.toLowerCase().contains('auto') ||
          titulo.length > 30) { // Títulos longos provavelmente são nomes de lojas
        return titulo;
      }
    }

    // Fallback: usar marca + modelo
    final marca = veiculo['marca'] as String? ?? '';
    final modelo = veiculo['modelo'] as String? ?? '';
    if (marca.isNotEmpty && modelo.isNotEmpty) {
      return '$marca $modelo';
    }

    return 'Lojista';
  }

  Future<void> _carregarVeiculosDosLojistas() async {
    if (_lojistasSeguidos.isEmpty) return;

    try {
      final vendedorIds = _lojistasSeguidos.map((l) => l['user_id'] as String).toList();

      final response = await Supabase.instance.client
          .from('veiculos')
          .select()
          .eq('status', 'ativo')
          .order('criado_em', ascending: false)
          .limit(50); // Limitar para performance

      // Filtrar apenas veículos dos vendedores seguidos
      final veiculosFiltrados = (response as List<dynamic>)
          .where((veiculo) => vendedorIds.contains(veiculo['user_id']))
          .cast<Map<String, dynamic>>()
          .toList();

      if (mounted) {
        setState(() {
          _veiculosDosLojistas = veiculosFiltrados;
        });
      }
    } catch (e) {
      print('Erro ao carregar veículos dos lojistas: $e');
    }
  }

  Future<void> _desseguirVendedor(String vendedorId) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      await Supabase.instance.client
          .from('vendedores_seguidos')
          .delete()
          .eq('user_id', user.id)
          .eq('vendedor_id', vendedorId);

      // Recarregar lista
      await _carregarLojistasSeguidos();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lojista removido dos seguidos')),
        );
      }
    } catch (e) {
      print('Erro ao desseguir vendedor: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao remover lojista')),
        );
      }
    }
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
        return 'R\$ ${precoRaw.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
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
      return '${q.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} km';
    })();

    final String cidadeEstado = (() {
      final c = veiculo['cidade'];
      final e = veiculo['estado'];
      if (c == null && e == null) return '-';
      final parts = [c, e].whereType<String>().map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      if (parts.isEmpty) return '-';
      return parts.join(' - ');
    })();

    return {
      'foto': foto,
      'nome': nome,
      'preco': preco,
      'ano': ano,
      'quilometragem': quilometragem,
      'cidadeEstado': cidadeEstado,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lojistas Seguidos'),
        backgroundColor: Colors.deepPurple,
        elevation: 2,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _lojistasSeguidos.isEmpty
              ? _buildEmptyState()
              : _buildContent(),
  // BottomNavigationBar fixo para navegação
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        onTap: (index) {
          if (index == 0) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const CompradorHome()),
              (route) => false,
            );
          } else if (index == 1) {
            Navigator.of(context).pushNamed('/favoritos');
          } else if (index == 3) {
            Navigator.of(context).pushNamed('/perfil');
          }
        },
        selectedItemColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.deepPurple,
        unselectedItemColor: Theme.of(context).brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.6) : Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border),
            label: 'Favoritos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.store),
            label: 'Lojistas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.store_outlined,
            size: 64,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white.withValues(alpha: 0.4)
                : Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhum lojista seguido',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withValues(alpha: 0.7)
                  : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Siga lojistas para ver seus anúncios aqui',
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withValues(alpha: 0.5)
                  : Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return CustomScrollView(
      slivers: [
        // Lista de lojistas seguidos
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Lojistas que você segue',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black87,
              ),
            ),
          ),
        ),

        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final lojista = _lojistasSeguidos[index];
              return _buildLojistaCard(lojista);
            },
            childCount: _lojistasSeguidos.length,
          ),
        ),

        // Veículos dos lojistas
        if (_veiculosDosLojistas.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Anúncios dos lojistas seguidos',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black87,
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.75,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final veiculo = _veiculosDosLojistas[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/detalhes',
                        arguments: veiculo,
                      );
                    },
                    child: VeiculoCard(
                      foto: _extractVehicleData(veiculo)['foto']!,
                      nome: _extractVehicleData(veiculo)['nome']!,
                      preco: _extractVehicleData(veiculo)['preco']!,
                      ano: _extractVehicleData(veiculo)['ano']!,
                      quilometragem: _extractVehicleData(veiculo)['quilometragem']!,
                      cidadeEstado: _extractVehicleData(veiculo)['cidadeEstado']!,
                      badge: '',
                      onVerDetalhes: () {
                        Navigator.pushNamed(
                          context,
                          '/detalhes',
                          arguments: veiculo,
                        );
                      },
                    ),
                  );
                },
                childCount: _veiculosDosLojistas.length,
              ),
            ),
          ),
        ],

        const SliverToBoxAdapter(
          child: SizedBox(height: 20),
        ),
      ],
    );
  }

  Widget _buildLojistaCard(Map<String, dynamic> lojista) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar do lojista
            CircleAvatar(
              radius: 24,
              backgroundColor: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey[200],
              child: Icon(
                Icons.store,
                color: isDark ? Colors.white : Colors.grey[600],
              ),
            ),
            const SizedBox(width: 12),

            // Informações do lojista
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lojista['nome_loja'] ?? 'Lojista',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${lojista['cidade'] ?? ''} ${lojista['estado'] ?? ''}'.trim(),
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white.withValues(alpha: 0.7) : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${lojista['total_anuncios'] ?? 0} anúncios',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white.withValues(alpha: 0.6) : Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),

            // Botão de desseguir
            IconButton(
              onPressed: () => _desseguirVendedor(lojista['user_id']),
              icon: Icon(
                Icons.person_remove,
                color: Colors.red[400],
              ),
              tooltip: 'Deixar de seguir',
            ),
          ],
        ),
      ),
    );
  }
}