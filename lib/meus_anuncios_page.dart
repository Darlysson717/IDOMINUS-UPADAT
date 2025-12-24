import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/vehicle_deletion_service.dart';

class MeusAnunciosPage extends StatefulWidget {
  const MeusAnunciosPage({super.key});

  @override
  State<MeusAnunciosPage> createState() => _MeusAnunciosPageState();
}

class _MeusAnunciosPageState extends State<MeusAnunciosPage> {
  List<Map<String, dynamic>> _anuncios = [];
  bool _loading = true;
  late final RealtimeChannel _realtimeChannel;

  @override
  void initState() {
    super.initState();
    _buscarAnuncios();
    
    // Configurar realtime para atualizações em tempo real dos anúncios do usuário
    _realtimeChannel = Supabase.instance.client
        .channel('meus_anuncios_changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'veiculos',
          callback: (payload) {
            // Recarregar anúncios quando houver qualquer mudança
            _buscarAnuncios();
          },
        )
        .subscribe();
  }

  Future<void> _buscarAnuncios() async {
    setState(() => _loading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        setState(() => _loading = false);
        return;
      }

      final response = await Supabase.instance.client
          .from('veiculos')
          .select()
          .eq('usuario_id', user.id)
          .order('criado_em', ascending: false);

      List<Map<String, dynamic>> anuncios = [];
      try {
        anuncios = List<Map<String, dynamic>>.from(response as List);
      } catch (_) {
        anuncios = [];
      }
      setState(() {
        _anuncios = anuncios;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _anuncios = [];
        _loading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar anúncios: $e')),
        );
      }
    }
  }

  Future<void> _deletarAnuncio(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: const Text('Tem certeza que deseja excluir este anúncio? Esta ação não pode ser desfeita e removerá todas as imagens associadas.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        // Usar o novo serviço de exclusão completa
        await VehicleDeletionService.deleteVehicle(id);

        setState(() {
          _anuncios.removeWhere((a) => a['id'] == id);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Anúncio e imagens excluídos com sucesso')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao excluir anúncio: $e')),
          );
        }
      }
    }
  }

  Future<void> _alterarStatus(String id, String novoStatus) async {
    try {
      await Supabase.instance.client
          .from('veiculos')
          .update({'status': novoStatus})
          .eq('id', id);

      setState(() {
        final index = _anuncios.indexWhere((a) => a['id'] == id);
        if (index != -1) {
          final atualizado = Map<String, dynamic>.from(_anuncios[index]);
          atualizado['status'] = novoStatus;
          _anuncios[index] = atualizado;
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              novoStatus == 'ativo' ? 'Anúncio ativado com sucesso' : 'Anúncio desativado com sucesso',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao atualizar status: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmall = size.width < 400;
    final horizontalPadding = size.width * 0.04;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Anúncios', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.deepPurple,
        elevation: 4,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar',
            onPressed: _buscarAnuncios,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _anuncios.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inventory, size: 64, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Você ainda não publicou anúncios',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/publicar');
                        },
                        child: Text('Publicar Anúncio'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Lista de anúncios
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                        child: ListView.separated(
                          itemCount: _anuncios.length + 1, // +1 para o card de aviso
                          separatorBuilder: (context, index) {
                            // Não mostrar separador após o card de aviso (index 0)
                            if (index == 0) return SizedBox.shrink();
                            return SizedBox(height: isSmall ? 8 : 16);
                          },
                          itemBuilder: (context, index) {
                            // Primeiro item: Card de aviso
                            if (index == 0) {
                              return Container(
                                margin: EdgeInsets.symmetric(horizontal: 0, vertical: 8),
                                child: Card(
                                  color: Colors.orange.shade50,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(color: Colors.orange.shade300, width: 1),
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.all(isSmall ? 12 : 16),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.warning_amber_rounded,
                                          color: Colors.orange.shade700,
                                          size: isSmall ? 24 : 28,
                                        ),
                                        SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Importante',
                                                style: TextStyle(
                                                  fontSize: isSmall ? 14 : 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.orange.shade800,
                                                ),
                                              ),
                                              SizedBox(height: 4),
                                              Text(
                                                'Exclua seu anúncio imediatamente após a venda do veículo. Anúncios de veículos já vendidos podem resultar na suspensão da sua conta.',
                                                style: TextStyle(
                                                  fontSize: isSmall ? 12 : 14,
                                                  color: Colors.orange.shade700,
                                                  height: 1.3,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }

                            // Ajustar o índice para os anúncios (remover 1 porque o primeiro item é o card de aviso)
                            final anuncioIndex = index - 1;
                            final anuncio = _anuncios[anuncioIndex];

                            final String foto = (() {
                              final thumbs = anuncio['fotos_thumb'];
                              if (thumbs is List && thumbs.isNotEmpty && thumbs.first is String) {
                                return thumbs.first as String;
                              }
                              final f = anuncio['foto'];
                              if (f is String && f.isNotEmpty) return f;
                              final fotos = anuncio['fotos'];
                              if (fotos is List && fotos.isNotEmpty) {
                                final first = fotos.first;
                                if (first is String) return first;
                              }
                              return '';
                            })();

                            final String nome = (() {
                              if (anuncio['nome'] is String && (anuncio['nome'] as String).trim().isNotEmpty) {
                                return anuncio['nome'];
                              }
                              if (anuncio['titulo'] is String && (anuncio['titulo'] as String).trim().isNotEmpty) {
                                return anuncio['titulo'];
                              }
                              final parts = [
                                anuncio['marca'],
                                anuncio['modelo'],
                                anuncio['versao'],
                              ].whereType<String>().map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
                              if (parts.isNotEmpty) return parts.join(' ');
                              return 'Veículo';
                            })();

                            final dynamic precoRaw = anuncio['preco'];
                            final String preco = (() {
                              if (precoRaw == null) return 'Preço a consultar';
                              if (precoRaw is num) {
                                return 'R\$ ${precoRaw.toStringAsFixed(2)}';
                              }
                              return precoRaw.toString();
                            })();

                            final String ano = (() {
                              final a = anuncio['ano_modelo'] ?? anuncio['ano_fab'] ?? anuncio['ano'];
                              if (a == null) return '-';
                              return a.toString();
                            })();

                            final String quilometragem = (() {
                              final q = anuncio['km'] ?? anuncio['quilometragem'];
                              if (q == null) return '-';
                              return q.toString();
                            })();

                            final String status = (anuncio['status'] ?? 'ativo').toString();
                            final bool ativo = status == 'ativo';
                            final Color statusColor = ativo ? Colors.green : Colors.grey;

                            final String cidadeEstado = (() {
                              final c = anuncio['cidade'];
                              final e = anuncio['estado'];
                              if (c == null && e == null) return '-';
                              final parts = [c, e].whereType<String>().map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
                              if (parts.isEmpty) return '-';
                              return parts.join(' - ');
                            })();

                            return Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 4,
                              shadowColor: Colors.black12,
                              margin: EdgeInsets.symmetric(vertical: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Imagem
                                  ClipRRect(
                                    borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                                    child: (foto.isEmpty || foto == 'null')
                                        ? Container(
                                            height: 200,
                                            width: double.infinity,
                                            color: Colors.grey[300],
                                            child: Icon(Icons.directions_car, size: 60, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.grey[600]),
                                          )
                                        : Image.network(
                                            foto,
                                            height: 200,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Container(
                                                height: 200,
                                                width: double.infinity,
                                                color: Colors.grey[300],
                                                child: Icon(Icons.directions_car, size: 60, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.grey[600]),
                                              );
                                            },
                                          ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Nome/modelo
                                        Text(
                                          nome,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        // Preço
                                        Text(
                                          preco,
                                          style: TextStyle(
                                            color: Colors.deepPurple,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        // Detalhes
                                        Row(
                                          children: [
                                            Icon(Icons.calendar_today, size: 16, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.grey[600]),
                                            const SizedBox(width: 4),
                                            Text(ano, style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                                            const SizedBox(width: 12),
                                            Icon(Icons.speed, size: 16, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.grey[600]),
                                            const SizedBox(width: 4),
                                            Text(quilometragem, style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                                            const SizedBox(width: 12),
                                            Icon(Icons.location_on, size: 16, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.grey[600]),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                cidadeEstado,
                                                style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            Chip(
                                              backgroundColor: statusColor.withValues(alpha: 0.12),
                                              label: Text(
                                                ativo ? 'Ativo' : 'Inativo',
                                                style: TextStyle(color: statusColor, fontWeight: FontWeight.w600),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            TextButton.icon(
                                              onPressed: anuncio['id'] == null
                                                  ? null
                                                  : () => _alterarStatus(
                                                        anuncio['id'].toString(),
                                                        ativo ? 'inativo' : 'ativo',
                                                      ),
                                              icon: Icon(
                                                ativo ? Icons.pause_circle_filled : Icons.check_circle,
                                                size: 18,
                                              ),
                                              label: Text(ativo ? 'Pausar anúncio' : 'Reativar'),
                                              style: TextButton.styleFrom(
                                                foregroundColor: statusColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        // Botões de ação
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            TextButton.icon(
                                              onPressed: () {
                                                Navigator.pushNamed(context, '/detalhes', arguments: anuncio);
                                              },
                                              icon: Icon(Icons.visibility, size: 18),
                                              label: Text('Ver'),
                                              style: TextButton.styleFrom(
                                                foregroundColor: Theme.of(context).brightness == Brightness.dark 
                                                  ? Colors.white 
                                                  : Colors.deepPurple,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            TextButton.icon(
                                              onPressed: () {
                                                Navigator.pushNamed(context, '/publicar', arguments: anuncio)
                                                    .then((_) => _buscarAnuncios());
                                              },
                                              icon: Icon(Icons.edit, size: 18),
                                              label: Text('Editar'),
                                              style: TextButton.styleFrom(
                                                foregroundColor: Theme.of(context).brightness == Brightness.dark 
                                                  ? Colors.white 
                                                  : Colors.blue,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            TextButton.icon(
                                              onPressed: () => _deletarAnuncio(anuncio['id']),
                                              icon: Icon(Icons.delete, size: 18),
                                              label: Text('Excluir'),
                                              style: TextButton.styleFrom(
                                                foregroundColor: Colors.red,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                )
    );
  }

  @override
  void dispose() {
    _realtimeChannel.unsubscribe();
    super.dispose();
  }
}