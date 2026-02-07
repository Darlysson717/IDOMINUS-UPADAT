import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/payment_config.dart';

class PixPaymentResult {
  final String paymentId;
  final String qrCode;
  final String copyPasteKey;
  final String? qrCodeBase64;
  final String? ticketUrl;
  final double? transactionAmount;
  final DateTime? expiresAt;

  PixPaymentResult._(
    this.paymentId,
    this.qrCode,
    this.copyPasteKey, {
    this.qrCodeBase64,
    this.ticketUrl,
    this.transactionAmount,
    this.expiresAt,
  });

  bool get hasQrCode => qrCode.isNotEmpty;

  factory PixPaymentResult.fromMap(Map<String, dynamic> map) {
    return PixPaymentResult._(
      map['paymentId']?.toString() ?? '',
      map['qrCode']?.toString() ?? '',
      map['copyPasteKey']?.toString() ?? '',
      qrCodeBase64: map['qrCodeBase64']?.toString(),
      ticketUrl: map['ticketUrl']?.toString(),
      transactionAmount: map['transactionAmount'] is num
          ? (map['transactionAmount'] as num).toDouble()
          : double.tryParse(map['transactionAmount']?.toString() ?? ''),
      expiresAt: map['expiresAt'] != null
          ? DateTime.tryParse(map['expiresAt'].toString())
          : null,
    );
  }
}

class PixPaymentService {
  PixPaymentService._();

  static final PixPaymentService instance = PixPaymentService._();
  final SupabaseClient _client = Supabase.instance.client;

  Future<PixPaymentResult> createPixPayment({
    required int amountInCents,
    required String planType,
    required String description,
    Map<String, dynamic>? metadata,
    String? payerEmail,
  }) async {
    final body = <String, dynamic>{
      'amount_in_cents': amountInCents,
      'plan_type': planType,
      'description': description,
      'metadata': metadata ?? <String, dynamic>{},
    };

    if (payerEmail != null && payerEmail.isNotEmpty) {
      body['payer_email'] = payerEmail;
    }

    final response = await _client.functions.invoke(
      'create-mercadopago-pix',
      body: body,
    );

    if (response.status >= 300) {
      String? errorMessage;
      if (response.data is Map<String, dynamic>) {
        errorMessage = (response.data as Map<String, dynamic>)['message']?.toString();
      } else if (response.data is Map) {
        errorMessage = (response.data as Map)['message']?.toString();
      } else {
        errorMessage = response.data?.toString();
      }
      throw Exception(
        errorMessage ?? 'Falha ao gerar o pagamento PIX. Status ${response.status}',
      );
    }

    final raw = response.data;
    Map<String, dynamic> data;
    if (raw is Map<String, dynamic>) {
      data = raw;
    } else if (raw is Map) {
      data = raw.map<String, dynamic>((key, value) => MapEntry(key.toString(), value));
    } else {
      data = <String, dynamic>{};
    }

    final result = PixPaymentResult.fromMap(data);
    if (!result.hasQrCode) {
      throw Exception('A resposta do servidor não possui QR Code PIX');
    }

    return result;
  }
}
