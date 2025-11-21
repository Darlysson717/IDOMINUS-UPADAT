enum VerificationStatus {
  pending,
  approved,
  rejected,
  incomplete
}

class SellerVerification {
  final String userId;
  final String cnpj;
  final String storeName; // Nome da loja (da conta Google)
  final String documentoUrl; // URL do Alvará de Funcionamento
  final VerificationStatus status;
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime? reviewedAt;

  SellerVerification({
    required this.userId,
    required this.cnpj,
    required this.storeName,
    required this.documentoUrl,
    this.status = VerificationStatus.incomplete,
    this.rejectionReason,
    required this.createdAt,
    this.reviewedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'cnpj': cnpj,
      'store_name': storeName,
      'documento_url': documentoUrl,
      'status': status.toString().split('.').last,
      'rejection_reason': rejectionReason,
      'created_at': createdAt.toIso8601String(),
      'reviewed_at': reviewedAt?.toIso8601String(),
    };
  }

  factory SellerVerification.fromJson(Map<String, dynamic> json) {
    return SellerVerification(
      userId: json['user_id'],
      cnpj: json['cnpj'],
      storeName: json['store_name'] ?? 'Nome não informado',
      documentoUrl: json['documento_url'],
      status: VerificationStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => VerificationStatus.pending,
      ),
      rejectionReason: json['rejection_reason'],
      createdAt: DateTime.parse(json['created_at']),
      reviewedAt: json['reviewed_at'] != null ? DateTime.parse(json['reviewed_at']) : null,
    );
  }
}