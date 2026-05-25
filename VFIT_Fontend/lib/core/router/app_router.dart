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
import '../../features/home/presentation/pages/home_page.dart';

import '../../features/nutrition/presentation/pages/nutrition_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/profile/presentation/pages/change_password_page.dart';
import '../../features/profile/presentation/pages/edit_profile_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/progress/presentation/pages/progress_page.dart';
import '../../features/workout/presentation/pages/exercise_detail_page.dart';
import '../../features/workout/presentation/pages/exercises_page.dart';
import '../../features/workout/presentation/pages/workout_detail_page.dart';
import '../../features/workout/presentation/pages/workout_page.dart';
import '../utils/enum_parsers.dart';
import '../widgets/app_shell.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authControllerProvider);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/splash',
    redirect: (context, state) {
      final path = state.uri.path;
      final isSplash = path == '/splash';
      final isAuthRoute = {
        '/login',
        '/register',
        '/register-otp',
        '/forgot-password',
        '/reset-password',
      }.contains(path);
      final isOnboardingRoute = path == '/onboarding';
      final isPublicExerciseRoute = path == '/workouts' ||
          path.startsWith('/workouts/') ||
          path == '/exercises' ||
          path.startsWith('/exercises/');
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
        return auth.isPendingOnboarding ? '/onboarding' : '/home';
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
