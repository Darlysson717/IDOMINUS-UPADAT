import 'package:flutter/material.dart';
import '../models/seller_verification.dart';
import '../services/seller_verification_service.dart';
import '../services/admin_service.dart';
import '../widgets/skeleton_widgets.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';

class AdminVerificationPanel extends StatefulWidget {
  const AdminVerificationPanel({super.key});

  @override
  State<AdminVerificationPanel> createState() => _AdminVerificationPanelState();
}

class _AdminVerificationPanelState extends State<AdminVerificationPanel> with SingleTickerProviderStateMixin {
  List<SellerVerification> _verifications = [];
  List<Administrator> _administrators = [];
  bool _isLoading = true;
  bool _isAdmin = false;
  bool _isSuperAdmin = false;
  String? _errorMessage;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeAdminStatus();
  }

  Future<void> _initializeAdminStatus() async {
    final isAdmin = await AdminService.isCurrentUserAdmin();
    final isSuperAdmin = await AdminService.isCurrentUserSuperAdmin();

    setState(() {
      _isAdmin = isAdmin;
      _isSuperAdmin = isSuperAdmin;
    });

    if (isAdmin) {
      _loadData();
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadVerifications(),
      _loadAdministrators(),
      _checkSuperAdminStatus(),
    ]);
  }

  Future<void> _loadVerifications() async {
    try {
      final service = SellerVerificationService();
      final verifications = await service.getAllVerifications();

      setState(() {
        _verifications = verifications;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao carregar verificações: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadAdministrators() async {
    try {
      final administrators = await AdminService.getAllAdministrators();
      setState(() {
        _administrators = administrators;
      });
    } catch (e) {
      print('Erro ao carregar administradores: $e');
    }
  }

  Future<void> _checkSuperAdminStatus() async {
    final isSuperAdmin = await AdminService.isCurrentUserSuperAdmin();
    setState(() {
      _isSuperAdmin = isSuperAdmin;
    });
  }

  Future<void> _approveVerification(String userId) async {
    try {
      final service = SellerVerificationService();
      await service.approveVerification(userId);

      // Recarregar lista
      await _loadVerifications();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vendedor aprovado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao aprovar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _openDocument(String documentUrl) async {
    print('=== DEBUG: _openDocument chamado ===');
    print('URL recebida: $documentUrl');
    print('Comprimento da URL: ${documentUrl.length}');

    try {
      // Verificar se é uma imagem em base64 (modo desenvolvimento)
      if (documentUrl.startsWith('data:image/')) {
        print('✅ Detectado como base64 com data URI');
        _showImageDialog(documentUrl);
        return;
      }

      // Tentar detectar base64 puro (sem data URI)
      if (_isBase64String(documentUrl)) {
        print('✅ Detectado como base64 puro');
        final mimeType = _guessMimeType(documentUrl);
        print('MIME type detectado: $mimeType');
        final fullBase64 = 'data:$mimeType;base64,$documentUrl';
        _showImageDialog(fullBase64);
        return;
      }

      // Verificar se é uma URL simulada (modo desenvolvimento)
      if (documentUrl.contains('supabase.storage.example.com')) {
        print('⚠️ Detectado como URL simulada, mas tentando extrair base64...');

        // Mesmo sendo URL simulada, pode conter dados base64
        // Vamos tentar extrair qualquer parte que seja base64 válida
        final parts = documentUrl.split('/');
        if (parts.length > 1) {
          final lastPart = parts.last;
          if (_isBase64String(lastPart)) {
            print('✅ Encontrado base64 na URL simulada');
            final mimeType = _guessMimeType(lastPart);
            final fullBase64 = 'data:$mimeType;base64,$lastPart';
            _showImageDialog(fullBase64);
            return;
          }
        }

        // Se não conseguiu extrair base64, mostrar mensagem
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Modo desenvolvimento: Documento simulado não disponível'),
              backgroundColor: Colors.blue,
            ),
          );
        }
        return;
      }

      print('🔗 Tentando abrir como URL externa');
      final uri = Uri.parse(documentUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        print('❌ URL não pode ser lançada');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Não foi possível abrir o documento'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Erro ao abrir documento: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao abrir documento: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  bool _isBase64String(String str) {
    try {
      base64Decode(str);
      return true;
    } catch (e) {
      return false;
    }
  }

  String _guessMimeType(String base64String) {
    // Tentar detectar o tipo baseado nos primeiros bytes
    try {
      final bytes = base64Decode(base64String.substring(0, 50));
      if (bytes.length >= 2) {
        if (bytes[0] == 0xFF && bytes[1] == 0xD8) return 'image/jpeg';
        if (bytes[0] == 0x89 && bytes[1] == 0x50) return 'image/png';
        if (bytes[0] == 0x47 && bytes[1] == 0x49) return 'image/gif';
      }
    } catch (e) {
      // Ignorar erro
    }
    return 'image/jpeg'; // Default
  }

  void _testImageDialog() {
    // Imagem base64 pequena para teste (1x1 pixel PNG transparente)
    const testBase64 = 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==';
    print('=== TESTE: Usando imagem hardcoded ===');
    _showImageDialog(testBase64);
  }

  Future<void> _requestRevalidation(String userId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Solicitar Revalidação'),
        content: const Text(
          'Isso irá revogar a aprovação atual e solicitar que o vendedor '
          'envie novos documentos para verificação. Deseja continuar?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('Solicitar Revalidação'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final service = SellerVerificationService();

      // Primeiro, marcar como rejeitado com motivo específico
      await service.rejectVerification(
        userId,
        'Revalidação solicitada pelo administrador. Por favor, envie novos documentos.'
      );

      // Recarregar lista
      await _loadVerifications();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Revalidação solicitada com sucesso'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao solicitar revalidação: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDocumentInfo(SellerVerification verification) {
    final url = verification.documentoUrl;
    final isBase64 = url.startsWith('data:image/') || _isBase64String(url);
    final isSimulated = url.contains('supabase.storage.example.com');
    final length = url.length;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Informações do Documento'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tipo: ${isBase64 ? "Base64" : isSimulated ? "Simulado" : "URL"}'),
            Text('Tamanho: $length caracteres'),
            const SizedBox(height: 8),
            const Text('URL:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(
              url.length > 100 ? '${url.substring(0, 100)}...' : url,
              style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  void _showImageDialog(String base64Image) {
    print('=== DEBUG: _showImageDialog ===');
    print('Base64 image length: ${base64Image.length}');
    print('Base64 image preview: ${base64Image.substring(0, 100)}...');

    try {
      String imageData;

      if (base64Image.startsWith('data:image/')) {
        print('✅ Processando como data URI completo');
        // Formato completo: data:image/jpeg;base64,/9j/4AAQ...
        imageData = base64Image.split(',').last;
      } else {
        print('✅ Processando como base64 puro');
        // Apenas base64 puro
        imageData = base64Image;
      }

      print('Image data length: ${imageData.length}');
      print('Tentando decodificar base64...');

      final imageBytes = base64Decode(imageData);
      print('✅ Base64 decodificado com sucesso! ${imageBytes.length} bytes');

      showDialog(
        context: context,
        builder: (context) => Dialog(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: const Text('Documento Anexado'),
                leading: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.7,
                  maxWidth: MediaQuery.of(context).size.width * 0.9,
                ),
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Image.memory(
                    imageBytes,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      print('❌ Erro no Image.memory: $error');
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error, size: 48, color: Colors.red),
                            SizedBox(height: 16),
                            Text('Erro ao carregar imagem'),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Fechar'),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      print('❌ Erro ao mostrar dialog de imagem: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar imagem: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectVerification(String userId, String reason) async {
    if (reason.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Digite o motivo da rejeição'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final service = SellerVerificationService();
      await service.rejectVerification(userId, reason);

      // Recarregar lista
      await _loadVerifications();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Solicitação rejeitada'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao rejeitar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showRejectDialog(String userId) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rejeitar Solicitação'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Digite o motivo da rejeição:'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'Ex: Documento ilegível, CNPJ inválido, etc.',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _rejectVerification(userId, reasonController.text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Rejeitar'),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationCard(SellerVerification verification) {
    final statusColor = switch (verification.status) {
      VerificationStatus.pending => Colors.orange,
      VerificationStatus.approved => Colors.green,
      VerificationStatus.rejected => Colors.red,
      _ => Colors.grey,
    };

    final statusText = switch (verification.status) {
      VerificationStatus.pending => 'Pendente',
      VerificationStatus.approved => 'Aprovado',
      VerificationStatus.rejected => 'Rejeitado',
      _ => 'Incompleto',
    };

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        verification.storeName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'CNPJ: ${verification.cnpj}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Data: ${_formatDate(verification.createdAt)}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            if (verification.documentoUrl.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.attach_file, size: 16),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Documento anexado',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                  TextButton(
                    onPressed: () => _openDocument(verification.documentoUrl),
                    child: const Text('Ver'),
                  ),
                  TextButton(
                    onPressed: () => _showDocumentInfo(verification),
                    child: const Text('Info'),
                  ),
                ],
              ),
            ],
            if (verification.rejectionReason != null && verification.rejectionReason!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Motivo da rejeição:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      verification.rejectionReason!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),
            ],
            if (verification.status == VerificationStatus.pending) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _approveVerification(verification.userId),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Aprovar'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _showRejectDialog(verification.userId),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        foregroundColor: Colors.red,
                      ),
                      child: const Text('Rejeitar'),
                    ),
                  ),
                ],
              ),
            ],
            if (verification.status == VerificationStatus.approved) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _requestRevalidation(verification.userId),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Solicitar Revalidação'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.orange),
                    foregroundColor: Colors.orange,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
           '${date.month.toString().padLeft(2, '0')}/'
           '${date.year} ${date.hour.toString().padLeft(2, '0')}:'
           '${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    // Verificar se o usuário é admin
    if (!_isAdmin) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Acesso Negado'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.admin_panel_settings,
                size: 80,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              const Text(
                'Acesso Restrito',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Você não tem permissão para acessar o painel administrativo.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Voltar'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Painel Administrativo'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(
              text: 'Verificações',
              icon: Icon(Icons.verified_user, color: Colors.white),
            ),
            Tab(
              text: 'Administradores',
              icon: Icon(Icons.admin_panel_settings, color: Colors.white),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Atualizar',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildVerificationsTab(),
          _buildAdministratorsTab(),
        ],
      ),
    );
  }

  Widget _buildVerificationsTab() {
    if (_isLoading) {
      return ListView.builder(
        itemCount: 5,
        itemBuilder: (context, index) => const VehicleCardSkeleton(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadVerifications,
              child: const Text('Tentar Novamente'),
            ),
          ],
        ),
      );
    }

    if (_verifications.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: Colors.green,
            ),
            SizedBox(height: 16),
            Text(
              'Nenhuma solicitação pendente',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadVerifications,
      child: ListView.builder(
        itemCount: _verifications.length,
        itemBuilder: (context, index) =>
            _buildVerificationCard(_verifications[index]),
      ),
    );
  }

  Widget _buildAdministratorsTab() {
    return Column(
      children: [
        if (_isSuperAdmin) ...[
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: _showAddAdminDialog,
              icon: const Icon(Icons.add),
              label: const Text('Adicionar Administrador'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
        Expanded(
          child: _administrators.isEmpty
              ? const Center(
                  child: Text('Nenhum administrador encontrado'),
                )
              : ListView.builder(
                  itemCount: _administrators.length,
                  itemBuilder: (context, index) =>
                      _buildAdministratorCard(_administrators[index]),
                ),
        ),
      ],
    );
  }

  void _showAddAdminDialog() {
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Adicionar Administrador'),
        content: TextField(
          controller: emailController,
          decoration: const InputDecoration(
            labelText: 'Email do novo administrador',
            hintText: 'exemplo@email.com',
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final email = emailController.text.trim();
              if (email.isNotEmpty) {
                final success = await AdminService.addAdministrator(email);
                if (success) {
                  Navigator.of(context).pop();
                  _loadAdministrators();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Administrador adicionado com sucesso!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Erro ao adicionar administrador'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );
  }

  Widget _buildAdministratorCard(Administrator admin) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: admin.isSuperAdmin ? Colors.red : Colors.blue,
          child: Icon(
            admin.isSuperAdmin ? Icons.admin_panel_settings : Icons.admin_panel_settings_outlined,
            color: Colors.white,
          ),
        ),
        title: Text(admin.email),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              admin.isSuperAdmin ? 'Super Administrador' : 'Administrador',
              style: TextStyle(
                color: admin.isSuperAdmin ? Colors.red : Colors.blue,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              'Criado em: ${_formatDate(admin.createdAt)}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        trailing: _isSuperAdmin && !admin.isSuperAdmin
            ? IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _showRemoveAdminDialog(admin),
              )
            : null,
      ),
    );
  }

  void _showRemoveAdminDialog(Administrator admin) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover Administrador'),
        content: Text(
          'Tem certeza que deseja remover ${admin.email} dos administradores?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final success = await AdminService.removeAdministrator(admin.id);
              if (success) {
                Navigator.of(context).pop();
                _loadAdministrators();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Administrador removido com sucesso!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Erro ao remover administrador'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
  }
}