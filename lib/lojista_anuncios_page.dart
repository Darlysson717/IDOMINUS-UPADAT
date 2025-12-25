import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'veiculo_card.dart';
import 'services/follow_service.dart';

class LojistaAnunciosPage extends StatefulWidget {
  final Map<String, dynamic> lojista;

  const LojistaAnunciosPage({super.key, required this.lojista});

  @override
  State<LojistaAnunciosPage> createState() => _LojistaAnunciosPageState();
}

class _LojistaAnunciosPageState extends State<LojistaAnunciosPage> {
  List<Map<String, dynamic>> _veiculos = [];
  bool _loading = true;
  bool _isFollowing = false;
  bool _loadingFollow = false;

  @override
  void initState() {
    super.initState();
    _carregarAnuncios();
    _checkIfFollowing();
  }

  Future<void> _carregarAnuncios() async {
    if (mounted) {
      setState(() => _loading = true);
    }

    try {
      final response = await Supabase.instance.client
          .from('veiculos')
          .select()
          .eq('user_id', widget.lojista['user_id'])
          .eq('status', 'ativo')
          .order('criado_em', ascending: false);

      if (mounted) {
        setState(() {
          _veiculos = (response as List<dynamic>).cast<Map<String, dynamic>>();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar anúncios: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _checkIfFollowing() async {
    final sellerUserId = widget.lojista['user_id'] as String?;
    if (sellerUserId == null) return;

    try {
      final isFollowing = await FollowService.I.isFollowing(sellerUserId);
      if (mounted) {
        setState(() => _isFollowing = isFollowing);
      }
    } catch (_) {
      // Silêncio: não queremos travar a UI caso a verificação falhe
    }
  }

  Future<void> _toggleFollow() async {
    final sellerUserId = widget.lojista['user_id'] as String?;
    if (sellerUserId == null) return;

    if (mounted) {
      setState(() => _loadingFollow = true);
    }

    try {
      if (_isFollowing) {
        await FollowService.I.unfollowSeller(sellerUserId);
      } else {
        await FollowService.I.followSeller(sellerUserId);
      }

      if (mounted) {
        setState(() => _isFollowing = !_isFollowing);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao atualizar follow: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loadingFollow = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final avatarUrl = (widget.lojista['avatar_url'] as String?)?.trim() ?? '';
    final nome = (widget.lojista['nome_loja'] as String?)?.trim() ?? 'Lojista';
    final cidade = (widget.lojista['cidade'] as String?)?.trim() ?? '';
    final estado = (widget.lojista['estado'] as String?)?.trim() ?? '';
    final localizacao = [cidade, estado].where((part) => part.isNotEmpty).join(' - ');
    final totalAnuncios = _veiculos.length;

    Widget buildHeader() {
      return Container(
        padding: const EdgeInsets.all(16),
        color: isDark ? Colors.grey[900] : Colors.grey[100],
        child: Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: isDark ? Colors.white24 : Colors.grey[300],
              backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
              child: avatarUrl.isNotEmpty
                  ? null
                  : Icon(
                      Icons.person,
                      size: 32,
                      color: isDark ? Colors.white : Colors.grey[600],
                    ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nome,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    localizacao.isNotEmpty ? localizacao : 'Localização indisponível',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isDark ? Colors.white70 : Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$totalAnuncios ${totalAnuncios == 1 ? 'anúncio' : 'anúncios'}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark ? Colors.white60 : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              onPressed: _loadingFollow ? null : _toggleFollow,
              icon: _loadingFollow
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Icon(_isFollowing ? Icons.check : Icons.person_add, size: 18),
              label: Text(_isFollowing ? 'Seguindo' : 'Seguir'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isFollowing ? Colors.grey[700] : Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      );
    }

    Widget buildBody() {
      if (_loading) {
        return const Center(child: CircularProgressIndicator());
      }

      if (_veiculos.isEmpty) {
        return RefreshIndicator(
          onRefresh: _carregarAnuncios,
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 24),
            children: [
              buildHeader(),
              const SizedBox(height: 40),
              Icon(
                Icons.inventory_2_outlined,
                size: 64,
                color: isDark ? Colors.white30 : Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Nenhum anúncio ativo',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: isDark ? Colors.white70 : Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Assim que o lojista publicar novos veículos, eles aparecerão aqui.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark ? Colors.white54 : Colors.grey[600],
                ),
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: () async {
          await _carregarAnuncios();
          await _checkIfFollowing();
        },
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: buildHeader()),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final veiculo = _veiculos[index];
                    final vehicleData = _extractVehicleData(veiculo);
                    final isLast = index == _veiculos.length - 1;
                    return Padding(
                      padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
                      child: VeiculoCard(
                        foto: vehicleData['foto']!,
                        nome: vehicleData['nome']!,
                        preco: vehicleData['preco']!,
                        ano: vehicleData['ano']!,
                        quilometragem: vehicleData['quilometragem']!,
                        cidadeEstado: vehicleData['cidadeEstado']!,
                        badge: '',
                        onVerDetalhes: () {
                          Navigator.pushNamed(
                            context,
                            '/detalhes',
                            arguments: veiculo,
                          ).then((_) => _checkIfFollowing());
                        },
                      ),
                    );
                  },
                  childCount: _veiculos.length,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Anúncios do Lojista'),
        backgroundColor: Colors.deepPurple,
      ),
      body: buildBody(),
    );
  }

  Map<String, String> _extractVehicleData(Map<String, dynamic> veiculo) {
    final foto = (() {
      final thumbs = veiculo['fotos_thumb'];
      if (thumbs is List && thumbs.isNotEmpty && thumbs.first is String) {
        return thumbs.first as String;
      }
      final primeiraFoto = veiculo['foto'];
      if (primeiraFoto is String && primeiraFoto.isNotEmpty) return primeiraFoto;
      final fotos = veiculo['fotos'];
      if (fotos is List && fotos.isNotEmpty && fotos.first is String) {
        return fotos.first as String;
      }
      return '';
    })();

    final nome = (() {
      if (veiculo['nome'] is String && (veiculo['nome'] as String).trim().isNotEmpty) {
        return veiculo['nome'];
      }
      if (veiculo['titulo'] is String && (veiculo['titulo'] as String).trim().isNotEmpty) {
        return veiculo['titulo'];
      }
      final partes = [
        veiculo['marca'],
        veiculo['modelo'],
        veiculo['versao'],
      ].whereType<String>().map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      if (partes.isNotEmpty) return partes.join(' ');
      return 'Veículo';
    })();

    final preco = (() {
      final precoRaw = veiculo['preco'];
      if (precoRaw == null) return 'Preço a consultar';
      if (precoRaw is num) {
        return 'R\$ ${precoRaw.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (match) => '${match[1]}.',
        )}';
      }
      return precoRaw.toString();
    })();

    final ano = (() {
      final valor = veiculo['ano_modelo'] ?? veiculo['ano_fab'] ?? veiculo['ano'];
      if (valor == null) return '-';
      return valor.toString();
    })();

    final quilometragem = (() {
      final valor = veiculo['km'] ?? veiculo['quilometragem'];
      if (valor == null) return '-';
      final texto = valor.toString();
      final formatado = texto.replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (match) => '${match[1]}.',
      );
      return '$formatado km';
    })();

    final cidadeEstado = (() {
      final cidade = (veiculo['cidade'] as String?)?.trim() ?? '';
      final estado = (veiculo['estado'] as String?)?.trim() ?? '';
      final partes = [cidade, estado].where((parte) => parte.isNotEmpty).toList();
      if (partes.isEmpty) return '-';
      return partes.join(' - ');
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
}
