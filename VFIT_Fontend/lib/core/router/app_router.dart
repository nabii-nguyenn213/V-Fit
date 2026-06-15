import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/presentation/pages/admin_page.dart';
import '../../features/admin_dashboard/presentation/pages/admin_revenue_screen.dart';
import '../../features/auth/application/auth_controller.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/register_otp_page.dart';
import '../../features/auth/presentation/pages/reset_password_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/auth/presentation/pages/deactivated_page.dart';
import '../../features/ai/presentation/pages/ai_body_analysis_page.dart';
import '../../features/ai/presentation/pages/ai_form_check_page.dart';
import '../../features/ai/presentation/pages/ai_coach_page.dart';
import '../../features/home/presentation/pages/home_page.dart';

import '../../features/nutrition/presentation/pages/nutrition_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/onboarding/presentation/pages/ai_onboarding_body_scan_page.dart';
import '../../features/profile/presentation/pages/change_password_page.dart';
import '../../features/profile/presentation/pages/edit_profile_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/progress/presentation/pages/progress_page.dart';
import '../../features/workout/presentation/pages/exercise_detail_page.dart';
import '../../features/workout/presentation/pages/exercises_page.dart';
import '../../features/workout/presentation/pages/workout_detail_page.dart';
import '../../features/workout/presentation/pages/workout_page.dart';
import 'app_routes.dart';
import '../utils/enum_parsers.dart';
import '../widgets/app_shell.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

final _authRefreshListenable = Provider<_AuthRefreshNotifier>((ref) {
  final notifier = _AuthRefreshNotifier();
  ref.listen<AuthState>(authControllerProvider, (previous, next) {
    // Only trigger router refresh when actual auth status changes
    if (previous?.status != next.status) {
      notifier.notify();
    }
  });
  return notifier;
});

class _AuthRefreshNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = ref.watch(_authRefreshListenable);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final path = state.uri.path;
      final isSplash = path == '/splash';
      final isAuthRoute = {
        '/login',
        '/register',
        '/register-otp',
        '/forgot-password',
        '/reset-password',
      }.contains(path);
      final isOnboardingRoute = path == '/onboarding' || path == '/onboarding/body-scan-realtime';
      final isProtectedRoute = path.startsWith('/profile/edit') ||
          path.startsWith('/profile/change-password') ||
          path.startsWith('/admin');

      if (auth.status == AuthStatus.initial) {
        return isSplash ? null : '/splash';
      }

      if (auth.isAuthenticated && auth.user?.role == RoleName.admin) {
        if (!path.startsWith('/admin')) {
          return '/admin/revenue';
        }
        return null;
      }

      if (!auth.isAuthenticated && (isProtectedRoute || isOnboardingRoute)) {
        return '/register';
      }

      if (auth.isAuthenticated && isAuthRoute) {
        return auth.isPendingOnboarding ? '/onboarding' : '/home';
      }

      if (auth.isActive && isOnboardingRoute) {
        return '/home';
      }

      if (isSplash) {
        if (auth.isPendingOnboarding) {
          return '/onboarding';
        }
        if (auth.isActive) {
          return '/home';
        }
        return '/login';
      }

      if (path.startsWith('/admin') && auth.user?.role != RoleName.admin) {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashPage()),
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(
        path: '/deactivated',
        builder: (context, state) => const DeactivatedPage(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/register-otp',
        builder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          return RegisterOtpPage(email: email);
        },
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) => const ResetPasswordPage(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: '/onboarding/body-scan-realtime',
        builder: (context, state) => const AiOnboardingBodyScanPage(),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/home', builder: (context, state) => const HomePage()),
          GoRoute(
            path: '/workouts',
            builder: (context, state) => const WorkoutPage(),
          ),
          GoRoute(
            path: '/nutrition',
            builder: (context, state) => const NutritionPage(),
          ),
          GoRoute(
            path: '/progress',
            builder: (context, state) => const ProgressPage(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfilePage(),
          ),
          GoRoute(
            path: '/premium',
            builder: (context, state) => const ProfilePage(),
          ),
        ],
      ),
      GoRoute(
        path: '/workouts/:id',
        builder: (context, state) =>
            WorkoutDetailPage(id: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/exercises',
        builder: (context, state) => const ExercisesPage(),
      ),
      GoRoute(
        path: AppRoutes.aiFormCheck,
        builder: (context, state) => AiFormCheckPage(
          exerciseId: state.uri.queryParameters['exerciseId'] ?? 'general',
        ),
      ),
      GoRoute(
        path: AppRoutes.aiBodyAnalysis,
        builder: (context, state) => const AiBodyAnalysisPage(),
      ),
      GoRoute(
        path: AppRoutes.aiCoach,
        builder: (context, state) {
          final tabStr = state.uri.queryParameters['tab'];
          final initialTab = tabStr != null ? int.tryParse(tabStr) ?? 0 : 0;
          return AiCoachPage(initialTab: initialTab);
        },
      ),
      GoRoute(
        path: '/exercises/:id',
        builder: (context, state) =>
            ExerciseDetailPage(id: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/profile/edit',
        builder: (context, state) => const EditProfilePage(),
      ),
      GoRoute(
        path: '/profile/change-password',
        builder: (context, state) => const ChangePasswordPage(),
      ),
      GoRoute(path: '/admin', builder: (context, state) => const AdminPage()),
      GoRoute(
        path: '/admin/revenue',
        builder: (context, state) => const AdminRevenueScreen(),
      ),
    ],
  );
});
