import 'dart:async';
import 'package:flutter/foundation.dart';

/// Configuration for retry behavior
class RetryConfig {
  final int maxAttempts;
  final Duration initialDelay;
  final Duration maxDelay;
  final double delayMultiplier;
  final bool retryOnTimeout;

  const RetryConfig({
    this.maxAttempts = 3,
    this.initialDelay = const Duration(milliseconds: 500),
    this.maxDelay = const Duration(seconds: 10),
    this.delayMultiplier = 2.0,
    this.retryOnTimeout = true,
  });
}

/// Helper class for implementing retry logic with exponential backoff
class RetryHelper {
  /// Default retry configuration
  static const defaultConfig = RetryConfig(
    maxAttempts: 3,
    initialDelay: Duration(milliseconds: 500),
    maxDelay: Duration(seconds: 10),
    delayMultiplier: 2.0,
    retryOnTimeout: true,
  );

  /// Retry a function with exponential backoff
  /// 
  /// Example:
  /// ```dart
  /// final result = await RetryHelper.retry(
  ///   () => apiClient.post('/endpoint'),
  ///   config: RetryConfig(maxAttempts: 5),
  ///   onRetry: (attempt, error, delay) {
  ///     print('Attempt $attempt failed: $error, retrying in $delay');
  ///   },
  /// );
  /// ```
  static Future<T> retry<T>(
    Future<T> Function() operation, {
    RetryConfig config = defaultConfig,
    void Function(int attempt, dynamic error, Duration delay)? onRetry,
    bool Function(dynamic error)? shouldRetry,
  }) async {
    Duration delay = config.initialDelay;
    
    for (int attempt = 1; attempt <= config.maxAttempts; attempt++) {
      try {
        if (kDebugMode) {
          print('[Retry] Attempt $attempt/${config.maxAttempts}');
        }
        return await operation();
      } catch (error) {
        // Check if we should retry this error
        if (shouldRetry != null && !shouldRetry(error)) {
          rethrow;
        }

        // Check if we've exhausted retries
        if (attempt >= config.maxAttempts) {
          if (kDebugMode) {
            print('[Retry] Max attempts reached. Final error: $error');
          }
          rethrow;
        }

        // Calculate next delay (exponential backoff)
        final nextDelay = Duration(
          milliseconds: (delay.inMilliseconds * config.delayMultiplier).toInt(),
        );
        final cappedDelay = nextDelay.inMilliseconds > config.maxDelay.inMilliseconds
            ? config.maxDelay
            : nextDelay;

        if (kDebugMode) {
          print('[Retry] Attempt $attempt failed: $error');
          print('[Retry] Retrying in ${cappedDelay.inMilliseconds}ms...');
        }

        onRetry?.call(attempt, error, cappedDelay);

        // Wait before retrying
        await Future.delayed(cappedDelay);
        delay = cappedDelay;
      }
    }

    // Should not reach here
    throw Exception('Retry logic error');
  }

  /// Retry a function with custom conditions
  static Future<T> retryWhen<T>(
    Future<T> Function() operation,
    bool Function(dynamic error) shouldRetry, {
    RetryConfig config = defaultConfig,
    void Function(int attempt, dynamic error, Duration delay)? onRetry,
  }) async {
    return retry(
      operation,
      config: config,
      onRetry: onRetry,
      shouldRetry: shouldRetry,
    );
  }

  /// Retry a function but give up after a certain duration
  static Future<T> retryWithTimeout<T>(
    Future<T> Function() operation,
    Duration timeout, {
    RetryConfig config = defaultConfig,
    void Function(int attempt, dynamic error, Duration delay)? onRetry,
  }) async {
    final startTime = DateTime.now();

    return retry(
      () async {
        final elapsed = DateTime.now().difference(startTime);
        if (elapsed.inMilliseconds > timeout.inMilliseconds) {
          throw TimeoutException(
            'Retry timeout exceeded after $elapsed',
          );
        }
        return operation();
      },
      config: config,
      onRetry: onRetry,
    );
  }
}

/// Extension for easier retry usage on Future
extension RetryExtension<T> on Future<T> Function() {
  /// Example:
  /// ```dart
  /// final result = (() => apiClient.get('/users'))
  ///   .withRetry(maxAttempts: 3);
  /// ```
  Future<T> withRetry({
    int maxAttempts = 3,
    Duration initialDelay = const Duration(milliseconds: 500),
    Duration maxDelay = const Duration(seconds: 10),
  }) async {
    return RetryHelper.retry(
      this,
      config: RetryConfig(
        maxAttempts: maxAttempts,
        initialDelay: initialDelay,
        maxDelay: maxDelay,
      ),
    );
  }
}
