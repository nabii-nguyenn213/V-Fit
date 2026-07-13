class MonthlyRevenueResponseModel {
  final double lifetimeRevenue;
  final List<MonthlyRevenueItemModel> monthlyDetails;
  final List<RecentTransactionModel> recentTransactions;
  final int totalUsers;
  final int activeVipUsers;
  final int freeUsers;
  final int onboardingCompletedUsers;
  final int onboardingPendingUsers;
  final List<RegistrationTrendItemModel> registrationTrend;

  const MonthlyRevenueResponseModel({
    required this.lifetimeRevenue,
    required this.monthlyDetails,
    required this.recentTransactions,
    this.totalUsers = 0,
    this.activeVipUsers = 0,
    this.freeUsers = 0,
    this.onboardingCompletedUsers = 0,
    this.onboardingPendingUsers = 0,
    this.registrationTrend = const [],
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
      totalUsers: (json['totalUsers'] as num?)?.toInt() ?? 0,
      activeVipUsers: (json['activeVipUsers'] as num?)?.toInt() ?? 0,
      freeUsers: (json['freeUsers'] as num?)?.toInt() ?? 0,
      onboardingCompletedUsers: (json['onboardingCompletedUsers'] as num?)?.toInt() ?? 0,
      onboardingPendingUsers: (json['onboardingPendingUsers'] as num?)?.toInt() ?? 0,
      registrationTrend: (json['registrationTrend'] as List?)
              ?.map((item) => RegistrationTrendItemModel.fromJson(Map<String, dynamic>.from(item as Map)))
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
  final String userEmail;
  final String orderType;
  final double amount;
  final String status;
  final String? voucherCode;
  final DateTime createdAt;

  const RecentTransactionModel({
    required this.id,
    required this.userId,
    required this.userEmail,
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
      userEmail: json['userEmail']?.toString() ?? json['userId']?.toString() ?? '',
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

class AdminUserModel {
  final String id;
  final String email;
  final String fullName;
  final String? avatarUrl;
  final String role;
  final bool active;
  final bool premiumActive;
  final String? premiumPlan;
  final DateTime? premiumExpiredAt;
  final DateTime createdAt;

  const AdminUserModel({
    required this.id,
    required this.email,
    required this.fullName,
    this.avatarUrl,
    required this.role,
    required this.active,
    required this.premiumActive,
    this.premiumPlan,
    this.premiumExpiredAt,
    required this.createdAt,
  });

  factory AdminUserModel.fromJson(Map<String, dynamic> json) {
    return AdminUserModel(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      avatarUrl: json['avatarUrl']?.toString(),
      role: json['role']?.toString() ?? 'USER',
      active: json['active'] as bool? ?? true,
      premiumActive: json['premiumActive'] as bool? ?? false,
      premiumPlan: json['premiumPlan']?.toString(),
      premiumExpiredAt: json['premiumExpiredAt'] != null
          ? DateTime.parse(json['premiumExpiredAt'].toString())
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now(),
    );
  }
}

class PaginatedUserResponseModel {
  final List<AdminUserModel> content;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;
  final bool last;

  const PaginatedUserResponseModel({
    required this.content,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
    required this.last,
  });

  factory PaginatedUserResponseModel.fromJson(Map<String, dynamic> json) {
    final page = (json['page'] as num?)?.toInt() ?? 0;
    final size = (json['size'] as num?)?.toInt() ?? 20;
    final totalElements = (json['totalElements'] as num?)?.toInt() ?? 0;
    final totalPages = (json['totalPages'] as num?)?.toInt() ?? 0;
    final isLast = json['last'] as bool? ?? json['isLast'] as bool? ?? (page + 1 >= totalPages);

    return PaginatedUserResponseModel(
      content: (json['content'] as List?)
              ?.map((item) => AdminUserModel.fromJson(Map<String, dynamic>.from(item as Map)))
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

class VisitorLogModel {
  final String id;
  final String ip;
  final String os;
  final String browser;
  final String action;
  final String? location;
  final DateTime createdAt;

  const VisitorLogModel({
    required this.id,
    required this.ip,
    required this.os,
    required this.browser,
    required this.action,
    this.location,
    required this.createdAt,
  });

  factory VisitorLogModel.fromJson(Map<String, dynamic> json) {
    return VisitorLogModel(
      id: json['id']?.toString() ?? '',
      ip: json['ip']?.toString() ?? '',
      os: json['os']?.toString() ?? '',
      browser: json['browser']?.toString() ?? '',
      action: json['action']?.toString() ?? '',
      location: json['location']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now(),
    );
  }
}

class PaginatedVisitorLogResponseModel {
  final List<VisitorLogModel> content;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;
  final bool last;

  const PaginatedVisitorLogResponseModel({
    required this.content,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
    required this.last,
  });

  factory PaginatedVisitorLogResponseModel.fromJson(Map<String, dynamic> json) {
    final page = (json['page'] as num?)?.toInt() ?? 0;
    final size = (json['size'] as num?)?.toInt() ?? 20;
    final totalElements = (json['totalElements'] as num?)?.toInt() ?? 0;
    final totalPages = (json['totalPages'] as num?)?.toInt() ?? 0;
    final isLast = json['last'] as bool? ?? json['isLast'] as bool? ?? (page + 1 >= totalPages);

    return PaginatedVisitorLogResponseModel(
      content: (json['content'] as List?)
              ?.map((item) => VisitorLogModel.fromJson(Map<String, dynamic>.from(item as Map)))
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

class TrafficMetricsResponseModel {
  final int totalVisits;
  final PaginatedVisitorLogResponseModel logs;
  final Map<String, int> osStats;
  final Map<String, int> browserStats;

  const TrafficMetricsResponseModel({
    required this.totalVisits,
    required this.logs,
    required this.osStats,
    required this.browserStats,
  });

  factory TrafficMetricsResponseModel.fromJson(Map<String, dynamic> json) {
    final logsJson = json['logs'] != null
        ? Map<String, dynamic>.from(json['logs'] as Map)
        : <String, dynamic>{};
        
    final osStatsRaw = json['osStats'] != null
        ? Map<String, dynamic>.from(json['osStats'] as Map)
        : <String, dynamic>{};
        
    final browserStatsRaw = json['browserStats'] != null
        ? Map<String, dynamic>.from(json['browserStats'] as Map)
        : <String, dynamic>{};

    return TrafficMetricsResponseModel(
      totalVisits: (json['totalVisits'] as num?)?.toInt() ?? 0,
      logs: PaginatedVisitorLogResponseModel.fromJson(logsJson),
      osStats: osStatsRaw.map((key, value) => MapEntry(key, (value as num).toInt())),
      browserStats: browserStatsRaw.map((key, value) => MapEntry(key, (value as num).toInt())),
    );
  }
}

class SearchMetricItemModel {
  final String keyword;
  final int searchCount;

  const SearchMetricItemModel({
    required this.keyword,
    required this.searchCount,
  });

  factory SearchMetricItemModel.fromJson(Map<String, dynamic> json) {
    return SearchMetricItemModel(
      keyword: json['keyword']?.toString() ?? '',
      searchCount: (json['searchCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class RegistrationTrendItemModel {
  final String date;
  final int count;
  final int vipCount;
  final int freeCount;

  const RegistrationTrendItemModel({
    required this.date,
    required this.count,
    required this.vipCount,
    required this.freeCount,
  });

  factory RegistrationTrendItemModel.fromJson(Map<String, dynamic> json) {
    return RegistrationTrendItemModel(
      date: json['date']?.toString() ?? '',
      count: (json['count'] as num?)?.toInt() ?? 0,
      vipCount: (json['vipCount'] as num?)?.toInt() ?? 0,
      freeCount: (json['freeCount'] as num?)?.toInt() ?? 0,
    );
  }
}
