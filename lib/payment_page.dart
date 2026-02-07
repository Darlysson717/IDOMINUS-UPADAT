import 'package:efipay/efipay.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'config/payment_config.dart';
import 'services/business_ads_service.dart';
import 'services/pix_payment_service.dart';

class PaymentPage extends StatefulWidget {
  final String selectedPlan;
  final String planPrice;
  final Map<String, dynamic> adData;

  const PaymentPage({
    super.key,
    required this.selectedPlan,
    required this.planPrice,
    required this.adData,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  PixPaymentResult? _pixPayment;
  String? _pixError;
  bool _isLoading = false;
  bool _paymentCompleted = false;

  @override
  void initState() {
    super.initState();
    _generatePixPayment();
  }

  Future<void> _generatePixPayment() async {
    setState(() {
      _isLoading = true;
      _pixError = null;
    });

    try {
      final amountInCents = _getAmountFromPlan();
      final payerEmail = Supabase.instance.client.auth.currentUser?.email ??
          widget.adData['userEmail']?.toString();

      final metadata = <String, dynamic>{
        'business_name': widget.adData['businessName'],
        'category': widget.adData['category'],
        'city': widget.adData['city'],
        'plan_type': widget.selectedPlan,
      }..removeWhere(
          (key, value) => value == null || (value is String && value.isEmpty),
        );

      final pixResult = await PixPaymentService.instance.createPixPayment(
        amountInCents: amountInCents,
        planType: widget.selectedPlan,
        description: _getPlanDescription(),
        metadata: metadata,
        payerEmail: (payerEmail != null && payerEmail.isNotEmpty)
            ? payerEmail
            : PaymentConfig.fallbackPayerEmail,
      );

      setState(() {
        _pixPayment = pixResult;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao gerar PIX: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _pixError = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  int _getAmountFromPlan() {
    // Converter preço para centavos
    final priceString = widget.planPrice.replaceAll('R\$ ', '').replaceAll('/mês', '');
    final price = double.parse(priceString);
    return (price * 100).toInt(); // Converter para centavos
  }

  String _getPlanDescription() {
    switch (widget.selectedPlan) {
      case 'basico':
        return 'Banner rotativo local';
      case 'destaque':
        return 'Card patrocinado';
      case 'premium':
        return 'Prioridade + topo';
      default:
        return '';
    }
  }

  String _formatExpiration(DateTime expiresAt) {
    String twoDigits(int value) => value.toString().padLeft(2, '0');
    final local = expiresAt.toLocal();
    return '${twoDigits(local.day)}/${twoDigits(local.month)}/${local.year} '
        '${twoDigits(local.hour)}:${twoDigits(local.minute)}';
  }

  void _copyPixCode() {
    final copyPasteKey = _pixPayment?.copyPasteKey;
    if (copyPasteKey != null && copyPasteKey.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: copyPasteKey));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Código PIX copiado para a área de transferência'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nenhum código PIX disponível para copiar'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _simulatePaymentCompletion() async {
    try {
      String? imageUrl;

      // Fazer upload da imagem se existir
      if (widget.adData['image'] != null && (widget.adData['image'] is XFile || widget.adData['image'] is File)) {
        final businessAdsService = BusinessAdsService();

        // Converter File para XFile se necessário
        XFile? imageFile;
        if (widget.adData['image'] is File) {
          // Para File, criar um XFile temporário
          final file = widget.adData['image'] as File;
          imageFile = XFile(file.path, name: file.path.split('/').last);
        } else if (widget.adData['image'] is XFile) {
          imageFile = widget.adData['image'] as XFile;
        }

        if (imageFile != null) {
          imageUrl = await businessAdsService.uploadBusinessAdImage(imageFile);
        }
      }

      // Salvar anúncio no banco de dados
      await BusinessAdsService().saveBusinessAd(
        planType: widget.selectedPlan,
        amountPaid: _getAmountFromPlan(),
        paymentId: 'simulated_${DateTime.now().millisecondsSinceEpoch}',
        businessName: widget.adData['businessName'],
        category: widget.adData['category'],
        city: widget.adData['city'],
        whatsapp: widget.adData['whatsapp'],
        website: widget.adData['website'],
        creativeText: widget.adData['creativeText'],
        imageUrl: imageUrl,
      );

      setState(() {
        _paymentCompleted = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pagamento confirmado! Anúncio criado com sucesso.'),
          backgroundColor: Colors.green,
        ),
      );

      // Voltar para a tela inicial após 2 segundos
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar anúncio: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_paymentCompleted) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 80,
              ),
              const SizedBox(height: 16),
              const Text(
                'Pagamento Confirmado!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Seu anúncio foi criado com sucesso.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pagamento PIX'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Resumo do pedido
            const Text(
              'Resumo do Pedido',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Plano: ${_getPlanDescription()}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Valor: ${widget.planPrice}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF667EEA),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Cobrança mensal',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // QR Code PIX
            const Text(
              'QR Code PIX',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            if (_isLoading)
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Gerando código PIX...'),
                  ],
                ),
              )
            else if (_pixPayment?.qrCode.isNotEmpty ?? false)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: QrImageView(
                          data: _pixPayment!.qrCode,
                          version: QrVersions.auto,
                          size: 200.0,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Escaneie o QR Code com seu app bancário',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _copyPixCode,
                        icon: const Icon(Icons.copy),
                        label: const Text('Copiar código PIX'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade200,
                          foregroundColor: Colors.black,
                        ),
                      ),
                      if (_pixPayment?.expiresAt != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Expira em: ${_formatExpiration(_pixPayment!.expiresAt!)}',
                          style: const TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        'ID do pagamento: ${_pixPayment?.paymentId ?? '---'}',
                        style: const TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              )
            else
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(Icons.qr_code_2_outlined, size: 64, color: Colors.grey.shade500),
                      const SizedBox(height: 12),
                      Text(
                        _pixError ?? 'Não foi possível gerar o QR Code PIX. Tente novamente.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _generatePixPayment,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 32),

            // Informações do anúncio (se fornecidas)
            if (widget.adData['businessName']?.isNotEmpty ?? false) ...[
              const Text(
                'Informações do Anúncio',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.adData['businessName']?.isNotEmpty ?? false)
                        Text('Nome: ${widget.adData['businessName']}'),
                      if (widget.adData['category']?.isNotEmpty ?? false)
                        Text('Categoria: ${widget.adData['category']}'),
                      if (widget.adData['city']?.isNotEmpty ?? false)
                        Text('Cidade: ${widget.adData['city']}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],

            // Botão de simulação (apenas para teste)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.yellow.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.yellow.shade200),
              ),
              child: Column(
                children: [
                  const Text(
                    'Modo de Teste',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Clique no botão abaixo para simular a confirmação do pagamento.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _simulatePaymentCompletion,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: const Text('Simular Pagamento Confirmado'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Nota sobre produção
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: const Text(
                'Em produção, o pagamento será confirmado automaticamente quando o PIX for processado pelo banco.',
                style: TextStyle(
                  color: Colors.blue,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}