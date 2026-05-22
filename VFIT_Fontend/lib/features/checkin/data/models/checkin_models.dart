class CheckinResult {
  const CheckinResult({
    required this.checkinDate,
    required this.monthKey,
    required this.monthCheckinCount,
    required this.awardedVouchers,
  });

  final String checkinDate;
  final String monthKey;
  final int monthCheckinCount;
  final List<CheckinVoucher> awardedVouchers;

  factory CheckinResult.fromJson(Map<String, dynamic> json) {
    final vouchers = json['awardedVouchers'] as List? ?? const [];
    return CheckinResult(
      checkinDate: json['checkinDate']?.toString() ?? '',
      monthKey: json['monthKey']?.toString() ?? '',
      monthCheckinCount: (json['monthCheckinCount'] as num?)?.toInt() ?? 0,
      awardedVouchers: vouchers
          .whereType<Map>()
          .map(
            (item) => CheckinVoucher.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(),
    );
  }
}

class CheckinVoucher {
  const CheckinVoucher({
    required this.id,
    required this.code,
    required this.amount,
    required this.status,
    this.issuedAt,
    this.expiredAt,
    this.rewardMilestone,
  });

  final String id;
  final String code;
  final double amount;
  final String status;
  final DateTime? issuedAt;
  final DateTime? expiredAt;
  final int? rewardMilestone;

  factory CheckinVoucher.fromJson(Map<String, dynamic> json) {
    return CheckinVoucher(
      id: json['id']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      amount: _readDouble(json['amount']),
      status: json['status']?.toString() ?? '',
      issuedAt: DateTime.tryParse(json['issuedAt']?.toString() ?? ''),
      expiredAt: DateTime.tryParse(json['expiredAt']?.toString() ?? ''),
      rewardMilestone: (json['rewardMilestone'] as num?)?.toInt(),
    );
  }

  String get amountLabel {
    final value = amount.round();
    if (value >= 1000 && value % 1000 == 0) {
      return '${value ~/ 1000}K';
    }
    return value.toString();
  }
}

double _readDouble(Object? value) {
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

class CheckinStatus {
  const CheckinStatus({
    required this.checkedToday,
    required this.monthCheckinCount,
  });

  final bool checkedToday;
  final int monthCheckinCount;

  factory CheckinStatus.fromJson(Map<String, dynamic> json) {
    return CheckinStatus(
      checkedToday: json['checkedToday'] == true,
      monthCheckinCount: (json['monthCheckinCount'] as num?)?.toInt() ?? 0,
    );
  }
}
