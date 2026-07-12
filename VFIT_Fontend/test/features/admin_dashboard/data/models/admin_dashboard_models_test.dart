import 'package:flutter_test/flutter_test.dart';
import 'package:vfit_frontend/features/admin_dashboard/data/models/admin_dashboard_models.dart';

void main() {
  group('RecentTransactionModel', () {
    test('maps the normalized admin OrderDto contract without losing VIP data',
        () {
      final transaction = RecentTransactionModel.fromJson({
        'id': 'payment-001',
        'userId': 'user-001',
        'userEmail': 'vip@example.com',
        'orderType': 'VIP_YEARLY',
        'amount': 1500000,
        'status': 'SUCCESS',
        'voucherCode': 'VIP50',
        'createdAt': '2026-07-12T10:30:00Z',
      });

      expect(transaction.id, 'payment-001');
      expect(transaction.userId, 'user-001');
      expect(transaction.userEmail, 'vip@example.com');
      expect(transaction.orderType, 'VIP_YEARLY');
      expect(transaction.amount, 1500000.0);
      expect(transaction.status, 'SUCCESS');
      expect(transaction.voucherCode, 'VIP50');
      expect(transaction.createdAt, DateTime.utc(2026, 7, 12, 10, 30));
    });

    test('keeps the user id as the email fallback for legacy revenue rows', () {
      final transaction = RecentTransactionModel.fromJson({
        'id': 'legacy-order',
        'userId': 'legacy-user',
        'amount': 150000,
        'createdAt': '2026-05-26T00:34:00Z',
      });

      expect(transaction.userEmail, 'legacy-user');
      expect(transaction.orderType, 'PREMIUM');
      expect(transaction.status, 'SUCCESS');
    });
  });

  test('AdminUserModel maps the id used to request VIP history', () {
    final user = AdminUserModel.fromJson({
      'id': 'vip-user-001',
      'email': 'vip@example.com',
      'fullName': 'Khach VIP',
      'role': 'USER',
      'active': true,
      'premiumActive': true,
      'premiumPlan': 'VIP_MONTHLY',
      'premiumExpiredAt': '2026-08-12T10:30:00Z',
      'createdAt': '2026-06-15T00:00:00Z',
    });

    expect(user.id, 'vip-user-001');
    expect(user.premiumActive, isTrue);
    expect(user.premiumPlan, 'VIP_MONTHLY');
  });
}
