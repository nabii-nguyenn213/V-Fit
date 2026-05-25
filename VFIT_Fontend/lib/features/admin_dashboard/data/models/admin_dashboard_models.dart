class MonthlyRevenueResponseModel {
  final double lifetimeRevenue;
  final List<MonthlyRevenueItemModel> monthlyDetails;
  final List<RecentTransactionModel> recentTransactions;

  const MonthlyRevenueResponseModel({
    required this.lifetimeRevenue,
    required this.monthlyDetails,
    required this.recentTransactions,
  });

  factory MonthlyRevenueResponseModel.fromJson(Map<String, dynamic> json) {
    return MonthlyRevenueResponseModel(
      lifetimeRevenue: (json['lifetimeRevenue'] as num?)?.toDouble() ?? 0.0,
      monthlyDetails: (json['monthlyDetails'] as List?)
              ?.map((item) => MonthlyRevenueItemModel.fromJson(Map<String, dynamic>.from(item as Map)))
              .toList() ??
          [],
      recentTransactions: (json['recentTransactions'] as List?)
              ?.map((item) => RecentTransactionModel.fromJson(Map<String, dynamic>.from(item as Map)))
              .toList() ??
          [],
    );
  }
}

class MonthlyRevenueItemModel {
  final String month;
  final double totalRevenue;
  final int totalOrders;
  final double growthRate;

  const MonthlyRevenueItemModel({
    required this.month,
    required this.totalRevenue,
    required this.totalOrders,
    required this.growthRate,
  });

  factory MonthlyRevenueItemModel.fromJson(Map<String, dynamic> json) {
    return MonthlyRevenueItemModel(
      month: json['month']?.toString() ?? '',
      totalRevenue: (json['totalRevenue'] as num?)?.toDouble() ?? 0.0,
      totalOrders: (json['totalOrders'] as num?)?.toInt() ?? 0,
      growthRate: (json['growthRate'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class RecentTransactionModel {
  final String id;
  final String userId;
  final String orderType;
  final double amount;
  final String status;
  final String? voucherCode;
  final DateTime createdAt;

  const RecentTransactionModel({
    required this.id,
    required this.userId,
    required this.orderType,
    required this.amount,
    required this.status,
    this.voucherCode,
    required this.createdAt,
  });

  factory RecentTransactionModel.fromJson(Map<String, dynamic> json) {
    return RecentTransactionModel(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      orderType: json['orderType']?.toString() ?? 'PREMIUM',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      status: json['status']?.toString() ?? 'SUCCESS',
      voucherCode: json['voucherCode']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now(),
    );
  }
}

class PaginatedTransactionResponseModel {
  final List<RecentTransactionModel> content;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;
  final bool last;

  const PaginatedTransactionResponseModel({
    required this.content,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
    required this.last,
  });

  factory PaginatedTransactionResponseModel.fromJson(Map<String, dynamic> json) {
    final page = (json['page'] as num?)?.toInt() ?? 0;
    final size = (json['size'] as num?)?.toInt() ?? 5;
    final totalElements = (json['totalElements'] as num?)?.toInt() ?? 0;
    final totalPages = (json['totalPages'] as num?)?.toInt() ?? 0;
    final isLast = json['last'] as bool? ?? json['isLast'] as bool? ?? (page + 1 >= totalPages);
    
    return PaginatedTransactionResponseModel(
      content: (json['content'] as List?)
              ?.map((item) => RecentTransactionModel.fromJson(Map<String, dynamic>.from(item as Map)))
              .toList() ??
          [],
      page: page,
      size: size,
      totalElements: totalElements,
      totalPages: totalPages,
      last: isLast,
    );
  }
}
