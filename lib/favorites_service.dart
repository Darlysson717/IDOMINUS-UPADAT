import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'services/favoritos_ranking_service.dart';

class FavoritesService extends ChangeNotifier {
  static final FavoritesService _instance = FavoritesService._internal();
  factory FavoritesService() => _instance;
  FavoritesService._internal();

  final Map<String, Map<String,dynamic>> _items = {}; // key: veiculo id (ou hash)
  bool _loadedFromServer = false;
  bool get loadedFromServer => _loadedFromServer;

  UnmodifiableListView<Map<String,dynamic>> get items => UnmodifiableListView(_items.values);

  bool isFavorited(String id) => _items.containsKey(id);

  void toggle(String id, Map<String,dynamic> data){
    if(isFavorited(id)){
      _items.remove(id);
    } else {
      _items[id] = data;
    }
    notifyListeners();
  }

  // ---------- Persistência Supabase ----------
  Future<void> syncFromServer() async {
    if(_loadedFromServer) return; // evita recarregar múltiplas vezes
    final user = Supabase.instance.client.auth.currentUser;
    if(user == null) return;
    try {
      _items.clear(); // Limpar favoritos anteriores para carregar apenas os do usuário atual
      // Busca favoritos com join simples dos campos principais do veículo
      // Ajuste conforme colunas existentes na tabela 'veiculos'
    final List data = await Supabase.instance.client
      .from('favoritos')
      .select('veiculo_id, veiculos(id,titulo,marca,modelo,versao,fotos,cidade,estado,preco,status)')
      .eq('user_id', user.id);
      for(final row in data){
        try {
          final veiculoId = row['veiculo_id']?.toString();
          final veiculo = row['veiculos'];
          if(veiculoId != null && veiculo is Map<String,dynamic>){
            _items[veiculoId] = veiculo;
          }
        } catch(_){/*ignorar item mal formatado*/}
      }
      _loadedFromServer = true;
      notifyListeners();
    } catch(e){
      // Falha silenciosa (poderia logar). Não marca loaded para tentar novamente depois.
    }
  }

  Future<void> addRemote(String veiculoId, Map<String,dynamic> veiculo) async {
    final user = Supabase.instance.client.auth.currentUser;
    if(user == null) throw Exception('Faça login para favoritar.');
    // UI otimista
    final wasPresent = _items.containsKey(veiculoId);
    _items[veiculoId] = veiculo;
    notifyListeners();
    try {
      // Evitar erro de chave duplicada: usar UPSERT com conflito em (user_id, veiculo_id)
      await Supabase.instance.client
          .from('favoritos')
          .upsert({
            'user_id': user.id,
            'veiculo_id': veiculoId,
          }, onConflict: 'user_id,veiculo_id');
      FavoritosRankingService.I.invalidateCache();

      // Notificar o dono do veículo se não for o próprio usuário
      if (veiculo['usuario_id'] != user.id) {
        print('🔔 FAVORITE: Sending notification to owner ${veiculo['usuario_id']}');
        try {
          final result = await Supabase.instance.client.from('notificacoes').insert({
            'user_id': veiculo['usuario_id'],
            'tipo': 'favorito',
            'mensagem': 'Your ad "${veiculo['titulo']}" has been favorited!',
            'veiculo_id': veiculoId,
          });
          print('✅ FAVORITE: Notification inserted: $result');
        } catch (e) {
          // Silenciar erro de notificação para não quebrar o favorito
          print('❌ FAVORITE: Error inserting notification: $e');
        }
      } else {
        print('🚫 FAVORITE: User favoriting own ad, no notification');
      }
    } on PostgrestException catch (error) {
      if(!wasPresent){
        _items.remove(veiculoId);
        notifyListeners();
      }
      throw Exception(error.message);
    } catch(e){
      if(!wasPresent){
        _items.remove(veiculoId);
        notifyListeners();
      }
      throw Exception(e.toString());
    }
  }

  Future<void> removeRemote(String veiculoId) async {
    final user = Supabase.instance.client.auth.currentUser;
    if(user == null) throw Exception('Faça login para alterar favoritos.');
    if(!_items.containsKey(veiculoId)) return; // já não está
    final backup = _items[veiculoId];
    _items.remove(veiculoId);
    notifyListeners();
    try {
      await Supabase.instance.client.from('favoritos')
          .delete()
          .match({'user_id': user.id, 'veiculo_id': veiculoId});
      FavoritosRankingService.I.invalidateCache();
    } on PostgrestException catch (error) {
      if(backup != null){
        _items[veiculoId] = backup;
        notifyListeners();
      }
      throw Exception(error.message);
    } catch(e){
      if(backup != null){
        _items[veiculoId] = backup;
        notifyListeners();
      }
      throw Exception(e.toString());
    }
  }

  void remove(String id){
    if(_items.remove(id) != null){
      notifyListeners();
    }
  }

  void clear(){
    if(_items.isNotEmpty){
      _items.clear();
      notifyListeners();
    }
  }

  void reset(){
    _items.clear();
    _loadedFromServer = false;
    notifyListeners();
  }
}
