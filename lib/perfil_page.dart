

import 'package:flutter/material.dart';
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

/// Tela de Perfil com Drawer lateral esquerdo
class PerfilPage extends StatelessWidget {
  const PerfilPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final nome = user?.userMetadata?['name'] ?? user?.email?.split('@').first ?? 'Usuário';
    final email = user?.email ?? '';
    final fotoUrl = user?.userMetadata?['avatar_url'] ?? '';
    final isSmall = MediaQuery.of(context).size.width < 400;
    final userId = user?.id;

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
                      child: fotoUrl.isEmpty ? const Icon(Icons.person, size: 44, color: Colors.white70) : null,
                      backgroundColor: Colors.deepPurple[200],
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
                          child: fotoUrl.isEmpty ? const Icon(Icons.person, size: 36, color: Colors.white70) : null,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
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
                        future: _loadUserStats(userId),
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
              children: [
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
              ],
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

  Future<void> _checkForUpdates(BuildContext context) async {
    print('🔍 Verificando atualizações manualmente...');
    
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
          _showUpdateDialog(context, updateInfo);
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
      builder: (context) => AlertDialog(
        title: const Text('Nova versão disponível'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Versão ${updateInfo['version']} está disponível.'),
            const SizedBox(height: 8),
            if (updateInfo['changelog'] != null)
              Text(
                'Novidades:\n${updateInfo['changelog']}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Depois'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await UpdateService.downloadAndInstallUpdate(updateInfo['apkUrl']);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erro ao baixar atualização: $e'),
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
    // Mesmo cálculo da tela de Visualizações (AnalyticsService) para total de visualizações
    final summary = await AnalyticsService.I.fetchSummary(days: 90);

    // Mesma contagem usada em MeusAnunciosPage: lista anúncios do usuário
    final anunciosResponse = await client
        .from('veiculos')
        .select()
        .eq('usuario_id', userId);

    int anunciosCount = 0;
    try {
      anunciosCount = (anunciosResponse as List).length;
    } catch (_) {
      anunciosCount = 0;
    }

    final seguidoresResponse = await client
        .from('vendedores_seguidos')
        .select('id')
        .eq('vendedor_id', userId);

    return {
      'anuncios': anunciosCount,
      'visualizacoes': summary.totalViews,
      'seguidores': (seguidoresResponse as List).length,
    };
  } catch (_) {
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
    Key? key,
  }) : super(key: key);

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
