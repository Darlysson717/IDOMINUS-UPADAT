import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'veiculo_card.dart';
import 'perfil_page.dart';
import 'filtro_avancado.dart';
import 'lojistas_seguidos_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'favorites_service.dart';
import 'services/location_service.dart';
import 'services/recommendation_service.dart';
import 'widgets/vehicle_carousel.dart';
import 'widgets/skeleton_widgets.dart';
import 'services/update_service.dart';

String removeAccents(String str) {
  const accents = 'àáâãäåæçèéêëìíîïðñòóôõö÷øùúûüýþÿ';
  const noAccents = 'aaaaaaaceeeeiiiidnoooooouuuuyty';
  return str.split('').map((char) {
    final index = accents.indexOf(char.toLowerCase());
    return index != -1 ? noAccents[index] : char;
  }).join('');
}

class CompradorHome extends StatefulWidget {
  const CompradorHome({super.key});

  @override
  State<CompradorHome> createState() => _CompradorHomeState();
}

class _CompradorHomeState extends State<CompradorHome> with WidgetsBindingObserver {
  String? _erroSnack;
  Map<String, String?> _filtrosAvancados = {};
  int _selectedIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  String _cidadeFiltro = '';
  String _searchText = '';

  List<Map<String, dynamic>> _veiculos = [];
  bool _loading = true;
  late final RealtimeChannel _realtimeChannel;

  // Novos serviços para carrosséis
  final RecommendationService _recommendationService = RecommendationService.I;

  // Dados para carrosséis
  List<Map<String, dynamic>> _recommendedVehicles = [];
  bool _loadingRecommended = true;
  bool _hasLoadedRecommendations = false;

  // Controle de verificação de atualizações
  DateTime? _lastUpdateCheck;
  Timer? _periodicUpdateTimer;

