import 'package:flutter/material.dart';
import 'favorites_service.dart';

class FavoritosPage extends StatefulWidget {
  const FavoritosPage({super.key});
  @override
  State<FavoritosPage> createState() => _FavoritosPageState();
}

class _FavoritosPageState extends State<FavoritosPage> {
  final FavoritesService _fav = FavoritesService();

  @override
  void initState() {
    super.initState();
    _fav.addListener(_onFavChange);
  }

  @override
  void dispose() {
    _fav.removeListener(_onFavChange);
    super.dispose();
  }

  void _onFavChange(){
    if(mounted) setState((){});
  }

  @override
  Widget build(BuildContext context) {
    final items = _fav.items;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favoritos'),
        actions: [
          if(items.isNotEmpty)
            IconButton(
              tooltip: 'Limpar todos',
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Limpar favoritos'),
                    content: const Text('Deseja remover todos os veículos favoritos?'),
                    actions: [
                      TextButton(onPressed: ()=> Navigator.pop(context,false), child: const Text('Cancelar')),
                      FilledButton(onPressed: ()=> Navigator.pop(context,true), child: const Text('Remover')),
                    ],
                  ),
                );
                if(ok == true){
                  _fav.clear();
                }
              },
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      body: items.isEmpty
          ? _EmptyState(onVoltar: (){ Navigator.pop(context); })
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemBuilder: (_, i){
                final v = items[i];
                final fotos = (v['fotos'] is List) ? List<String>.from(v['fotos']) : <String>[];
                final thumb = fotos.isNotEmpty ? fotos.first : null;
                final titulo = (v['titulo'] ?? '') as String;
                final precoRaw = v['preco'];
                String preco = '-';
                if(precoRaw is num){
                  preco = 'R\$ ' + precoRaw.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m)=>'.');
                } else if(precoRaw != null){
                  preco = precoRaw.toString();
                }
                final id = (v['id'] ?? v['uuid'] ?? v['codigo'] ?? v.hashCode).toString();
                return InkWell(
                  onTap: () {
                    Navigator.pushNamed(context, '/detalhes', arguments: v);
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(.4),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(.2)),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            width: 92, height: 72,
                            color: Colors.grey[300],
                            child: thumb != null ? Image.network(thumb, fit: BoxFit.cover, errorBuilder: (_, __, ___)=> const Icon(Icons.image)) : const Icon(Icons.directions_car),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                titulo.isNotEmpty ? titulo : _fallbackTitle(v),
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Text(preco, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.green.shade700)),
                              const SizedBox(height: 4),
                              Text(_buildResumo(v), style: const TextStyle(fontSize: 11, color: Colors.black54)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          tooltip: 'Remover',
                          onPressed: () => _fav.remove(id),
                          icon: const Icon(Icons.close),
                        )
                      ],
                    ),
                  ),
                );
              },
              separatorBuilder: (_, __)=> const SizedBox(height: 12),
              itemCount: items.length,
            ),
    );
  }

  String _fallbackTitle(Map<String,dynamic> v){
    final parts = [v['marca'], v['modelo'], v['versao']].whereType<String>().map((e)=> e.trim()).where((e)=> e.isNotEmpty).toList();
    return parts.isEmpty ? 'Veículo' : parts.join(' ');
  }

  String _buildResumo(Map<String,dynamic> v){
    final ano = v['ano_fab']?.toString();
    final kmRaw = v['km'];
    String km = '';
    if(kmRaw is num){
      km = kmRaw.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m)=>'.') + ' km';
    }
    return [ano, km].where((e)=> e!=null && e.isNotEmpty).join(' • ');
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onVoltar;
  const _EmptyState({required this.onVoltar});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border, size: 72, color: Colors.grey.shade500),
            const SizedBox(height: 20),
            const Text('Nenhum favorito ainda', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            const Text('Marque veículos como favoritos e eles aparecerão aqui.', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Colors.black54)),
            const SizedBox(height: 24),
            FilledButton.icon(onPressed: onVoltar, icon: const Icon(Icons.arrow_back), label: const Text('Voltar'))
          ],
        ),
      ),
    );
  }
}
