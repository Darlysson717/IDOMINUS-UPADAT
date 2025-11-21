import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/cnpj_validator.dart';
import '../services/seller_verification_service.dart';
import '../models/seller_verification.dart';

class SellerVerificationPage extends StatefulWidget {
  const SellerVerificationPage({Key? key}) : super(key: key);

  @override
  State<SellerVerificationPage> createState() => _SellerVerificationPageState();
}

class _SellerVerificationPageState extends State<SellerVerificationPage> {
  final _formKey = GlobalKey<FormState>();
  final _verificationService = SellerVerificationService();

  final _cnpjController = TextEditingController();
  String? _documentoUrl;
  bool _isLoading = false;
  SellerVerification? _currentVerification;

  @override
  void initState() {
    super.initState();
    _loadCurrentVerification();
  }

  Future<void> _loadCurrentVerification() async {
    final verification = await _verificationService.getCurrentUserVerification();
    if (verification != null) {
      setState(() {
        _currentVerification = verification;
        _cnpjController.text = verification.cnpj;
        _documentoUrl = verification.documentoUrl;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentVerification?.status == VerificationStatus.approved) {
      return _buildApprovedView();
    }

    if (_currentVerification?.status == VerificationStatus.pending) {
      return _buildPendingView();
    }

    if (_currentVerification?.status == VerificationStatus.rejected) {
      return _buildRejectedView();
    }

    return _buildFormView();
  }

  Widget _buildFormView() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verificação de Vendedor'),
        backgroundColor: const Color(0xFF4C1D95),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Para vender no marketplace, você precisa verificar sua loja.',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Precisamos apenas do CNPJ e do Alvará de Funcionamento.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),

              // CNPJ
              TextFormField(
                controller: _cnpjController,
                decoration: const InputDecoration(
                  labelText: 'CNPJ',
                  hintText: '00.000.000/0000-00',
                  helperText: 'Para teste: use 12.345.678/0001-95 (CNPJ válido)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'CNPJ é obrigatório';
                  }
                  if (!CNPJValidator.isValid(value)) {
                    return 'CNPJ inválido';
                  }
                  return null;
                },
                onChanged: (value) {
                  final formatted = CNPJValidator.format(value);
                  if (formatted != value) {
                    _cnpjController.value = TextEditingValue(
                      text: formatted,
                      selection: TextSelection.collapsed(offset: formatted.length),
                    );
                  }
                },
              ),
              const SizedBox(height: 24),

              // Documento
              const Text(
                'Documento Necessário:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                '• Alvará de Funcionamento',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),

              // Status do documento
              if (_documentoUrl != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Alvará de Funcionamento anexado',
                          style: TextStyle(color: Colors.green, fontWeight: FontWeight.w500),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            _documentoUrl = null;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.file_upload, color: Colors.grey),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Nenhum documento anexado',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Botão para adicionar documento
              ElevatedButton.icon(
                onPressed: _pickDocumento,
                icon: const Icon(Icons.add_photo_alternate),
                label: const Text('Anexar Alvará'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4C1D95),
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
              const SizedBox(height: 24),

              // Botão de envio
              ElevatedButton(
                onPressed: _isLoading ? null : _submitVerification,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4C1D95),
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Enviar para Verificação'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPendingView() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verificação Pendente'),
        backgroundColor: const Color(0xFF4C1D95),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.pending,
              size: 64,
              color: Colors.orange,
            ),
            const SizedBox(height: 16),
            const Text(
              'Sua solicitação está sendo analisada',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Em até 48 horas você receberá uma resposta.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApprovedView() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verificação Aprovada'),
        backgroundColor: const Color(0xFF4C1D95),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.verified,
              size: 64,
              color: Colors.green,
            ),
            const SizedBox(height: 16),
            const Text(
              'Parabéns! Sua conta foi verificada.',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Agora você pode publicar anúncios no marketplace.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(horizontal: 32),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.update,
                    color: Colors.blue,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Deseja atualizar seus documentos?',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.blue,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Mantenha suas informações sempre atualizadas',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _showResubmitDialog,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Atualizar Documentos'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRejectedView() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verificação Rejeitada'),
        backgroundColor: const Color(0xFF4C1D95),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.cancel,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            const Text(
              'Sua solicitação foi rejeitada',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Motivo: ${_currentVerification?.rejectionReason ?? "Não informado"}',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _currentVerification = null;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4C1D95),
              ),
              child: const Text('Tentar Novamente'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDocumento() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() => _isLoading = true);
      try {
        final url = await _verificationService.uploadDocumento(
          pickedFile.path,
          pickedFile.name,
        );
        setState(() {
          _documentoUrl = url;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao fazer upload: $e')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _submitVerification() async {
    if (!_formKey.currentState!.validate()) return;

    if (_documentoUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Anexe o Alvará de Funcionamento')),
      );
      return;
    }

    // Verificar se já existe uma verificação
    if (_currentVerification != null) {
      if (_currentVerification!.status == VerificationStatus.pending) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Você já tem uma solicitação pendente'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      if (_currentVerification!.status == VerificationStatus.approved) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sua conta já foi verificada'),
            backgroundColor: Colors.green,
          ),
        );
        return;
      }

