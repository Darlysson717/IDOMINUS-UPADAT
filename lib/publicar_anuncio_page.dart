import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';
import 'services/location_service.dart';
import 'services/seller_verification_service.dart';
import 'models/seller_verification.dart';

class PublicarAnuncioPage extends StatefulWidget {
  final Map<String, dynamic>? anuncio;

  const PublicarAnuncioPage({Key? key, this.anuncio}) : super(key: key);
  @override
  State<PublicarAnuncioPage> createState() => _PublicarAnuncioPageState();
}

class _PublicarAnuncioPageState extends State<PublicarAnuncioPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  // Controladores básicos
  final _titulo = TextEditingController();
  final _descricao = TextEditingController();
  final _preco = TextEditingController();
  final _modelo = TextEditingController();
  final _versao = TextEditingController();
  final _anoFab = TextEditingController();
  final _km = TextEditingController();
  final _cidade = TextEditingController();
  final _cor = TextEditingController();
  final _whatsapp = TextEditingController();
  // Removidos controladores textuais -> agora switches
  final _airbags = TextEditingController();
  final _garantia = TextEditingController();

  // Seletivos
  String? _condicao; // Novo / Usado / Seminovo
  // Pagamentos múltiplos
  final List<String> _pagamentoOpcoes = const [
    'À vista','Financiamento','Consórcio','Troca aceita','Pix','Cartão','Entrada + Parcelas'
  ];
  final Set<String> _pagamentosSelecionados = {};
  String? _combustivel; // Gasolina / Flex / etc
  String? _cambio; // Manual / Automático / CVT
  String? _numPortas; // 2 4 5
  String? _direcao; // Elétrica / Hidráulica / Mecânica
  String? _farois; // LED / Halógeno / Xenon
  String? _situacaoVeiculo; // Em dia / Financiado / etc
  // Carroceria
  final List<String> _carrocerias = const [
    'Hatch','Sedan','SUV','Picape','Perua','Cupê','Conversível','Minivan','Utilitário','Outro'
  ];
  String? _carroceria;
  // Versões / motorização
  final List<String> _versoesPadrao = const [
    '1.0','1.0 Turbo','1.3','1.4','1.4 Turbo','1.5','1.6','1.6 16V','1.8','2.0','2.0 Turbo','2.2','2.4','V6','V8','Elétrico','Híbrido','Outro'
  ];
  String? _versaoSelecionada;
  // Marcas disponíveis no Brasil (principais + novas montadoras elétricas)
  final List<String> _marcasBrasil = const [
    'Chevrolet','Volkswagen','Fiat','Toyota','Hyundai','Jeep','Renault','Honda','Nissan','Caoa Chery',
    'Peugeot','Citroën','Mitsubishi','BMW','Mercedes-Benz','Audi','Volvo','Land Rover','Suzuki','Kia',
    'Ford','JAC','RAM','BYD','GWM (Haval)','Mini','Porsche','Jaguar','Lexus','Ferrari','Maserati','Dodge','Subaru'
  ];
  String? _marcaSelecionada;
  // Localização simplificada
  final List<String> _ufs = const [
    'AC','AL','AP','AM','BA','CE','DF','ES','GO','MA','MT','MS','MG','PA','PB','PR','PE','PI','RJ','RN','RS','RO','RR','SC','SP','SE','TO'
  ];
  String? _ufSelecionado;

  // Booleans simples (armazenaremos como texto Sim/Não para compatibilidade)
  bool _arCondicionado = false;
  bool _vidrosDianteiros = false;
  bool _vidrosTraseiros = false;
  bool _travasEletricas = false;
  bool _bancosCouro = false;
  bool _abs = false;
  bool _controleEstabilidade = false;
  bool _sensorEstacionamento = false;
  bool _manualChave = false;
  bool _ipvaPago = false;
  bool _multimidiaPresente = false;
  bool _rodasLigaLeve = false;

  // Fotos
  final ImagePicker _picker = ImagePicker();
  final List<File> _fotos = [];
  final List<Uint8List> _thumbs = [];
  final List<String> _thumbUrls = [];
  bool _publicando = false;

  // Animações
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _fadeController.forward();

    // Pre-fill fields if editing
    if (widget.anuncio != null) {
      final a = widget.anuncio!;
      _titulo.text = a['titulo'] ?? '';
      _descricao.text = a['descricao'] ?? '';
      _preco.text = _formatPrice(a['preco']);
      _modelo.text = a['modelo'] ?? '';
      _versao.text = a['versao'] ?? '';
      _anoFab.text = a['ano_fab']?.toString() ?? '';
      _km.text = a['km']?.toString() ?? '';
      _cidade.text = a['cidade'] ?? '';
      _cor.text = a['cor'] ?? '';
      _whatsapp.text = a['whatsapp'] ?? '';
      _condicao = a['condicao']?.toString();
      _combustivel = a['combustivel']?.toString();
      _cambio = a['cambio']?.toString();
      _numPortas = a['num_portas']?.toString();
      _direcao = a['direcao']?.toString();
      _farois = a['farois']?.toString();
      _situacaoVeiculo = a['situacao_veiculo']?.toString();
      _carroceria = a['carroceria']?.toString();
      _versaoSelecionada = a['versao']?.toString();
      _marcaSelecionada = a['marca']?.toString();
      _ufSelecionado = a['estado']?.toString();
      _arCondicionado = a['ar_condicionado'] == true || a['ar_condicionado'] == 'Sim';
      _vidrosDianteiros = a['vidros_dianteiros'] == true || a['vidros_dianteiros'] == 'Sim';
      _vidrosTraseiros = a['vidros_traseiros'] == true || a['vidros_traseiros'] == 'Sim';
      _travasEletricas = a['travas_eletricas'] == true || a['travas_eletricas'] == 'Sim';
      _bancosCouro = a['bancos_couro'] == true || a['bancos_couro'] == 'Sim';
      _abs = a['abs'] == true || a['abs'] == 'Sim';
      _controleEstabilidade = a['controle_estabilidade'] == true || a['controle_estabilidade'] == 'Sim';
      _sensorEstacionamento = a['sensor_estacionamento'] == true || a['sensor_estacionamento'] == 'Sim';
      _manualChave = a['manual_chave'] == true || a['manual_chave'] == 'Sim';
      _ipvaPago = a['ipva_pago'] == true || a['ipva_pago'] == 'Sim';
      _multimidiaPresente = a['multimidia'] == true || a['multimidia'] == 'Sim';
      _rodasLigaLeve = a['rodas_liga'] == true || a['rodas_liga'] == 'Sim';

      // Campo airbags (TextEditingController)
      _airbags.text = a['airbags']?.toString() ?? '';
      _garantia.text = a['garantia'] ?? '';

      // Pagamentos selecionados
      final pagamentoRaw = a['pagamento'];
      if (pagamentoRaw is String && pagamentoRaw.isNotEmpty) {
        _pagamentosSelecionados.addAll(pagamentoRaw.split(', ').map((e) => e.trim()));
      } else if (pagamentoRaw is List) {
        _pagamentosSelecionados.addAll(pagamentoRaw.map((e) => e.toString()));
      }

      // Fotos existentes (URLs)
      final fotosUrls = a['fotos'] as List<dynamic>? ?? [];
      _thumbUrls.addAll(fotosUrls.map((e) => e.toString()));
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    for (final c in [
  _titulo,_descricao,_preco,_modelo,_versao,_anoFab,_km,_cidade,_cor,_airbags,_garantia
    ]) { c.dispose(); }
    super.dispose();
  }

  // -------- Utilidades de parsing --------
  int? _int(String v){
    if(v.trim().isEmpty) return null;
    final digits = v.replaceAll(RegExp(r'[^0-9]'), '');
    if(digits.isEmpty) return null;
    return int.tryParse(digits);
  }
  double? _parsePrecoValor(dynamic preco) {
    if (preco == null) return null;
    if (preco is num) return preco.toDouble();
    if (preco is String) {
      final trimmed = preco.trim();
      if (trimmed.isEmpty) return null;
      final digits = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
      if (digits.isEmpty) return null;

      int decimalDigits = 0;
      final match = RegExp(r'[.,](\d+)\s*$').firstMatch(trimmed);
      if (match != null) {
        decimalDigits = match.group(1)?.length ?? 0;
        if (decimalDigits > 2) decimalDigits = 0;
      }

      final valorInt = double.tryParse(digits);
      if (valorInt == null) return null;

      double divisor = 1;
      for (var i = 0; i < decimalDigits; i++) {
        divisor *= 10;
      }

      return valorInt / divisor;
    }
    return null;
  }

  double? _double(String v){
    return _parsePrecoValor(v);
  }

  final _priceFormatter = _PriceFormatter();
  // _simNao removido: agora usamos boolean nativo direto no insert

  // Função auxiliar para formatar preço
  String _formatPrice(dynamic preco) {
    final valor = _parsePrecoValor(preco);
    if (valor == null) return '';
    final inteiro = valor.round();
    return NumberFormat.decimalPattern('pt_BR').format(inteiro);
  }

  // -------- Geração de thumbnail --------
  Future<Uint8List> _geraThumb(File f) async {
    final bytes = await f.readAsBytes();
    final original = img.decodeImage(bytes);
    if (original == null) return bytes;
    final thumb = img.copyResize(original, width: 240);
    return Uint8List.fromList(img.encodeJpg(thumb, quality: 75));
  }

  // -------- Seleção de fotos --------
  Future<void> _addFotos() async {
    try {
      final imgs = await _picker.pickMultiImage(imageQuality: 80);
      if (imgs.isEmpty) return;
      final restantes = 10 - _fotos.length;
      if (restantes <= 0) return;
      setState(() => _fotos.addAll(imgs.take(restantes).map((e) => File(e.path))));
      // gerar thumbs
      _thumbs.clear();
      for (final f in _fotos) { _thumbs.add(await _geraThumb(f)); }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao selecionar fotos: $e')));
    }
  }

  Future<Map<String,List<String>>> _uploadFotos() async {
    final client = Supabase.instance.client;
    final List<String> urls = [];
    _thumbUrls.clear();
    for (int i=0;i<_fotos.length;i++) {
      final f = _fotos[i];
      final originalBytes = await f.readAsBytes();
      // compressão leve (se largura > 1800px reduz para 1800)
      final decoded = img.decodeImage(originalBytes);
      Uint8List uploadBytes = originalBytes;
      if (decoded != null) {
        img.Image processed = decoded;
        if (processed.width > 1800) {
          processed = img.copyResize(processed, width: 1800);
        }
        uploadBytes = Uint8List.fromList(img.encodeJpg(processed, quality: 85));
      }
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final baseName = f.path.split('/').last;
  final name = 'anuncios/${timestamp}_$baseName';
      await client.storage.from('fotos').uploadBinary(name, uploadBytes, fileOptions: const FileOptions(contentType: 'image/jpeg')); 
      final publicUrl = client.storage.from('fotos').getPublicUrl(name);
      urls.add(publicUrl);
      if (_thumbs.length == _fotos.length) {
  final tName = 'anuncios/thumbs/${timestamp}_$baseName';
        await client.storage.from('fotos').uploadBinary(tName, _thumbs[i], fileOptions: const FileOptions(contentType: 'image/jpeg'));
        final tUrl = client.storage.from('fotos').getPublicUrl(tName);
        _thumbUrls.add(tUrl);
      }
    }
    return { 'orig': urls, 'thumb': List<String>.from(_thumbUrls) };
  }

  Future<void> _publicar() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Faça login para publicar.')));
      return;
    }
    setState(() => _publicando = true);
    try {
  final upload = await _uploadFotos();
  final fotosUrls = upload['orig'] ?? [];
  // Normalização de cidade (Title Case) e UF maiúscula
  String cidadeRaw = _cidade.text.trim();
  String cidadeNorm = cidadeRaw.split(RegExp(r'\s+')).map((p){
    if(p.isEmpty) return '';
    final lower = p.toLowerCase();
    return lower[0].toUpperCase()+lower.substring(1);
  }).join(' ');
  final ufNorm = _ufSelecionado?.toUpperCase();
  // thumbnails ignoradas pois coluna fotos_thumb não existe no schema atual
  final anuncio = <String,dynamic>{
        'titulo': _titulo.text.trim(),
        'descricao': _descricao.text.trim(),
        'preco': _double(_preco.text),
  'marca': _marcaSelecionada,
        'modelo': _modelo.text.trim(),
    'versao': _versaoSelecionada == null
      ? null
      : (_versaoSelecionada == 'Outro' ? _versao.text.trim() : _versaoSelecionada),
        'ano_fab': _int(_anoFab.text),
        'km': _int(_km.text),
  'cidade': cidadeNorm.isEmpty ? null : cidadeNorm,
  'estado': ufNorm,
        'cor': _cor.text.trim(),
        'whatsapp': _whatsapp.text.trim(),
        'condicao': _condicao,
  // Mantém compatibilidade: primeiro pagamento (se houver) + lista completa
  // Armazena todas as formas selecionadas em uma única string separada por vírgula
  'pagamento': _pagamentosSelecionados.isEmpty ? null : _pagamentosSelecionados.join(', '),
        'garantia': _garantia.text.trim(),
        'combustivel': _combustivel,
        'cambio': _cambio,
        'num_portas': _numPortas == null? null : _int(_numPortas!),
        'direcao': _direcao,
        'farois': _farois,
        'situacao_veiculo': _situacaoVeiculo,
  'carroceria': _carroceria,
        'ar_condicionado': _arCondicionado,
        'vidros_dianteiros': _vidrosDianteiros,
        'vidros_traseiros': _vidrosTraseiros,
        'travas_eletricas': _travasEletricas,
        'bancos_couro': _bancosCouro,
  'multimidia': _multimidiaPresente,
  'rodas_liga': _rodasLigaLeve,
        'airbags': _int(_airbags.text.replaceAll(RegExp(r'[^0-9]'), '')),
        'abs': _abs,
        'controle_estabilidade': _controleEstabilidade,
        'sensor_estacionamento': _sensorEstacionamento,
        'manual_chave': _manualChave,
        'ipva_pago': _ipvaPago,
  if (fotosUrls.isNotEmpty) 'fotos': fotosUrls,
        'criado_em': DateTime.now().toIso8601String(),
        'usuario_id': user.id,
  'status': widget.anuncio?['status'] ?? 'ativo',
        // Coordenadas GPS para localização geográfica
        if (LocationService.I.lat != null) 'lat': LocationService.I.lat,
        if (LocationService.I.lon != null) 'lon': LocationService.I.lon,
      };
      // Remove strings vazias
      anuncio.removeWhere((k,v) => v is String && v.trim().isEmpty);
      try {
        dynamic resp;
        if (widget.anuncio != null) {
          // Update existing ad
          resp = await Supabase.instance.client
              .from('veiculos')
              .update(anuncio)
              .eq('id', widget.anuncio!['id'])
              .select();
        } else {
          // Insert new ad
          resp = await Supabase.instance.client.from('veiculos').insert(anuncio).select();
        }
        if (resp.isNotEmpty) {
          final message = widget.anuncio != null ? 'Anúncio atualizado!' : 'Anúncio publicado!';
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
          if (widget.anuncio == null) {
            _formKey.currentState?.reset();
            setState(() { _fotos.clear(); });
          }
        }
      } on PostgrestException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Falha ao salvar: ${e.message}')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao publicar: $e')));
    } finally {
      if (mounted) setState(()=>_publicando=false);
    }
  }

  Widget _sectionTitle(String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12.0),
    child: Text(text, style: const TextStyle(fontSize:18,fontWeight: FontWeight.bold,color: Colors.deepPurple)),
  );

  Widget _sectionCard(String title, List<Widget> children) => LayoutBuilder(
    builder: (context, constraints) {
      final isSmall = constraints.maxWidth < 600;
      return FadeTransition(
        opacity: _fadeAnimation,
        child: Card(
          elevation: 4,
          margin: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: EdgeInsets.all(isSmall ? 12 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: isSmall ? 18 : 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
                const SizedBox(height: 12),
                ...children,
              ],
            ),
          ),
        ),
      );
    },
  );

  InputDecoration _dec(String label, {IconData? icon}) => InputDecoration(
    labelText: label,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    prefixIcon: icon != null ? Icon(icon, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.deepPurple) : null,
    filled: true,
    fillColor: Colors.grey.shade50,
  );

  Widget _responsiveRow(List<Widget> children, {double spacing = 12}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isVerySmall = constraints.maxWidth < 600;
        if (isVerySmall) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children.expand((child) => [child, SizedBox(height: spacing)]).toList()..removeLast(),
          );
        } else {
          return Row(
            children: children.expand((child) => [Expanded(child: child), SizedBox(width: spacing)]).toList()..removeLast(),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SellerVerification?>(
      future: SellerVerificationService().getCurrentUserVerification(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final verification = snapshot.data;

        // Se não está aprovado, mostra tela de verificação necessária
        if (verification?.status != VerificationStatus.approved) {
          return _buildVerificationRequiredView(verification);
        }

        // Se aprovado, mostra o formulário normal
        return _buildPublishForm();
      },
    );
  }

  Widget _buildVerificationRequiredView(SellerVerification? verification) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Publicar Anúncio'),
        backgroundColor: const Color(0xFF4C1D95),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.store,
                size: 64,
                color: Color(0xFF4C1D95),
              ),
              const SizedBox(height: 24),
              const Text(
                'Verificação Necessária',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4C1D95),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Para publicar anúncios, você precisa verificar sua loja.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 32),

              if (verification?.status == VerificationStatus.pending) ...[
                const Icon(
                  Icons.pending,
                  size: 48,
                  color: Colors.orange,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Sua solicitação está sendo analisada.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.orange),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Em até 48 horas você poderá publicar anúncios.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ] else if (verification?.status == VerificationStatus.rejected) ...[
                const Icon(
                  Icons.cancel,
                  size: 48,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Sua solicitação foi rejeitada.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.red),
                ),
                const SizedBox(height: 8),
                Text(
                  'Motivo: ${verification?.rejectionReason ?? "Não informado"}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
              ] else ...[
                const Text(
                  'Complete o processo de verificação para começar a vender.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ],

              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/seller-verification');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4C1D95),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                child: Text(
                  verification?.status == VerificationStatus.rejected
                      ? 'Tentar Novamente'
                      : 'Fazer Verificação',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPublishForm() {
    final loc = LocationService.I;
    // Trigger fetch if not already attempted
    if (loc.cidade == null && !loc.loading) {
      // chama async após build
      Future.microtask(()=> loc.fetch());
    }
    // Se localização disponível, preenche campos
    if (loc.cidade != null && _cidade.text.isEmpty) {
      _cidade.text = loc.cidade!;
    }
    if (loc.uf != null && _ufSelecionado == null) {
      _ufSelecionado = loc.uf!;
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.anuncio != null ? 'Editar Anúncio' : 'Publicar Anúncio'),
        backgroundColor: Colors.deepPurple,
        elevation: 4,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepPurple, Colors.purpleAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;
          final horizontalPadding = screenWidth < 600 ? 12.0 : screenWidth < 900 ? 20.0 : 32.0;
          final verticalPadding = 20.0;

          return Form(
            key: _formKey,
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
              children: [
            _sectionCard('Dados Básicos', [
              TextFormField(controller: _titulo, decoration: _dec('Título', icon: Icons.title), validator: (v)=> v==null||v.isEmpty? 'Obrigatório':null),
              const SizedBox(height:12),
              TextFormField(controller: _descricao, decoration: _dec('Descrição', icon: Icons.description), maxLines: 3, validator: (v)=> v==null||v.isEmpty? 'Obrigatório':null),
              const SizedBox(height:12),
              TextFormField(
                controller: _preco,
                decoration: _dec('Preço', icon: Icons.attach_money).copyWith(prefixText: 'R\$ '),
                keyboardType: TextInputType.number,
                inputFormatters:[_priceFormatter],
                validator:(v){
                  if(v!=null && v.isNotEmpty){
                    final numeric = v.replaceAll(RegExp(r'[^0-9]'), '');
                    if(numeric.isEmpty) return 'Preço inválido';
                  }
                  return null;
                },
              ),
              const SizedBox(height:12),
              _responsiveRow([
                DropdownButtonFormField<String>(
                  value: _marcaSelecionada,
                  decoration: _dec('Marca', icon: Icons.business),
                  items: _marcasBrasil.map((m)=> DropdownMenuItem(value:m, child: Text(m))).toList(),
                  onChanged: (val){ setState(()=> _marcaSelecionada = val); },
                  validator: (v){
                    if((_modelo.text.isNotEmpty || (_versaoSelecionada!=null && _versaoSelecionada!.isNotEmpty) || _versao.text.isNotEmpty) && (v==null || v.isEmpty)) return 'Marca obrigatória';
                    return null;
                  },
                ),
                TextFormField(controller: _modelo, decoration: _dec('Modelo', icon: Icons.directions_car), validator:(v){ if(((_marcaSelecionada!=null && _marcaSelecionada!.isNotEmpty) || _versao.text.isNotEmpty || (_versaoSelecionada!=null && _versaoSelecionada!.isNotEmpty)) && (v==null||v.isEmpty)) return 'Modelo obrigatório'; return null;}),
              ]),
              const SizedBox(height:12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    value: _versaoSelecionada,
                    decoration: _dec('Versão / Motorização', icon: Icons.settings),
                    items: _versoesPadrao.map((v)=>DropdownMenuItem(value:v, child: Text(v))).toList(),
                    onChanged: (val){ setState(()=> _versaoSelecionada = val); },
                    validator: (v){
                      if(v==null || v.isEmpty) return 'Selecione';
                      if(v=='Outro' && _versao.text.trim().isEmpty) return 'Informe a versão';
                      return null;
                    },
                  ),
                  if(_versaoSelecionada=='Outro') ...[
                    const SizedBox(height:8),
                    TextFormField(
                      controller: _versao,
                      decoration: _dec('Versão personalizada', icon: Icons.edit),
                      validator: (v){ if(_versaoSelecionada=='Outro' && (v==null||v.trim().isEmpty)) return 'Obrigatório'; return null; },
                    ),
                  ]
                ],
              ),
              const SizedBox(height:12),
              _responsiveRow([
                TextFormField(controller: _anoFab, decoration: _dec('Ano Fab.', icon: Icons.calendar_today), keyboardType: TextInputType.number, validator:(v){ if(v!=null && v.isNotEmpty){ final n=int.tryParse(v); if(n==null|| n<1980 || n> DateTime.now().year+1) return 'Ano inválido'; } return null;}),
                TextFormField(controller: _km, decoration: _dec('KM', icon: Icons.speed), keyboardType: TextInputType.number, inputFormatters: [_priceFormatter], validator:(v){ if(v!=null && v.isNotEmpty){ final n=_int(v); if(n==null|| n<0) return 'KM inválido'; } return null;}),
              ]),
            ]),

            _sectionCard('Localização', [
              _responsiveRow([
                TextFormField(
                  controller: _cidade,
                  decoration: _dec('Cidade', icon: Icons.location_city),
                  validator: (v){
                    if(v==null || v.trim().isEmpty) return 'Informe a cidade';
                    return null;
                  },
                  // Mantemos sempre editável para evitar travar se plugin falhar
                  enabled: true,
                ),
                DropdownButtonFormField<String>(
                  value: _ufSelecionado,
                  decoration: _dec('UF', icon: Icons.map),
                  items: _ufs.map((u)=>DropdownMenuItem(value:u, child: Text(u))).toList(),
                  onChanged: (val)=> setState(()=> _ufSelecionado = val),
                  validator: (v){ if(v==null || v.isEmpty) return 'UF'; return null; },
                  disabledHint: _ufSelecionado==null? null : Text(_ufSelecionado!),
                  isDense: true,
                ),
              ]),
              const SizedBox(height:8),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: loc.loading ? null : () async {
                    // Se permissão negada para sempre abre settings
                    if (LocationService.I.deniedForever) {
                      await LocationService.I.openAppSettings();
                      return;
                    }
                    // Solicita permissão explícita
                    final ok = await LocationService.I.requestPermissionWithRationale();
                    if(!ok){
                      if(mounted && LocationService.I.erro != null){
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(LocationService.I.erro!))
                        );
                      }
                      return;
                    }
                    await LocationService.I.fetch(force: true);
                    if(mounted){
                      if(LocationService.I.cidade != null){
                        setState(() {
                          if(_cidade.text.isEmpty) _cidade.text = LocationService.I.cidade!;
                          if(_ufSelecionado == null) _ufSelecionado = LocationService.I.uf;
                        });
                      }
                    }
                  },
                  icon: Icon(
                    LocationService.I.deniedForever
                      ? Icons.lock
                      : (loc.cidade==null ? Icons.my_location : Icons.refresh),
                    size:18),
                  label: Text(
                    LocationService.I.deniedForever
                      ? 'Permitir nas configurações'
                      : (loc.cidade==null 
                          ? (LocationService.I.lastPermission == null
                              ? 'Permitir localização (durante uso)'
                              : 'Usar minha localização')
                          : 'Atualizar localização')
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Theme.of(context).brightness == Brightness.dark 
                      ? Colors.white 
                      : Colors.deepPurple),
                    foregroundColor: Theme.of(context).brightness == Brightness.dark 
                      ? Colors.white 
                      : Colors.deepPurple,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              if(LocationService.I.lastPermission == null && !LocationService.I.deniedForever && loc.cidade == null)
                const Padding(
                  padding: EdgeInsets.only(top:4.0),
                  child: Text('Precisamos só da localização enquanto você usa esta tela para sugerir cidade automaticamente.', style: TextStyle(fontSize:11,color: Colors.black54)),
                ),
              if(loc.cidade != null) Padding(
                padding: const EdgeInsets.only(top:6.0),
                child: Row(
                  children: [
                    Icon(Icons.location_on, size:14, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.deepPurple),
                    const SizedBox(width:4),
                    Flexible(child: Text('Local detectado: '+loc.cidade! + (loc.uf!=null? ' - '+loc.uf! : ''), style: const TextStyle(fontSize:12,color: Colors.deepPurple)))
                  ],
                ),
              ),
              // Removido debug de localização para experiência mais limpa
              const SizedBox(height:12),
              if (loc.loading) const Padding(
                padding: EdgeInsets.only(top:8.0),
                child: Row(children:[SizedBox(width:16,height:16,child:CircularProgressIndicator(strokeWidth:2)), SizedBox(width:8), Text('Detectando localização...')]),
              ),
              if (loc.erro != null) Padding(
                padding: const EdgeInsets.only(top:8.0),
                child: Text(loc.erro!, style: const TextStyle(color: Colors.red, fontSize: 12)),
              ),
              const SizedBox(height:12),
              TextFormField(
                controller: _whatsapp,
                decoration: _dec('WhatsApp (opcional)', icon: Icons.phone),
                keyboardType: TextInputType.phone,
                validator: (v){
                  if(v != null && v.isNotEmpty){
                    // Remove caracteres não numéricos para validação
                    final clean = v.replaceAll(RegExp(r'[^0-9]'), '');
                    if(clean.length < 10 || clean.length > 11) return 'WhatsApp inválido (10-11 dígitos)';
                  }
                  return null;
                },
              ),
            ]),

            _sectionCard('Comerciais', [
              Row(children:[
                Expanded(child: DropdownButtonFormField<String>(value:_condicao, decoration: _dec('Condição', icon: Icons.new_releases), items: const ['Novo','Seminovo','Usado'].map((e)=>DropdownMenuItem(value:e,child: Text(e))).toList(), onChanged:(v)=>setState(()=>_condicao=v))),
              ]),
              const SizedBox(height:12),
              Text('Formas de Pagamento', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height:8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _pagamentoOpcoes.map((opt){
                  final sel = _pagamentosSelecionados.contains(opt);
                  return FilterChip(
                    label: Text(opt, style: TextStyle(fontSize: 12, fontWeight: sel? FontWeight.bold: FontWeight.normal)),
                    selected: sel,
                    onSelected: (v){
                      setState(() {
                        if (v) { _pagamentosSelecionados.add(opt); } else { _pagamentosSelecionados.remove(opt); }
                      });
                    },
                    selectedColor: Colors.deepPurple.shade300,
                    showCheckmark: false,
                  );
                }).toList(),
              ),
              if(_pagamentosSelecionados.isNotEmpty) Padding(
                padding: const EdgeInsets.only(top:6.0),
                child: Text('Selecionados: '+_pagamentosSelecionados.join(', '), style: const TextStyle(fontSize:12,color: Colors.black54)),
              ),
              const SizedBox(height:12),
              TextFormField(controller: _garantia, decoration: _dec('Garantia', icon: Icons.shield)),
            ]),

            _sectionCard('Especificações', [
              _responsiveRow([
                DropdownButtonFormField<String>(value:_combustivel, decoration: _dec('Combustível', icon: Icons.local_gas_station), items: const ['Gasolina','Álcool','Flex','Diesel','Elétrico','Híbrido'].map((e)=>DropdownMenuItem(value:e,child: Text(e))).toList(), onChanged:(v)=>setState(()=>_combustivel=v)),
                DropdownButtonFormField<String>(value:_cambio, decoration: _dec('Câmbio', icon: Icons.settings_applications), items: const ['Manual','Automático','CVT','Automatizado'].map((e)=>DropdownMenuItem(value:e,child: Text(e))).toList(), onChanged:(v)=>setState(()=>_cambio=v)),
              ]),
              const SizedBox(height:12),
              _responsiveRow([
                DropdownButtonFormField<String>(value:_numPortas, decoration: _dec('Portas', icon: Icons.door_front_door), items: const ['2','4','5'].map((e)=>DropdownMenuItem(value:e,child: Text(e))).toList(), onChanged:(v)=>setState(()=>_numPortas=v)),
                DropdownButtonFormField<String>(value:_direcao, decoration: _dec('Direção', icon: Icons.drive_eta), items: const ['Elétrica','Hidráulica','Mecânica'].map((e)=>DropdownMenuItem(value:e,child: Text(e))).toList(), onChanged:(v)=>setState(()=>_direcao=v)),
              ]),
              const SizedBox(height:12),
              _responsiveRow([
                DropdownButtonFormField<String>(
                  value: _carroceria,
                  decoration: _dec('Carroceria', icon: Icons.directions_car_filled),
                  items: _carrocerias
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setState(() => _carroceria = v),
                ),
                TextFormField(
                  controller: _cor,
                  decoration: _dec('Cor', icon: Icons.color_lens),
                ),
              ]),
            ]),

            _sectionCard('Conforto / Itens', [
              SwitchListTile(title: const Text('Ar-condicionado'), value: _arCondicionado, onChanged:(v)=>setState(()=>_arCondicionado=v)),
              SwitchListTile(title: const Text('Vidros dianteiros elétricos'), value: _vidrosDianteiros, onChanged:(v)=>setState(()=>_vidrosDianteiros=v)),
              SwitchListTile(title: const Text('Vidros traseiros elétricos'), value: _vidrosTraseiros, onChanged:(v)=>setState(()=>_vidrosTraseiros=v)),
              SwitchListTile(title: const Text('Travas elétricas'), value: _travasEletricas, onChanged:(v)=>setState(()=>_travasEletricas=v)),
              SwitchListTile(title: const Text('Bancos em couro'), value: _bancosCouro, onChanged:(v)=>setState(()=>_bancosCouro=v)),
              SwitchListTile(title: const Text('Multimídia / Som'), value: _multimidiaPresente, onChanged:(v)=>setState(()=>_multimidiaPresente=v)),
            SwitchListTile(title: const Text('Rodas de liga leve'), value: _rodasLigaLeve, onChanged:(v)=>setState(()=>_rodasLigaLeve=v)),
            const SizedBox(height:8),
            TextFormField(controller: _airbags, decoration: _dec('Qtd Airbags (número)'), keyboardType: TextInputType.number),
            SwitchListTile(title: const Text('Freios ABS'), value: _abs, onChanged:(v)=>setState(()=>_abs=v)),
            SwitchListTile(title: const Text('Controle estabilidade'), value: _controleEstabilidade, onChanged:(v)=>setState(()=>_controleEstabilidade=v)),
            SwitchListTile(title: const Text('Sensor estacionamento / Câmera'), value: _sensorEstacionamento, onChanged:(v)=>setState(()=>_sensorEstacionamento=v)),
            DropdownButtonFormField<String>(value:_farois, decoration: _dec('Faróis', icon: Icons.lightbulb), items: const ['Halógeno','LED','Xenon'].map((e)=>DropdownMenuItem(value:e,child: Text(e))).toList(), onChanged:(v)=>setState(()=>_farois=v)),
            ]),

            _sectionCard('Documentação', [
              DropdownButtonFormField<String>(value:_situacaoVeiculo, decoration: _dec('Situação', icon: Icons.description), items: const ['Em dia','Financiado','Leilão','Sinistro'].map((e)=>DropdownMenuItem(value:e,child: Text(e))).toList(), onChanged:(v)=>setState(()=>_situacaoVeiculo=v)),
              SwitchListTile(title: const Text('Possui manual + chave reserva'), value: _manualChave, onChanged:(v)=>setState(()=>_manualChave=v)),
              SwitchListTile(title: const Text('IPVA pago'), value: _ipvaPago, onChanged:(v)=>setState(()=>_ipvaPago=v)),
            ]),

            _sectionTitle('Fotos (${_fotos.length}/10)'),
            LayoutBuilder(
              builder: (context, constraints) {
                final isVerySmall = constraints.maxWidth < 600;
                if (isVerySmall) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _fotos.length>=10?null:_addFotos,
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Galeria'),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () async {
                          try {
                            final img = await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
                            if (img!=null && _fotos.length<10) setState(()=>_fotos.add(File(img.path)));
                          } catch(e){
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Câmera: $e')));
                          }
                        },
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Câmera'),
                      ),
                    ],
                  );
                } else {
                  return Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _fotos.length>=10?null:_addFotos,
                          icon: const Icon(Icons.photo_library),
                          label: const Text('Galeria'),
                        ),
                      ),
                      const SizedBox(width:12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            try {
                              final img = await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
                              if (img!=null && _fotos.length<10) setState(()=>_fotos.add(File(img.path)));
                            } catch(e){
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Câmera: $e')));
                            }
                          },
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Câmera'),
                        ),
                      ),
                    ],
                  );
                }
              },
            ),
            const SizedBox(height:10),
            if (_fotos.isNotEmpty) LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                int crossAxisCount;
                if (width < 400) {
                  crossAxisCount = 2;
                } else if (width < 600) {
                  crossAxisCount = 3;
                } else {
                  crossAxisCount = 4;
                }
                final itemHeight = width / crossAxisCount - 8;
                final rows = (_fotos.length / crossAxisCount).ceil();
                final totalHeight = rows * (itemHeight + 8) + 16;

                return SizedBox(
                  height: totalHeight.clamp(120, 400),
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 1,
                    ),
                    itemCount: _fotos.length,
                    itemBuilder: (context, i) => Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            _fotos[i],
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => setState(() => _fotos.removeAt(i)),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              padding: const EdgeInsets.all(6),
                              child: const Icon(
                                Icons.close,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ) else Container(
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.photo_library, size: 48, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.grey),
                    SizedBox(height: 8),
                    Text(
                      'Nenhuma foto selecionada',
                      style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height:28),
            Container(
              height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.green, Colors.lightGreen],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.shade300.withOpacity(0.5),
                    spreadRadius: 2,
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: _publicando ? null : _publicar,
                icon: _publicando
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.cloud_upload),
                label: Text(_publicando ? (widget.anuncio != null ? 'Atualizando...' : 'Publicando...') : (widget.anuncio != null ? 'Atualizar Anúncio' : 'Publicar Anúncio')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  minimumSize: const Size(double.infinity, 52),
                ),
              ),
            ),
            const SizedBox(height:32)
          ],
        ),
      );
    },
  ),
    );
  }
}

class _PriceFormatter extends TextInputFormatter {
  String _format(String digits){
    if(digits.isEmpty) return '';
    digits = digits.replaceFirst(RegExp(r'^0+(?=\d)'), '');
    final buf = StringBuffer();
    int count = 0;
    for(int i = digits.length - 1; i >=0; i--){
      buf.write(digits[i]);
      count++;
      if(count==3 && i!=0){
        buf.write('.');
        count=0;
      }
    }
    return buf.toString().split('').reversed.join();
  }

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final formatted = _format(digits);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length)
    );
  }
}
