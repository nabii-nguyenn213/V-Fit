class ApiEndpoints {
  const ApiEndpoints._();

  static const appConfig = '/api/app/config';

  static const register = '/api/auth/register';
  static const verifyOtp = '/api/auth/verify-otp';
  static const resendOtp = '/api/auth/resend-otp';
  static const login = '/api/auth/login';
  static const socialLogin = '/api/auth/social-login';
  static const refreshToken = '/api/auth/refresh-token';
  static const logout = '/api/auth/logout';
  static const forgotPassword = '/api/auth/forgot-password';
  static const resetPassword = '/api/auth/reset-password';

  static const userSessions = '/api/users/sessions';
  static String userSession(String id) => '/api/users/sessions/$id';

  static const me = '/api/users/me';
  static const deleteAccount = '/api/users/me';
  static const onboardingProfile = '/api/v1/users/onboarding/profile';
  static const onboardingBodyScan = '/api/v1/users/onboarding';
  static const onboardingRealtime = '/api/v1/users/onboarding/realtime';
  static const avatar = '/api/users/me/avatar';
  static const changePassword = '/api/users/change-password';
  static const bodyMetrics = '/api/users/me/body-metrics';

  static const exercises = '/api/exercises';
  static const groupedExercises = '/api/v1/exercises/grouped';
  static String exercise(String id) => '/api/exercises/$id';

  static const workouts = '/api/workouts';
  static String workout(String id) => '/api/workouts/$id';
  static const personalizedWorkout = '/api/v1/workouts/personalized';

  static const badges = '/api/gamification/badges';
  static const challenges = '/api/gamification/challenges';

  static const progressSnaps = '/api/progress/snaps';
  static String progressSnap(String id) => '/api/progress/snaps/$id';

  static const aiCoach = '/api/ai/coach';
  static const aiWorkoutPlanner = '/api/ai/workout-planner';
  static const aiMealPlanner = '/api/ai/meal-planner';
  static const foodCalorieEstimate = '/api/ai/food-calorie-estimate';
  static const foodSearch = '/api/v1/foods/search';

  static const applyVoucher = '/api/v1/payments/apply-voucher';
  static const checkout = '/api/v1/payments/checkout';
  static const createPremiumPayment = '/api/payments/create';
  static const vipStatus = '/api/payments/vip-status';
  static String premiumPaymentStatus(String id) => '/api/payments/$id/status';
  static const checkin = '/api/v1/checkin';
  static const checkinStatus = '/api/v1/checkin/status';

  static const adminDashboard = '/api/admin/dashboard';
  static const adminUsers = '/api/admin/users';
  static const adminRevenue = '/api/v1/admin/revenue/monthly';
  static const adminRevenueTransactions = '/api/v1/admin/revenue/transactions';
}
