class DashboardStatsModel {
  const DashboardStatsModel({
    required this.monthlyVipCustomers,
    required this.yearlyVipCustomers,
    required this.monthlyRevenue,
    required this.yearlyRevenue,
    required this.totalRevenue,
  });

  final int monthlyVipCustomers;
  final int yearlyVipCustomers;
  final num monthlyRevenue;
  final num yearlyRevenue;
  final num totalRevenue;

  factory DashboardStatsModel.fromJson(Map<String, dynamic> json) {
    return DashboardStatsModel(
      monthlyVipCustomers: (json['monthlyVipCustomers'] as num?)?.toInt() ?? 0,
      yearlyVipCustomers: (json['yearlyVipCustomers'] as num?)?.toInt() ?? 0,
      monthlyRevenue: json['monthlyRevenue'] as num? ?? 0,
      yearlyRevenue: json['yearlyRevenue'] as num? ?? 0,
      totalRevenue: json['totalRevenue'] as num? ?? 0,
    );
  }
}