      // Se foi rejeitado, permitir reenviar
      if (_currentVerification!.status == VerificationStatus.rejected) {
        final shouldResubmit = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Reenviar Solicitação'),
            content: const Text(
              'Sua solicitação anterior foi rejeitada. Deseja reenviar com os dados atualizados?'
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Reenviar'),
              ),
            ],
          ),
        );

        if (shouldResubmit != true) return;
      }
    }

    setState(() => _isLoading = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('Usuário não logado');

      // Buscar nome da loja da conta Google/Supabase
      // Debug: verificar estrutura dos metadados
      print('=== DEBUG: User Info ===');
      print('User ID: ${user.id}');
      print('User Email: ${user.email}');
      print('Raw User Object: $user');

      // Para Google OAuth, o nome geralmente vem nestes campos:
      String? storeName;

      // 1. Verificar se há dados no userMetadata (Google OAuth)
      final metadata = user.userMetadata;
      if (metadata != null && metadata.isNotEmpty) {
        print('User Metadata keys: ${metadata.keys}');
        storeName ??= metadata['full_name'];
        storeName ??= metadata['name'];
        storeName ??= metadata['given_name'];
        if (metadata['given_name'] != null && metadata['family_name'] != null) {
          storeName ??= '${metadata['given_name']} ${metadata['family_name']}';
        }
        storeName ??= metadata['preferred_username'];
      }

      // 2. Verificar propriedades diretas do objeto User
      if (storeName == null) {
        try {
          // Tentar acessar propriedades que podem existir
          final userMap = user.toJson();
          print('User JSON keys: ${userMap.keys}');
          storeName ??= userMap['display_name'];
          storeName ??= userMap['name'];
        } catch (e) {
          print('Erro ao acessar propriedades do usuário: $e');
        }
      }

      // 3. Último recurso: usar parte do email
      storeName ??= user.email?.split('@').first;

      // 4. Padrão final
      storeName ??= 'Loja sem nome';

      print('Store name final: $storeName');

      final verification = SellerVerification(
        userId: user.id,
        cnpj: _cnpjController.text.replaceAll(RegExp(r'[^0-9]'), ''),
        storeName: storeName,
        documentoUrl: _documentoUrl!,
        status: VerificationStatus.pending,
        createdAt: DateTime.now(),
      );

      await _verificationService.submitVerification(verification);

      // Recarregar a verificação atualizada
      await _loadCurrentVerification();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verificação enviada com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao enviar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showResubmitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Atualizar Documentos'),
        content: const Text(
          'Deseja enviar uma nova solicitação de verificação? '
          'Seus documentos atuais serão substituídos pelos novos.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Limpar dados atuais e voltar para o formulário
              setState(() {
                _currentVerification = null;
                _documentoUrl = null;
                _cnpjController.clear();
              });
            },
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _cnpjController.dispose();
    super.dispose();
  }
}