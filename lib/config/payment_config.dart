class PaymentConfig {
  const PaymentConfig._();

  /// Public key used by the client to initialize Mercado Pago in test mode.
  static const String mercadoPagoPublicKey =
      'APP_USR-9675e84a-034d-4edf-8da9-afc35a442193';

  /// Access token for Mercado Pago API (server-side).
  static const String mercadoPagoAccessToken =
      'APP_USR-7268646702366031-010217-21d260f1d0fb7f01525f219e417bd479-3107430440';

  /// Optional notification URL configured in the backend/secret manager.
  /// Provide via --dart-define=PIX_NOTIFICATION_URL="https://..." to override.
  static const String pixNotificationUrl = String.fromEnvironment(
    'PIX_NOTIFICATION_URL',
    defaultValue: '',
  );

  /// Email fallback used when the authenticated user does not expose one.
  static const String fallbackPayerEmail = 'pagador-teste@domin.us';

  /// Optional Efipay credentials injected via --dart-define (never hardcode).
  static const String efiPayClientId = String.fromEnvironment(
    'EFIPAY_CLIENT_ID',
    defaultValue: '',
  );

  static const String efiPayClientSecret = String.fromEnvironment(
    'EFIPAY_CLIENT_SECRET',
    defaultValue: '',
  );

  static const String efiPayAccountId = String.fromEnvironment(
    'EFIPAY_ACCOUNT_ID',
    defaultValue: '',
  );

  static const bool efiPaySandbox = bool.fromEnvironment(
    'EFIPAY_SANDBOX',
    defaultValue: true,
  );

  static const String efiPayCertificatePath = String.fromEnvironment(
    'EFIPAY_CERTIFICATE_PATH',
    defaultValue: '',
  );
}
