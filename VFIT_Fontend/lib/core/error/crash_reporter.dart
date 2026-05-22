import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import '../config/environment.dart';

class CrashReporter {
  const CrashReporter._();

  static Future<void> record(Object error, StackTrace stackTrace) async {
    if (!Environment.enableCrashlytics) {
      if (kDebugMode) {
        debugPrint('CrashReporter disabled: $error');
      }
      return;
    }
    try {
      await FirebaseCrashlytics.instance.recordError(error, stackTrace);
    } catch (_) {
      // Firebase may be intentionally unconfigured in local/dev builds.
    }
  }
}
