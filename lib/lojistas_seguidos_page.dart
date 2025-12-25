import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'comprador_home.dart';
import 'lojista_anuncios_page.dart';

class LojistasSeguidosPage extends StatefulWidget {
  const LojistasSeguidosPage({super.key});

  @override
  State<LojistasSeguidosPage> createState() => _LojistasSeguidosPageState();
}

class _LojistasSeguidosPageState extends State<LojistasSeguidosPage> {
  List<Map<String, dynamic>> _lojistasSeguidos = [];
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

      // Buscar perfis dos vendedores seguidos
      final profilesResponse = await Supabase.instance.client
          .from('profiles')
          .select('id, name, avatar_url')
          .filter('id', 'in', _buildInFilter(vendedorIds));

      final profilesMap = <String, Map<String, dynamic>>{};
      for (final profile in profilesResponse as List<dynamic>) {
        final profileId = profile['id'] as String?;
        if (profileId == null) continue;
        profilesMap[profileId] = profile;
      }

      // Buscar informações dos vendedores apenas para os IDs seguidos
        final vendedoresResponse = await Supabase.instance.client
          .from('veiculos')
          .select('user_id, cidade, estado')
          .eq('status', 'ativo')
          .filter('user_id', 'in', _buildInFilter(vendedorIds))
          .order('criado_em', ascending: false);

      final Map<String, Map<String, dynamic>> vendedoresMap = {};
      for (final veiculo in vendedoresResponse as List<dynamic>) {
        final userId = veiculo['user_id'] as String?;
        if (userId == null || !vendedorIds.contains(userId)) continue;

        vendedoresMap.putIfAbsent(userId, () {
          final profile = profilesMap[userId];
          return {
            'user_id': userId,
            'nome_loja': _resolveProfileName(profile),
            'avatar_url': profile?['avatar_url'] ?? '',
            'cidade': veiculo['cidade'] ?? '',
            'estado': veiculo['estado'] ?? '',
            'total_anuncios': 0,
          };
        });

        vendedoresMap[userId]!['total_anuncios'] =
            (vendedoresMap[userId]!['total_anuncios'] as int? ?? 0) + 1;

        final cidadeRegistrada = (vendedoresMap[userId]!['cidade'] as String?)?.trim() ?? '';
        if (cidadeRegistrada.isEmpty && veiculo['cidade'] != null) {
          vendedoresMap[userId]!['cidade'] = veiculo['cidade'];
        }

        final estadoRegistrado = (vendedoresMap[userId]!['estado'] as String?)?.trim() ?? '';
        if (estadoRegistrado.isEmpty && veiculo['estado'] != null) {
          vendedoresMap[userId]!['estado'] = veiculo['estado'];
        }
      }

      // Garantir que todos os vendedores apareçam mesmo sem anúncios ativos
      for (final vendedorId in vendedorIds) {
        vendedoresMap.putIfAbsent(vendedorId, () {
          final profile = profilesMap[vendedorId];
          return {
            'user_id': vendedorId,
            'nome_loja': _resolveProfileName(profile),
            'avatar_url': profile?['avatar_url'] ?? '',
            'cidade': '',
            'estado': '',
            'total_anuncios': 0,
          };
        });
      }

      if (mounted) {
        setState(() {
          _lojistasSeguidos = vendedoresMap.values.toList()
            ..sort((a, b) => (a['nome_loja'] ?? 'Lojista')
                .toString()
                .toLowerCase()
                .compareTo((b['nome_loja'] ?? 'Lojista').toString().toLowerCase()));
          _loading = false;
        });
      }

    } catch (e) {
      print('Erro ao carregar lojistas seguidos: $e');
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  String _resolveProfileName(Map<String, dynamic>? profile) {
    final raw = (profile?['name'] as String?)?.trim();
    return (raw != null && raw.isNotEmpty) ? raw : 'Lojista';
  }

  String _buildInFilter(List<String> values) {
    final sanitized = values
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .map((value) => '"$value"')
        .join(',');
    return '($sanitized)';
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
        const SliverToBoxAdapter(
          child: SizedBox(height: 20),
        ),
      ],
    );
  }

  Widget _buildLojistaCard(Map<String, dynamic> lojista) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final avatarUrl = (lojista['avatar_url'] as String?)?.trim() ?? '';
    final cidade = (lojista['cidade'] as String?)?.trim() ?? '';
    final estado = (lojista['estado'] as String?)?.trim() ?? '';
    final localizacao = [cidade, estado].where((part) => part.isNotEmpty).join(' - ');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => LojistaAnunciosPage(lojista: lojista),
            ),
          );
          _carregarLojistasSeguidos();
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
            // Avatar do lojista
            CircleAvatar(
              radius: 24,
              backgroundColor: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey[200],
              backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
              child: avatarUrl.isNotEmpty
                  ? null
                  : Icon(
                      Icons.person,
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
                    localizacao.isNotEmpty ? localizacao : 'Localização indisponível',
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
    ),
  );
  }
}