  @override
  void initState() {
    print('🏠 CompradorHome initState chamado!');
    super.initState();
    
    // Adicionar observer para detectar quando o app volta ao foreground     
    WidgetsBinding.instance.addObserver(this);
    
    _buscarVeiculos();
    // Agendar verificação de updates para depois do carregamento inicial
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) _checkForUpdate();
    });
    _loadCarouselData();
    // sincroniza favoritos do servidor (carrega uma vez)
    FavoritesService().syncFromServer();    // Configurar realtime para atualizações em tempo real
    _realtimeChannel = Supabase.instance.client
        .channel('veiculos_changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'veiculos',
          callback: (payload) {
            // Recarregar anúncios quando houver qualquer mudança
            _buscarVeiculos();
          },
        )
        .subscribe();
    
    // Configurar verificação periódica de atualizações (a cada 24 horas)
    _setupPeriodicUpdateCheck();
  }

  void _setupPeriodicUpdateCheck() {
    // Verificar a cada 24 horas (86400000 milissegundos)
    _periodicUpdateTimer = Timer.periodic(
      const Duration(hours: 24),
      (timer) => _checkForUpdate(),
    );
  }

  @override
  void dispose() {
    _periodicUpdateTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _realtimeChannel.unsubscribe();
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // Verificar atualizações quando o app volta ao foreground (apenas se já passou tempo suficiente)
    if (state == AppLifecycleState.resumed) {
      final now = DateTime.now();
      if (_lastUpdateCheck == null || now.difference(_lastUpdateCheck!).inHours >= 1) {
        print('📱 App voltou ao foreground - verificando atualizações...');
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) _checkForUpdate();
        });
      }
    }
  }

  Future<void> _checkForUpdate() async {
    // Evitar verificações muito frequentes (mínimo 1 hora entre verificações)
    final now = DateTime.now();
    if (_lastUpdateCheck != null && 
        now.difference(_lastUpdateCheck!).inHours < 1) {
      return;
    }
    _lastUpdateCheck = now;
    
    if (kDebugMode) return; // Não verificar updates em debug
    
    try {
      final updateInfo = await UpdateService.checkForUpdate();
      
      if (updateInfo != null && mounted) {
        final currentVersion = await UpdateService.getCurrentVersion();
        final comparison = UpdateService.compareVersions(currentVersion, updateInfo['version']);

        if (comparison < 0) {
          _showForcedUpdateDialog(updateInfo);
        }
      }
    } catch (e) {
      print('⚠️ Erro na verificação automática de atualização: $e');
      // Não mostrar erro para o usuário, apenas log
    }
  }

  void _showForcedUpdateDialog(Map<String, dynamic> updateInfo) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Nova versão disponível'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Versão ${updateInfo['version']} está disponível.'),
            const SizedBox(height: 8),
            const Text('Atualize o app para continuar usando.'),
            const SizedBox(height: 8),
            if (updateInfo['changelog'] != null)
              Text(
                'Novidades:\n${updateInfo['changelog']}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () => SystemNavigator.pop(),
            icon: const Icon(Icons.exit_to_app, color: Colors.grey),
            label: const Text('Sair do App', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await UpdateService.openUpdateLink(updateInfo['apkUrl']);
                if (context.mounted) Navigator.of(context).pop();
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erro ao abrir a página de atualização: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Atualizar'),
          ),
        ],
      ),
    );
  }

  // Carregar dados para os carrosséis
  Future<void> _loadCarouselData() async {
    await _loadRecommendedVehicles();
  }

  Future<void> _loadRecommendedVehicles() async {
    if (mounted) {
      setState(() {
        _loadingRecommended = true;
        _hasLoadedRecommendations = false;
      });
    }
    try {
      final user = Supabase.instance.client.auth.currentUser;
      debugPrint('Carregando recomendações para usuário: ${user?.id ?? 'não logado'}');

      final recommendations = await _recommendationService.getPersonalizedRecommendations(limit: 20);
      debugPrint('Recomendações recebidas: ${recommendations.length}');

      if (mounted) {
        setState(() {
          _recommendedVehicles = recommendations;
          _loadingRecommended = false;
          _hasLoadedRecommendations = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingRecommended = false;
          _hasLoadedRecommendations = true;
        });
      }
      debugPrint('Erro ao carregar recomendações: $e');
    }
  }

  Future<void> _buscarVeiculos({bool aplicarStatus = true}) async {
    if (mounted) {
      setState(() => _loading = true);
    }
    try {
      // Build server-side filters based on _filtrosAvancados to reduce payload
      var query = Supabase.instance.client.from('veiculos').select();

      // Apenas anúncios ativos devem aparecer para compradores
      if (aplicarStatus) {
        query = query.eq('status', 'ativo');
      }

      // Search text: apply an OR across title, modelo, marca
      if (_searchText.isNotEmpty) {
        final escaped = _searchText.replaceAll('%', '\\%');
        // PostgREST OR expression
        query = query.or("titulo.ilike.%$escaped% , modelo.ilike.%$escaped% , marca.ilike.%$escaped% ");
      }

      // Textual ilike filters
      void addIlike(String key, String? value){
        if(value!=null && value.trim().isNotEmpty){
          final v = value.trim();
          query = query.ilike(key, '%$v%');
        }
      }

      addIlike('marca', _filtrosAvancados['marca']);
      addIlike('modelo', _filtrosAvancados['modelo']);
      addIlike('cor', _filtrosAvancados['cor']);
      // cidade é filtrada client-side pela localização detectada

      addIlike('carroceria', _filtrosAvancados['carroceria']);

      addIlike('direcao', _filtrosAvancados['direcao']);

      addIlike('farois', _filtrosAvancados['farois']);

      addIlike('situacao_veiculo', _filtrosAvancados['situacaoVeiculo']);

      // Exact-match selects
      if(_filtrosAvancados['combustivel']!=null && _filtrosAvancados['combustivel']!.isNotEmpty){
        query = query.eq('combustivel', _filtrosAvancados['combustivel']!);
      }
      if(_filtrosAvancados['cambio']!=null && _filtrosAvancados['cambio']!.isNotEmpty){
        query = query.eq('cambio', _filtrosAvancados['cambio']!);
      }
      if(_filtrosAvancados['motorizacao']!=null && _filtrosAvancados['motorizacao']!.isNotEmpty){
        query = query.eq('versao', _filtrosAvancados['motorizacao']!);
      }
      if(_filtrosAvancados['condicao']!=null && _filtrosAvancados['condicao']!.isNotEmpty){
        query = query.eq('condicao', _filtrosAvancados['condicao']!);
      }
      if(_filtrosAvancados['numPortas']!=null && _filtrosAvancados['numPortas']!.isNotEmpty){
        final p = int.tryParse(_filtrosAvancados['numPortas']!);
        if(p!=null) query = query.eq('num_portas', p);
      }
      if(_filtrosAvancados['carroceria']!=null && _filtrosAvancados['carroceria']!.isNotEmpty){
        query = query.eq('carroceria', _filtrosAvancados['carroceria']!);
      }

      // Numeric ranges
      if(_filtrosAvancados['anoMin']!=null && _filtrosAvancados['anoMin']!.isNotEmpty){
        final a = int.tryParse(_filtrosAvancados['anoMin']!);
        if(a!=null) query = query.gte('ano_fab', a);
      }
      if(_filtrosAvancados['anoMax']!=null && _filtrosAvancados['anoMax']!.isNotEmpty){
        final a = int.tryParse(_filtrosAvancados['anoMax']!);
        if(a!=null) query = query.lte('ano_fab', a);
      }
      if(_filtrosAvancados['precoMin']!=null && _filtrosAvancados['precoMin']!.isNotEmpty){
        final p = double.tryParse(_filtrosAvancados['precoMin']!.replaceAll(',', '.'));
        if(p!=null) query = query.gte('preco', p);
      }
      if(_filtrosAvancados['precoMax']!=null && _filtrosAvancados['precoMax']!.isNotEmpty){
        final p = double.tryParse(_filtrosAvancados['precoMax']!.replaceAll(',', '.'));
        if(p!=null) query = query.lte('preco', p);
      }
      if(_filtrosAvancados['kmMin']!=null && _filtrosAvancados['kmMin']!.isNotEmpty){
        final k = int.tryParse(_filtrosAvancados['kmMin']!);
        if(k!=null) query = query.gte('km', k);
      }
      if(_filtrosAvancados['kmMax']!=null && _filtrosAvancados['kmMax']!.isNotEmpty){
        final k = int.tryParse(_filtrosAvancados['kmMax']!);
        if(k!=null) query = query.lte('km', k);
      }

      // Always order by creation date desc
      final response = await query.order('criado_em', ascending: false);

      List<Map<String, dynamic>> veiculos = [];
      try {
        veiculos = List<Map<String, dynamic>>.from(response as List);
      } catch (_) {
        veiculos = [];
      }
      if (mounted) {
        setState(() {
          _veiculos = veiculos;
          _loading = false;
        });
      }
    } on PostgrestException catch (error) {
      if (aplicarStatus && error.code == '42703') {
        if (mounted) {
          setState(() {
            _erroSnack =
                'Coluna "status" não encontrada. Execute o script supabase/add_status_veiculos.sql e tente novamente.';
          });
        }
        await _buscarVeiculos(aplicarStatus: false);
        return;
      }
      if (mounted) {
        setState(() {
          _veiculos = [];
          _loading = false;
          _erroSnack = 'Erro ao carregar veículos: ${error.message}';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _veiculos = [];
          _loading = false;
          _erroSnack = 'Erro ao carregar veículos: $e';
        });
      }
    }
  }

  Future<void> _handleDetectLocation() async {
    final loc = LocationService.I;
    final ok = await loc.requestPermissionWithRationale();
    if (!ok) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permissão de localização negada.')),
        );
      }
      return;
    }

    await loc.fetch();
    if (!mounted) return;
    setState(() {
      _cidadeFiltro = loc.cidade ?? '';
    });
  }

  void _openFiltroAvancado() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => FiltroAvancado(
        onAplicar: (filtros) {
          setState(() {
            _filtrosAvancados = filtros;
          });
          _buscarVeiculos();
        },
        onLimpar: () {
          setState(() {
            _filtrosAvancados = {};
          });
          _buscarVeiculos();
        },
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_erroSnack != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _erroSnack != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_erroSnack!)),
          );
          setState(() {
            _erroSnack = null;
          });
        }
      });
    }
  }

  // Filtros personalizados (removido 'Novos' conforme mudança de requisito)
  List<String> get _filtros => ['Todos', 'Destaques', ' + favoritados'];
  String _filtroSelecionado = 'Todos';

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmall = size.width < 400;
    // final isLarge = size.width > 700; // reservado para futuros ajustes de layout responsivo
    final horizontalPadding = size.width * 0.04;
    final verticalPadding = isSmall ? 12.0 : size.height * 0.018;
    final primaryColor = const Color(0xFF4C1D95);
    final secondaryColor = const Color(0xFF7C3AED);
    final theme = Theme.of(context);
    final backgroundColor = theme.colorScheme.background;
    final surfaceColor = theme.colorScheme.surface;

    // Filtra veículos por busca e filtro (badge 'Novo' é calculada depois, sem filtro dedicado)
    var veiculosFiltrados = _veiculos.where((v) {
      final busca = _searchText.isEmpty ||
        (v['titulo']?.toLowerCase() ?? '').contains(_searchText.toLowerCase()) ||
        (v['modelo']?.toLowerCase() ?? '').contains(_searchText.toLowerCase()) ||
        (v['marca']?.toLowerCase() ?? '').contains(_searchText.toLowerCase());
      final bool filtro = (_filtroSelecionado == 'Todos' || v['ano']?.toString() == _filtroSelecionado);
      final marcaOk = _filtrosAvancados['marca'] == null || _filtrosAvancados['marca']!.isEmpty || (v['marca']?.toLowerCase() ?? '').contains(_filtrosAvancados['marca']!.toLowerCase());
      final modeloOk = _filtrosAvancados['modelo'] == null || _filtrosAvancados['modelo']!.isEmpty || (v['modelo']?.toLowerCase() ?? '').contains(_filtrosAvancados['modelo']!.toLowerCase());
      final anoMinOk = _filtrosAvancados['anoMin'] == null || _filtrosAvancados['anoMin']!.isEmpty || (v['ano'] ?? 0) >= int.tryParse(_filtrosAvancados['anoMin']!)!;
      final anoMaxOk = _filtrosAvancados['anoMax'] == null || _filtrosAvancados['anoMax']!.isEmpty || (v['ano'] ?? 9999) <= int.tryParse(_filtrosAvancados['anoMax']!)!;
      final precoMinOk = _filtrosAvancados['precoMin'] == null || _filtrosAvancados['precoMin']!.isEmpty || (v['preco'] ?? 0) >= double.tryParse(_filtrosAvancados['precoMin']!)!;
      final precoMaxOk = _filtrosAvancados['precoMax'] == null || _filtrosAvancados['precoMax']!.isEmpty || (v['preco'] ?? 999999999) <= double.tryParse(_filtrosAvancados['precoMax']!)!;
      final kmMinOk = _filtrosAvancados['kmMin'] == null || _filtrosAvancados['kmMin']!.isEmpty || (v['quilometragem'] ?? 0) >= int.tryParse(_filtrosAvancados['kmMin']!)!;
      final kmMaxOk = _filtrosAvancados['kmMax'] == null || _filtrosAvancados['kmMax']!.isEmpty || (v['quilometragem'] ?? 9999999) <= int.tryParse(_filtrosAvancados['kmMax']!)!;
      final corOk = _filtrosAvancados['cor'] == null || _filtrosAvancados['cor']!.isEmpty || (v['cor']?.toLowerCase() ?? '').contains(_filtrosAvancados['cor']!.toLowerCase());
      final combustivelOk = _filtrosAvancados['combustivel'] == null || _filtrosAvancados['combustivel']!.isEmpty || (v['combustivel'] ?? '').toLowerCase() == _filtrosAvancados['combustivel']!.toLowerCase();
      final cambioOk = _filtrosAvancados['cambio'] == null || _filtrosAvancados['cambio']!.isEmpty || (v['cambio'] ?? '').toLowerCase() == _filtrosAvancados['cambio']!.toLowerCase();
      final motorizacaoOk = _filtrosAvancados['motorizacao'] == null || _filtrosAvancados['motorizacao']!.isEmpty || (v['versao'] ?? '').toLowerCase() == _filtrosAvancados['motorizacao']!.toLowerCase();
      final numPortasOk = _filtrosAvancados['numPortas'] == null || _filtrosAvancados['numPortas']!.isEmpty || (v['num_portas']?.toString() ?? '') == _filtrosAvancados['numPortas'];
      final condicaoOk = _filtrosAvancados['condicao'] == null || _filtrosAvancados['condicao']!.isEmpty || (v['condicao'] ?? '').toLowerCase() == _filtrosAvancados['condicao']!.toLowerCase();

      final carroceriaOk = _filtrosAvancados['carroceria'] == null || _filtrosAvancados['carroceria']!.isEmpty || (v['carroceria']?.toLowerCase() ?? '').contains(_filtrosAvancados['carroceria']!.toLowerCase());

      final direcaoOk = _filtrosAvancados['direcao'] == null || _filtrosAvancados['direcao']!.isEmpty || (v['direcao']?.toLowerCase() ?? '').contains(_filtrosAvancados['direcao']!.toLowerCase());

      final faroisOk = _filtrosAvancados['farois'] == null || _filtrosAvancados['farois']!.isEmpty || (v['farois']?.toLowerCase() ?? '').contains(_filtrosAvancados['farois']!.toLowerCase());

      final situacaoVeiculoOk = _filtrosAvancados['situacaoVeiculo'] == null || _filtrosAvancados['situacaoVeiculo']!.isEmpty || (v['situacao_veiculo']?.toLowerCase() ?? '').contains(_filtrosAvancados['situacaoVeiculo']!.toLowerCase());

      // Cidade: filtra anúncios da cidade informada pelo comprador
      bool localCidadeOk = true;
      if (_cidadeFiltro.isNotEmpty) {
        final vCidade = v['cidade'] as String?;
        localCidadeOk = removeAccents(vCidade?.toLowerCase() ?? '').contains(removeAccents(_cidadeFiltro.toLowerCase()));
      }
      return busca && filtro && marcaOk && modeloOk && anoMinOk && anoMaxOk && precoMinOk && precoMaxOk && kmMinOk && kmMaxOk && corOk && combustivelOk && cambioOk && motorizacaoOk && numPortasOk && condicaoOk && carroceriaOk && direcaoOk && faroisOk && situacaoVeiculoOk && localCidadeOk;
    }).toList();

    final bool shouldShowRecommendationsCarousel =
      _loadingRecommended || _hasLoadedRecommendations;

    // nenhuma ordenação especial agora que filtro 'Novos' foi removido

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(88),
        child: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.dark,
          ),
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor, secondaryColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          titleSpacing: 24,
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dominus',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white),
              ),
              SizedBox(height: 4),
              Text(
                'Seu marketplace automotivo',
                style: TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications, color: Colors.white),
              onPressed: () {
                Navigator.of(context).pushNamed('/notifications');
              },
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: _loading
            ? _buildLoadingView()
            : RefreshIndicator(
                color: primaryColor,
                onRefresh: () => _buscarVeiculos(),
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                  slivers: [
                    SliverPadding(
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                        vertical: verticalPadding,
                      ),
                      sliver: SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: surfaceColor,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryColor.withValues(alpha: 0.08),
                                    blurRadius: 24,
                                    offset: const Offset(0, 12),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: _searchController,
                                          decoration: InputDecoration(
                                            hintText: 'Buscar veículo...',
                                            prefixIcon: Icon(Icons.search, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : primaryColor),
                                            filled: true,
                                            fillColor: backgroundColor,
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(16),
                                              borderSide: BorderSide(color: primaryColor.withValues(alpha: 0.1)),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(16),
                                              borderSide: BorderSide(color: primaryColor.withValues(alpha: 0.1)),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(16),
                                              borderSide: BorderSide(color: secondaryColor, width: 1.2),
                                            ),
                                            contentPadding: EdgeInsets.symmetric(
                                              vertical: isSmall ? 6 : 10,
                                              horizontal: isSmall ? 8 : 12,
                                            ),
                                          ),
                                          onChanged: (value) {
                                            setState(() {
                                              _searchText = value;
                                            });
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      SizedBox(
                                        height: 40,
                                        width: 40,
                                        child: Tooltip(
                                          message: 'Filtros avançados',
                                          child: InkWell(
                                            onTap: _openFiltroAvancado,
                                            borderRadius: BorderRadius.circular(14),
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: backgroundColor,
                                                borderRadius: BorderRadius.circular(14),
                                                border: Border.all(color: primaryColor.withValues(alpha: 0.16)),
                                              ),
                                              child: Icon(Icons.tune_rounded, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : primaryColor, size: 20),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Stack(
                                    children: [
                                      SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: Row(
                                          children: [
                                            FilterChip(
                                              avatar: Icon(
                                                Icons.location_on,
                                                size: 18,
                                                color: _cidadeFiltro.isNotEmpty ? Colors.white : (Theme.of(context).brightness == Brightness.dark ? Colors.white : primaryColor),
                                              ),
                                              label: Text(
                                                _cidadeFiltro.isEmpty ? 'Detectar cidade' : _cidadeFiltro,
                                                style: TextStyle(color: _cidadeFiltro.isNotEmpty ? Colors.white : (Theme.of(context).brightness == Brightness.dark ? Colors.white : primaryColor), fontWeight: FontWeight.w600),
                                              ),
                                              selected: _cidadeFiltro.isNotEmpty,
                                              selectedColor: secondaryColor,
                                              backgroundColor: backgroundColor,
                                              side: BorderSide(color: _cidadeFiltro.isNotEmpty ? Colors.transparent : (Theme.of(context).brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.2) : primaryColor.withValues(alpha: 0.16))),
                                              onSelected: (_) => _handleDetectLocation(),
                                              onDeleted: _cidadeFiltro.isNotEmpty
                                                  ? () {
                                                      setState(() {
                                                        _cidadeFiltro = '';
                                                      });
                                                    }
                                                  : null,
                                              deleteIcon: const Icon(Icons.close, size: 18),
                                              deleteIconColor: _cidadeFiltro.isNotEmpty ? Colors.white : Colors.grey,
                                              showCheckmark: false,
                                              visualDensity: VisualDensity.compact,
                                            ),
                                            if (_filtrosAvancados.isNotEmpty) ...[
                                              const SizedBox(width: 8),
                                              FilterChip(
                                                avatar: Icon(Icons.filter_alt_off_outlined, size: 18, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : primaryColor),
                                                label: Text('Limpar filtros', style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : primaryColor, fontWeight: FontWeight.w600)),
                                                backgroundColor: backgroundColor,
                                                side: BorderSide(color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.2) : primaryColor.withValues(alpha: 0.16)),
                                                onSelected: (_) {
                                                  setState(() {
                                                    _filtrosAvancados = {};
                                                  });
                                                  _buscarVeiculos();
                                                },
                                                visualDensity: VisualDensity.compact,
                                              ),
                                            ],
                                            ..._filtros.map((filtro) {
                                              final selecionado = filtro == _filtroSelecionado;
                                              return Padding(
                                                padding: const EdgeInsets.only(left: 8),
                                                child: ChoiceChip(
                                                  label: Text(filtro),
                                                  selected: selecionado,
                                                  onSelected: (_) {
                                                    if (filtro.trim().toLowerCase() == '+ favoritados') {
                                                      Navigator.pushNamed(context, '/mais-favoritos');
                                                      return;
                                                    }
                                                    setState(() {
                                                      _filtroSelecionado = filtro;
                                                    });
                                                  },
                                                  showCheckmark: false,
                                                  selectedColor: secondaryColor,
                                                  backgroundColor: surfaceColor,
                                                  pressElevation: 0,
                                                  side: BorderSide(
                                                    color: selecionado ? Colors.transparent : (Theme.of(context).brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.2) : primaryColor.withValues(alpha: 0.2)),
                                                  ),
                                                  labelStyle: TextStyle(
                                                    fontSize: isSmall ? 12 : 14,
                                                    fontWeight: FontWeight.w600,
                                                    color: selecionado ? Colors.white : (Theme.of(context).brightness == Brightness.dark ? Colors.white : primaryColor),
                                                  ),
                                                ),
                                              );
                                            }),
                                            const SizedBox(width: 32),
                                          ],
                                        ),
                                      ),
                                      Positioned(
                                        right: 0,
                                        top: 0,
                                        bottom: 0,
                                        child: IgnorePointer(
                                          child: Container(
                                            width: 36,
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.centerLeft,
                                                end: Alignment.centerRight,
                                                colors: [
                                                  surfaceColor.withValues(alpha: 0.0),
                                                  surfaceColor.withValues(alpha: 0.9),
                                                ],
                                              ),
                                            ),
                                            child: Align(
                                              alignment: Alignment.centerRight,
                                              child: Icon(
                                                Icons.chevron_right,
                                                color: primaryColor.withValues(alpha: 0.6),
                                                size: 18,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: isSmall ? 8 : 14),
                          ],
                        ),
                      ),
                    ),
                    if (veiculosFiltrados.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(Icons.directions_car_filled_outlined, size: 48, color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.4) : primaryColor.withValues(alpha: 0.4)),
                              const SizedBox(height: 12),
                              Text(
                                'Nenhum veículo encontrado com os filtros atuais.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: primaryColor.withValues(alpha: 0.6),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tente ajustar a busca ou redefinir os filtros para encontrar mais opções.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: primaryColor.withValues(alpha: 0.5)),
                              ),
                                if (shouldShowRecommendationsCarousel) ...[
                                  const SizedBox(height: 32),
                                  VehicleCarousel(
                                    title: 'Recomendações para Você',
                                    vehicles: _recommendedVehicles,
                                    isLoading: _loadingRecommended,
                                    simpleMode: true,
                                    emptyMessage: 'Nenhuma recomendação disponível no momento.',
                                  ),
                                ],
                            ],
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(horizontalPadding, 0, horizontalPadding, 24),
                        sliver: SliverList(
                          delegate: (() {
                            final bool showRecommendationsCarousel = shouldShowRecommendationsCarousel;
                            final int carouselInsertIndex = showRecommendationsCarousel
                                ? (veiculosFiltrados.length >= 5 ? 5 : veiculosFiltrados.length)
                                : -1;
                            final int totalItems = veiculosFiltrados.length + (showRecommendationsCarousel ? 1 : 0);

                            return SliverChildBuilderDelegate(
                              (context, index) {
                                final bool isLastElement = index == totalItems - 1;
                                final double bottomSpacing = isLastElement ? 0 : (isSmall ? 16 : 24);

                                if (showRecommendationsCarousel && index == carouselInsertIndex) {
                                  return Padding(
                                    padding: EdgeInsets.only(bottom: bottomSpacing),
                                    child: VehicleCarousel(
                                      title: 'Recomendações para Você',
                                      vehicles: _recommendedVehicles,
                                      isLoading: _loadingRecommended,
                                      simpleMode: true,
                                      emptyMessage: 'Nenhuma recomendação disponível no momento.',
                                    ),
                                  );
                                }

                                final int adjustedIndex = showRecommendationsCarousel && index > carouselInsertIndex
                                    ? index - 1
                                    : index;

                                final veiculo = veiculosFiltrados[adjustedIndex];
                                // Normalização e proteção contra nulls / tipos inesperados
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
                              if (badge.trim().isEmpty) {
                                final raw = veiculo['criado_em'];
                                DateTime? dt;
                                if (raw is DateTime) {
                                  dt = raw;
                                } else if (raw is String) {
                                  try {
                                    dt = DateTime.parse(raw);
                                  } catch (_) {
                                    // ignora datas inválidas
                                  }
                                }
                                if (dt != null && DateTime.now().difference(dt).inDays <= 7) {
                                  badge = 'Novo';
                                }
                              }

                              return Padding(
                                padding: EdgeInsets.only(bottom: bottomSpacing),
                                child: VeiculoCard(
                                  foto: foto,
                                  nome: nome,
                                  preco: preco,
                                  ano: ano,
                                  quilometragem: quilometragem,
                                  cidadeEstado: cidadeEstado,
                                  badge: badge,
                                  onVerDetalhes: () {
                                    Navigator.pushNamed(context, '/detalhes', arguments: veiculo);
                                  },
                                ),
                              );
                              },
                              childCount: totalItems,
                            );
                          })(),
                        ),
                      ),
                  ],
                ),
              ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: surfaceColor,
        elevation: 14,
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : primaryColor,
        unselectedItemColor: Theme.of(context).brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.6) : primaryColor.withValues(alpha: 0.4),
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        onTap: (index) {
          if (index == 0) {
            if (mounted) setState(() => _selectedIndex = 0);
          } else if (index == 1) {
            if (mounted) setState(() => _selectedIndex = 1);
            Navigator.pushNamed(context, '/favoritos');
          } else if (index == 2) {
            if (mounted) setState(() => _selectedIndex = 2);
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const LojistasSeguidosPage()),
            );
          } else if (index == 3) {
            if (mounted) setState(() => _selectedIndex = 3);
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PerfilPage()),
            );
          }
        },
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

  Widget _buildLoadingView() {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width * 0.04,
            vertical: MediaQuery.of(context).size.height * 0.02,
          ),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Simular a barra de busca
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[800]
                        : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.search,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[400]
                            : Colors.grey[600],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          height: 16,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[700]
                              : Colors.grey[300],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Simular filtros
                Row(
                  children: [
                    Container(
                      height: 32,
                      width: 80,
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[800]
                            : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[700]!
                              : Colors.grey[300]!,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      height: 32,
                      width: 100,
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[800]
                            : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[700]!
                              : Colors.grey[300]!,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Lista de skeletons
                VehicleListSkeleton(itemCount: 8),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
