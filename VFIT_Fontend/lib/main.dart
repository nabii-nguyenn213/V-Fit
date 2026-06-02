import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/network/network_providers.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'core/utils/responsive.dart';
import 'core/widgets/app_feedback.dart';
import 'features/auth/application/auth_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  final preferences = await SharedPreferences.getInstance();
  await _initializeSocialLogin();
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(preferences),
      ],
      child: const VFitApp(),
    ),
  );
}

Future<void> _initializeSocialLogin() async {
  const facebookAppId = String.fromEnvironment('FACEBOOK_APP_ID');
  if (!kIsWeb || facebookAppId.isEmpty) {
    return;
  }
  await FacebookAuth.i.webAndDesktopInitialize(
    appId: facebookAppId,
    cookie: true,
    xfbml: true,
    version: 'v19.0',
  );
}

class VFitApp extends ConsumerStatefulWidget {
  const VFitApp({super.key});

  @override
  ConsumerState<VFitApp> createState() => _VFitAppState();
}

class _VFitAppState extends ConsumerState<VFitApp> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(authControllerProvider.notifier).bootstrap(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeControllerProvider);
    return MaterialApp.router(
      title: 'V-FIT',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: appScaffoldMessengerKey,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
      builder: (context, child) {
        final media = MediaQuery.of(context);
        return ScrollConfiguration(
          behavior: const _VFitScrollBehavior(),
          child: MediaQuery(
            data: media.copyWith(
              textScaler: TextScaler.linear(
                AppResponsive.clampTextScale(
                  media.textScaler.scale(1),
                ),
              ),
            ),
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}

class _VFitScrollBehavior extends MaterialScrollBehavior {
  const _VFitScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics(
      parent: AlwaysScrollableScrollPhysics(),
    );
  }
}
