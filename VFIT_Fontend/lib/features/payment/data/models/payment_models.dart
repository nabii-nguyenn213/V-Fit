class CheckoutRequest {
  const CheckoutRequest({this.voucherCode});

  final String? voucherCode;

  Map<String, dynamic> toJson() {
    return {
      'voucherCode': voucherCode,
    };
  }
}

enum PremiumPlan {
  monthly('MONTHLY'),
  yearly('YEARLY');

  const PremiumPlan(this.apiValue);

  final String apiValue;

  static PremiumPlan? fromApiValue(String? value) {
    for (final plan in PremiumPlan.values) {
      if (plan.apiValue == value) {
        return plan;
      }
    }
    return null;
  }
}

enum PremiumPaymentStatus {
  pending('PENDING'),
  paid('PAID'),
  expired('EXPIRED'),
  failed('FAILED'),
  manualReview('MANUAL_REVIEW');

  const PremiumPaymentStatus(this.apiValue);

  final String apiValue;

  static PremiumPaymentStatus? fromApiValue(String? value) {
    for (final status in PremiumPaymentStatus.values) {
      if (status.apiValue == value) {
        return status;
      }
    }
    return null;
  }
}

class CreatePremiumPaymentRequest {
  const CreatePremiumPaymentRequest({
    required this.plan,
    this.voucherCode,
  });

  final PremiumPlan plan;
  final String? voucherCode;

  Map<String, dynamic> toJson() {
    return {
      'plan': plan.apiValue,
      if (voucherCode != null && voucherCode!.trim().isNotEmpty)
        'voucherCode': voucherCode!.trim().toUpperCase(),
    };
  }
}

class PremiumPayment {
  const PremiumPayment({
    required this.paymentId,
    required this.plan,
    required this.baseAmount,
    required this.discountAmount,
    required this.finalAmount,
    required this.bankCode,
    required this.accountNumber,
    required this.accountName,
    required this.paymentCode,
    required this.vietQrUrl,
    required this.expiredAt,
    this.voucherCode,
  });

  final String paymentId;
  final PremiumPlan? plan;
  final double baseAmount;
  final double discountAmount;
  final double finalAmount;
  final String bankCode;
  final String accountNumber;
  final String accountName;
  final String paymentCode;
  final String? voucherCode;
  final String vietQrUrl;
  final DateTime? expiredAt;

  factory PremiumPayment.fromJson(Map<String, dynamic> json) {
    return PremiumPayment(
      paymentId: json['paymentId']?.toString() ?? '',
      plan: PremiumPlan.fromApiValue(json['plan']?.toString()),
      baseAmount: (json['baseAmount'] as num?)?.toDouble() ?? 0,
      discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0,
      finalAmount: (json['finalAmount'] as num?)?.toDouble() ??
          (json['amount'] as num?)?.toDouble() ??
          0,
      bankCode: json['bankCode']?.toString() ?? '',
      accountNumber: json['accountNumber']?.toString() ?? '',
      accountName: json['accountName']?.toString() ?? '',
      paymentCode: json['paymentCode']?.toString() ?? '',
      voucherCode: json['voucherCode']?.toString(),
      vietQrUrl: json['vietQrUrl']?.toString() ?? '',
      expiredAt: DateTime.tryParse(json['expiredAt']?.toString() ?? ''),
    );
  }
}

class PremiumPaymentStatusResult {
  const PremiumPaymentStatusResult({
    required this.paymentId,
    required this.status,
    required this.premiumUnlocked,
    this.premiumExpiredAt,
  });

  final String paymentId;
  final PremiumPaymentStatus? status;
  final bool premiumUnlocked;
  final DateTime? premiumExpiredAt;

  factory PremiumPaymentStatusResult.fromJson(Map<String, dynamic> json) {
    return PremiumPaymentStatusResult(
      paymentId: json['paymentId']?.toString() ?? '',
      status: PremiumPaymentStatus.fromApiValue(json['status']?.toString()),
      premiumUnlocked: json['premiumUnlocked'] == true,
      premiumExpiredAt:
          DateTime.tryParse(json['premiumExpiredAt']?.toString() ?? ''),
    );
  }
}

class PremiumPaymentRealtimeEvent {
  const PremiumPaymentRealtimeEvent({
    required this.type,
    required this.paymentId,
    required this.status,
    required this.premiumUnlocked,
    this.paidAt,
  });

  final String type;
  final String paymentId;
  final PremiumPaymentStatus? status;
  final bool premiumUnlocked;
  final DateTime? paidAt;

  bool get isPaid =>
      type == 'PAYMENT_PAID' &&
      status == PremiumPaymentStatus.paid &&
      premiumUnlocked;

  factory PremiumPaymentRealtimeEvent.fromJson(Map<String, dynamic> json) {
    return PremiumPaymentRealtimeEvent(
      type: json['type']?.toString() ?? '',
      paymentId: json['paymentId']?.toString() ?? '',
      status: PremiumPaymentStatus.fromApiValue(json['status']?.toString()),
      premiumUnlocked: json['premiumUnlocked'] == true,
      paidAt: DateTime.tryParse(json['paidAt']?.toString() ?? ''),
    );
  }
}

class PaymentQuote {
  const PaymentQuote({
    required this.orderId,
    required this.planCode,
    required this.originalAmount,
    required this.discountAmount,
    required this.finalAmount,
    this.voucherCode,
  });

  final String orderId;
  final String planCode;
  final double originalAmount;
  final double discountAmount;
  final double finalAmount;
  final String? voucherCode;

  factory PaymentQuote.fromJson(Map<String, dynamic> json) {
    return PaymentQuote(
      orderId: json['orderId']?.toString() ?? '',
      planCode: json['planCode']?.toString() ?? '',
      originalAmount: (json['originalAmount'] as num?)?.toDouble() ?? 0,
      discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0,
      finalAmount: (json['finalAmount'] as num?)?.toDouble() ?? 0,
      voucherCode: json['voucherCode']?.toString(),
    );
  }
}

class CheckoutResult {
  const CheckoutResult({
    required this.orderId,
    required this.transactionId,
    required this.planCode,
    required this.originalAmount,
    required this.discountAmount,
    required this.finalAmount,
    required this.status,
    this.voucherCode,
    this.premiumUntil,
  });

  final String orderId;
  final String transactionId;
  final String planCode;
  final double originalAmount;
  final double discountAmount;
  final double finalAmount;
  final String status;
  final String? voucherCode;
  final DateTime? premiumUntil;

  factory CheckoutResult.fromJson(Map<String, dynamic> json) {
    return CheckoutResult(
      orderId: json['orderId']?.toString() ?? '',
      transactionId: json['transactionId']?.toString() ?? '',
      planCode: json['planCode']?.toString() ?? '',
      originalAmount: (json['originalAmount'] as num?)?.toDouble() ?? 0,
      discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0,
      finalAmount: (json['finalAmount'] as num?)?.toDouble() ?? 0,
      status: json['status']?.toString() ?? '',
      voucherCode: json['voucherCode']?.toString(),
      premiumUntil: DateTime.tryParse(json['premiumUntil']?.toString() ?? ''),
    );
  }
}
