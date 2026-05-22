class CheckoutRequest {
  const CheckoutRequest({this.voucherCode});

  final String? voucherCode;

  Map<String, dynamic> toJson() {
    return {
      'voucherCode': voucherCode,
    };
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
