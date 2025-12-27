

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'comprador_home.dart';
import 'publicar_anuncio_page.dart';
import 'meus_anuncios_page.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import 'services/seller_verification_service.dart';
import 'favorites_service.dart';
import 'services/admin_service.dart';
import 'services/update_service.dart';
import 'admin_verification_panel.dart';
import 'models/seller_verification.dart';
import 'services/analytics_service.dart';
import 'services/profile_service.dart';
import 'lojista_anuncios_page.dart';

/// Tela de Perfil com Drawer lateral esquerdo
class PerfilPage extends StatefulWidget {
  const PerfilPage({super.key});

  @override
  State<PerfilPage> createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
  String? _userId;
  late Future<Map<String, int>> _statsFuture;
  RealtimeChannel? _followersChannel;

  @override
  void initState() {
    super.initState();
    final user = Supabase.instance.client.auth.currentUser;
    _userId = user?.id;

    if (user != null) {
      ProfileService().syncProfileFromAuth();
      _statsFuture = _loadUserStats(user.id);
      _followersChannel = Supabase.instance.client
          .channel('seller-followers-${user.id}')
        ..onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'vendedores_seguidos',
          callback: (payload) {
            final newVendedor = payload.newRecord.isNotEmpty ? payload.newRecord['vendedor_id'] : null;
            final oldVendedor = payload.oldRecord.isNotEmpty ? payload.oldRecord['vendedor_id'] : null;
            debugPrint('[PerfilPage] Evento realtime recebido: new=$newVendedor old=$oldVendedor para vendedor=${user.id}');
            if (newVendedor == user.id || oldVendedor == user.id) {
              _refreshStats();
            }
          },
        )
        ..subscribe();
    } else {
      _statsFuture = Future.value(const {
        'anuncios': 0,
        'visualizacoes': 0,
        'seguidores': 0,
      });
    }
  }

  void _refreshStats() {
    if (!mounted || _userId == null) return;
    debugPrint('[PerfilPage] Atualizando estatísticas para usuário $_userId');
    setState(() {
      _statsFuture = _loadUserStats(_userId!);
    });
  }

  @override
  void dispose() {
    _followersChannel?.unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final nome = user?.userMetadata?['name'] ?? user?.email?.split('@').first ?? 'Usuário';
    final email = user?.email ?? '';
    final fotoUrl = user?.userMetadata?['avatar_url'] ?? '';
    final isSmall = MediaQuery.of(context).size.width < 400;
    final userId = _userId;

    final quickActionCards = <Widget>[
      _PerfilQuickActionCard(
        icon: Icons.directions_car,
        label: 'Meus Anúncios',
        color: Colors.deepPurple,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const MeusAnunciosPage()),
        ),
      ),
      _PerfilQuickActionCard(
        icon: Icons.add_box,
        label: 'Publicar',
        color: Colors.green,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const PublicarAnuncioPage()),
          );
        },
      ),
      _PerfilQuickActionCard(
        icon: Icons.bar_chart,
        label: 'Visualizações',
        color: Colors.orange,
        onTap: () => Navigator.of(context).pushNamed('/visualizacoes'),
      ),
      _PerfilQuickActionCard(
        icon: Icons.business,
        label: 'Sobre o Dominus',
        color: Colors.blue,
        onTap: () => Navigator.of(context).pushNamed('/sobre-dominus'),
      ),
    ];

    if (userId != null) {
      quickActionCards.add(
        _PerfilQuickActionCard(
          icon: Icons.qr_code_2,
          label: 'Link da Loja',
          color: Colors.indigo,
          onTap: () => _showSellerShareSheet(
            context,
            userId: userId,
            nome: nome,
            fotoUrl: fotoUrl,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Perfil'),
        backgroundColor: Colors.deepPurple,
        elevation: 2,
      ),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Informações do usuário no topo do Drawer
              Container(
                color: Colors.deepPurple[50],
                padding: EdgeInsets.symmetric(vertical: isSmall ? 24 : 36, horizontal: 16),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: isSmall ? 38 : 48,
                      backgroundImage: fotoUrl.isNotEmpty ? NetworkImage(fotoUrl) : null,
                      backgroundColor: Colors.deepPurple[200],
                      child: fotoUrl.isEmpty ? const Icon(Icons.person, size: 44, color: Colors.white70) : null,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      nome,
                      style: TextStyle(
                        fontSize: isSmall ? 18 : 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple[900],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: TextStyle(
                        fontSize: isSmall ? 13 : 15,
                        color: Colors.grey[700],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              // Botão de Assinatura
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pushNamed('/assinatura');
                  },
                  icon: const Icon(Icons.star, color: Colors.amber),
                  label: const Text('Assinatura'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 3,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Opções do menu
              FutureBuilder<SellerVerification?>(
                future: SellerVerificationService().getCurrentUserVerification(),
                builder: (context, snapshot) {
                  final verification = snapshot.data;
                  final isApproved = verification?.status == VerificationStatus.approved;
                  final isPending = verification?.status == VerificationStatus.pending;
                  final isRejected = verification?.status == VerificationStatus.rejected;

                  return ListTile(
                    leading: Icon(
                      isApproved ? Icons.verified : isPending ? Icons.pending : Icons.store,
                      color: isApproved ? Colors.green : isPending ? Colors.orange : Colors.deepPurple,
                    ),
                    title: Text(
                      isApproved ? 'Loja Verificada' : 'Verificar Loja',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: isPending
                      ? const Text('Análise em andamento', style: TextStyle(color: Colors.orange, fontSize: 12))
                      : isRejected
                      ? const Text('Verificação rejeitada', style: TextStyle(color: Colors.red, fontSize: 12))
                      : isApproved
                      ? const Text('Verificado ✓', style: TextStyle(color: Colors.green, fontSize: 12))
                      : const Text('Necessário para vender', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pushNamed('/seller-verification');
                    },
                  );
                },
              ),
              // Opção do Painel Administrativo (apenas para admin)
              FutureBuilder<bool>(
                future: AdminService.isCurrentUserAdmin(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox.shrink();
                  }
                  final isAdmin = snapshot.data ?? false;
                  if (!isAdmin) return const SizedBox.shrink();

                  return ListTile(
                    leading: const Icon(Icons.admin_panel_settings, color: Colors.red),
                    title: const Text('Painel Admin', style: TextStyle(fontWeight: FontWeight.w500)),
                    subtitle: const Text('Gerenciar verificações', style: TextStyle(color: Colors.red, fontSize: 12)),
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const AdminVerificationPanel(),
                        ),
                      );
                    },
                  );
                },
              ),
              Consumer<ThemeProvider>(
                builder: (context, themeProvider, child) {
                  return ListTile(
                    leading: Icon(
                      themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                      color: Colors.deepPurple,
                    ),
                    title: const Text('Modo Escuro', style: TextStyle(fontWeight: FontWeight.w500)),
                    trailing: Switch(
                      value: themeProvider.isDarkMode,
                      onChanged: (value) {
                        themeProvider.setDarkMode(value);
                      },
                      activeColor: Colors.deepPurple,
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.system_update, color: Colors.blue),
                title: const Text('Verificar Atualizações', style: TextStyle(fontWeight: FontWeight.w500)),
                subtitle: const Text('Buscar nova versão do app', style: TextStyle(color: Colors.grey, fontSize: 12)),
                onTap: () => _checkForUpdates(context),
              ),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Sair', style: TextStyle(fontWeight: FontWeight.w500, color: Colors.red)),
                onTap: () async {
                  Navigator.of(context).pop();
                  FavoritesService().reset(); // Limpar favoritos ao deslogar
                  await Supabase.instance.client.auth.signOut();
                  if (context.mounted) {
                    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                  }
                },
              ),
              const Divider(),
              const Spacer(),
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text('Apagar Conta', style: TextStyle(fontWeight: FontWeight.w500, color: Colors.red)),
                subtitle: const Text('Remove todos os seus dados permanentemente', style: TextStyle(color: Colors.red, fontSize: 12)),
                onTap: () => _showDeleteAccountDialog(context),
              ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  'Dominus',
                  style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
  body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: isSmall ? 18 : 32, vertical: isSmall ? 24 : 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 10,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: isSmall ? 46 : 56, horizontal: isSmall ? 16 : 22),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: LinearGradient(
                    colors: Theme.of(context).brightness == Brightness.dark
                        ? [Colors.deepPurple.shade900, Colors.deepPurple.shade600]
                        : [Colors.deepPurple.shade700, Colors.deepPurple.shade500],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: isSmall ? 40 : 48,
                          backgroundImage: fotoUrl.isNotEmpty ? NetworkImage(fotoUrl) : null,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          child: fotoUrl.isEmpty ? const Icon(Icons.person, size: 36, color: Colors.white70) : null,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Text(
                                nome,
                                style: TextStyle(
                                  fontSize: isSmall ? 20 : 22,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                email.isNotEmpty ? email : 'Conta sem e-mail',
                                style: TextStyle(
                                  fontSize: isSmall ? 14 : 15,
                                  color: Colors.white.withValues(alpha: 0.85),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (userId != null)
                      FutureBuilder<Map<String, int>>(
                        future: _statsFuture,
                        builder: (context, snapshot) {
                          final stats = snapshot.data ?? const {'anuncios': 0, 'visualizacoes': 0, 'seguidores': 0};
                          final loading = snapshot.connectionState == ConnectionState.waiting;

                          Widget buildStat(String label, int value) {
                            final textColor = Colors.white;
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  loading ? '—' : value.toString(),
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: isSmall ? 16 : 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  label,
                                  style: TextStyle(
                                    color: textColor.withValues(alpha: 0.8),
                                    fontSize: isSmall ? 12 : 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            );
                          }

                          return Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: isSmall ? 72 : 88,
                                  child: buildStat('Anúncios', stats['anuncios'] ?? 0),
                                ),
                                const SizedBox(width: 14),
                                buildStat('Visualizações', stats['visualizacoes'] ?? 0),
                                const SizedBox(width: 14),
                                buildStat('Seguidores', stats['seguidores'] ?? 0),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Cards de ações rápidas em grid 2x2 (quadrados)
            GridView.count(
              crossAxisCount: 2,
              // Maior razão reduz a altura e deixa os cards mais compactos
              childAspectRatio: 1.25,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: quickActionCards,
            ),
          ],
        ),
  ),
  // BottomNavigationBar fixo para navegação
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 3,
        onTap: (index) {
          if (index == 0) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const CompradorHome()),
              (route) => false,
            );
          } else if (index == 1) {
            Navigator.of(context).pushNamed('/favoritos');
          } else if (index == 2) {
            Navigator.of(context).pushNamed('/lojistas');
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

  void _showSellerShareSheet(
    BuildContext context, {
    required String userId,
    required String nome,
    required String fotoUrl,
  }) {
    final storeLink = _buildSellerShareLink(userId);
    final shareMessage = 'Confira meus anúncios no Dominus: $storeLink';

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        final bottomPadding = MediaQuery.of(sheetContext).viewPadding.bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + bottomPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.qr_code_2, size: 36, color: Colors.deepPurple),
              const SizedBox(height: 8),
              Text(
                'Compartilhe seus anúncios',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Text(
                'Envie o link ou o QR Code para que os clientes pulsem direto na sua vitrine do Dominus.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: QrImageView(
                  data: storeLink,
                  size: 200,
                  backgroundColor: Colors.white,
                  version: QrVersions.auto,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: theme.brightness == Brightness.dark ? 0.4 : 0.6),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: SelectableText(
                  storeLink,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.share),
                    label: const Text('Compartilhar link'),
                    onPressed: () => Share.share(shareMessage, subject: 'Meus anúncios Dominus'),
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.copy),
                    label: const Text('Copiar link'),
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: storeLink));
                      if (sheetContext.mounted) {
                        ScaffoldMessenger.of(sheetContext).showSnackBar(
                          const SnackBar(content: Text('Link copiado para a área de transferência')),
                        );
                      }
                    },
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('Baixar QR em PDF'),
                    onPressed: () => _exportSellerQrAsPdf(
                      sheetContext,
                      storeLink: storeLink,
                      nome: nome,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                icon: const Icon(Icons.storefront),
                label: const Text('Ver meus anúncios'),
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => LojistaAnunciosPage(
                        lojista: {
                          'user_id': userId,
                          'nome_loja': nome,
                          'avatar_url': fotoUrl,
                          'cidade': '',
                          'estado': '',
                          'total_anuncios': 0,
                        },
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  String _buildSellerShareLink(String userId) => 'https://domin.us/seller_redirect.html?seller=$userId';

  Future<void> _exportSellerQrAsPdf(
    BuildContext context, {
    required String storeLink,
    required String nome,
  }) async {
    try {
      final validation = QrValidator.validate(
        data: storeLink,
        version: QrVersions.auto,
        errorCorrectionLevel: QrErrorCorrectLevel.M,
      );

      if (validation.status != QrValidationStatus.valid || validation.qrCode == null) {
        throw Exception('Não foi possível validar o QR Code.');
      }

      final painter = QrPainter.withQr(
        qr: validation.qrCode!,
        gapless: true,
      );

      final imageData = await painter.toImageData(600, format: ui.ImageByteFormat.png);
      if (imageData == null) {
        throw Exception('Falha ao renderizar o QR Code.');
      }

      final qrBytes = imageData.buffer.asUint8List();
      final pw.Document doc = pw.Document();
      final qrImage = pw.MemoryImage(qrBytes);

      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(48),
          build: (pw.Context pdfContext) {
            return pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  'Dominus',
                  style: pw.TextStyle(
                    fontSize: 28,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.deepPurple,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  nome,
                  style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 24),
                pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.deepPurple, width: 2),
                    borderRadius: pw.BorderRadius.circular(16),
                  ),
                  child: pw.Image(qrImage, width: 220, height: 220),
                ),
                pw.SizedBox(height: 24),
                pw.Text(
                  'Aponte a câmera para acessar os anúncios:',
                  style: pw.TextStyle(fontSize: 14),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 8),
                pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey200,
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Text(
                    storeLink,
                    style: pw.TextStyle(fontSize: 12),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
              ],
            );
          },
        ),
      );

      final pdfBytes = await doc.save();
      final directory = await getTemporaryDirectory();
      final filename = 'dominustore_qr_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${directory.path}/$filename');
      await file.writeAsBytes(pdfBytes, flush: true);

      final openResult = await OpenFile.open(file.path);
      if (context.mounted) {
        final message = openResult.type == ResultType.done
            ? 'PDF salvo em ${file.path}'
            : 'PDF salvo em ${file.path}. Não foi possível abrir automaticamente.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao gerar PDF: $e')),
        );
      }
    }
  }

  Future<void> _checkForUpdates(BuildContext context) async {
    
    // Mostrar loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Verificando atualizações...'),
          ],
        ),
      ),
    );

    try {
      final updateInfo = await UpdateService.checkForUpdate();
      
      // Fechar loading
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      if (updateInfo != null) {
        final currentVersion = await UpdateService.getCurrentVersion();
        final comparison = UpdateService.compareVersions(currentVersion, updateInfo['version']);

        if (comparison < 0) {
          if (context.mounted) {
            _showUpdateDialog(context, updateInfo);
          }
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Você já está na versão mais recente!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erro ao verificar atualizações. Tente novamente.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // Fechar loading se ainda estiver aberto
      if (context.mounted) {
        Navigator.of(context).pop();
      }
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showUpdateDialog(BuildContext context, Map<String, dynamic> updateInfo) {
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

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Apagar Conta', style: TextStyle(color: Colors.red)),
          content: const Text(
            'Esta ação é irreversível. Todos os seus dados, anúncios, favoritos e histórico serão permanentemente removidos do sistema.\n\nTem certeza de que deseja continuar?',
            style: TextStyle(height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await _deleteAccount(context);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Apagar Conta'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteAccount(BuildContext context) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      // Mostrar loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Removendo conta...'),
            ],
          ),
        ),
      );

      // 1. Deletar anúncios do usuário
      await Supabase.instance.client
          .from('veiculos')
          .delete()
          .eq('user_id', user.id);

      // 2. Deletar favoritos do usuário
      await Supabase.instance.client
          .from('favoritos')
          .delete()
          .eq('user_id', user.id);

      // 3. Deletar verificações de vendedor
      await Supabase.instance.client
          .from('seller_verifications')
          .delete()
          .eq('user_id', user.id);

      // 4. Deletar visualizações
      await Supabase.instance.client
          .from('visualizacoes')
          .delete()
          .eq('user_id', user.id);

      // 5. Deletar contatos
      await Supabase.instance.client
          .from('contatos')
          .delete()
          .eq('user_id', user.id);

      // Nota: A conta de autenticação não será deletada por segurança
      // Apenas os dados são removidos e o usuário é deslogado

      // Fechar loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Logout e voltar para login
      if (context.mounted) {
        FavoritesService().reset();
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      }

    } catch (error) {
      // Fechar loading dialog se ainda estiver aberto
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Mostrar erro
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao apagar conta: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

Future<Map<String, int>> _loadUserStats(String userId) async {
  final client = Supabase.instance.client;

  try {
    debugPrint('[PerfilPage] _loadUserStats iniciada para $userId');
    // Mesmo cálculo da tela de Visualizações (AnalyticsService) para total de visualizações
    final summary = await AnalyticsService.I.fetchSummary(days: 90);
    debugPrint('[PerfilPage] Total de visualizações últimos 90 dias: ${summary.totalViews}');

    // Mesma contagem usada em MeusAnunciosPage: lista anúncios do usuário
    final anunciosResponse = await client
        .from('veiculos')
        .select()
      .eq('user_id', userId);

    int anunciosCount = 0;
    try {
      anunciosCount = (anunciosResponse as List).length;
    } catch (_) {
      anunciosCount = 0;
    }
    debugPrint('[PerfilPage] Total de anúncios carregados: $anunciosCount');

    final seguidoresResponse = await client
        .from('vendedores_seguidos')
        .select('id')
        .eq('vendedor_id', userId);

    final seguidoresCount = (seguidoresResponse as List).length;
    debugPrint('[PerfilPage] Total de seguidores retornado pelo banco: $seguidoresCount');

    return {
      'anuncios': anunciosCount,
      'visualizacoes': summary.totalViews,
      'seguidores': seguidoresCount,
    };
  } catch (error, stack) {
    debugPrint('[PerfilPage] Erro ao carregar estatísticas: $error');
    debugPrint('[PerfilPage] Stack: $stack');
    return const {'anuncios': 0, 'visualizacoes': 0, 'seguidores': 0};
  }
}

/// Card de ação rápida para o perfil
class _PerfilQuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _PerfilQuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.of(context).size.width < 400;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Card(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: isSmall ? 12 : 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: isSmall ? 24 : 28),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: isSmall ? 13 : 14,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
