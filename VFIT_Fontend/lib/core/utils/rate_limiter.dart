import 'dart:async';

/// Rate limiter to prevent too many API calls
class RateLimiter {
  final int requestsPerSecond;
  final String name;
  
  DateTime? _lastResetTime;
  int _requestCount = 0;
  final List<DateTime> _requestTimestamps = [];

  RateLimiter({
    required this.requestsPerSecond,
    this.name = 'RateLimiter',
  });

  /// Check if a request is allowed
  /// Returns true if request can be made, false if rate limited
  bool allowRequest() {
    final now = DateTime.now();
    
    // Clean old timestamps (older than 1 second)
    _requestTimestamps.removeWhere(
      (time) => now.difference(time).inSeconds >= 1,
    );

    // Check if we can make another request
    if (_requestTimestamps.length < requestsPerSecond) {
      _requestTimestamps.add(now);
      return true;
    }

    return false;
  }

  /// Get time until next request is allowed
  Duration get nextAvailableTime {
    if (_requestTimestamps.isEmpty) {
      return Duration.zero;
    }

    // The oldest request in our window
    final oldestRequest = _requestTimestamps.first;
    final resetTime = oldestRequest.add(Duration(seconds: 1));
    final now = DateTime.now();

    if (now.isAfter(resetTime)) {
      return Duration.zero;
    }

    return resetTime.difference(now);
  }

  /// Get remaining requests in current window
  int get remainingRequests => requestsPerSecond - _requestTimestamps.length;

  /// Get current rate (requests per second)
  double getCurrentRate() {
    final now = DateTime.now();
    final recentRequests = _requestTimestamps
        .where((t) => now.difference(t).inSeconds < 1)
        .length;
    return recentRequests.toDouble();
  }

  /// Reset the rate limiter
  void reset() {
    _requestCount = 0;
    _requestTimestamps.clear();
    _lastResetTime = null;
  }

  @override
  String toString() {
    return '$name: ${getCurrentRate().toStringAsFixed(1)} req/s '
        '(${remainingRequests}/${requestsPerSecond} available)';
  }
}

/// Example usage class for food scanning
class FoodScanRateLimiter {
  static final _instance = FoodScanRateLimiter._internal();
  
  late final RateLimiter _limiter;

  factory FoodScanRateLimiter() {
    return _instance;
  }

  FoodScanRateLimiter._internal() {
    // Allow 2 scans per second
    _limiter = RateLimiter(requestsPerSecond: 2, name: 'FoodScan');
  }

  bool canScan() => _limiter.allowRequest();

  Duration get timeUntilNextScan => _limiter.nextAvailableTime;

  int get remainingScans => _limiter.remainingRequests;

  String get status => _limiter.toString();

  void reset() => _limiter.reset();
}

/// Utility class for WebSocket rate limiting
class WebSocketRateLimiter {
  static final _instance = WebSocketRateLimiter._internal();
  
  late final RateLimiter _frameLimiter;
  late final RateLimiter _messageLimiter;

  factory WebSocketRateLimiter() {
    return _instance;
  }

  WebSocketRateLimiter._internal() {
    // Allow frame sending at configured rate (e.g., 1 per second = 1 FPS)
    _frameLimiter = RateLimiter(requestsPerSecond: 1, name: 'WSFrames');
    // Allow control messages at higher rate
    _messageLimiter = RateLimiter(requestsPerSecond: 10, name: 'WSMessages');
  }

  bool canSendFrame() => _frameLimiter.allowRequest();

  bool canSendMessage() => _messageLimiter.allowRequest();

  Duration get timeUntilNextFrame => _frameLimiter.nextAvailableTime;

  Duration get timeUntilNextMessage => _messageLimiter.nextAvailableTime;

  String get frameStatus => _frameLimiter.toString();

  String get messageStatus => _messageLimiter.toString();

  void reset() {
    _frameLimiter.reset();
    _messageLimiter.reset();
  }
}

/// Exception thrown when rate limit is exceeded
class RateLimitException implements Exception {
  final String message;
  final Duration retryAfter;

  RateLimitException(this.message, {this.retryAfter = Duration.zero});

  @override
  String toString() => 'RateLimitException: $message (retry after $retryAfter)';
}

/// Utility to make API calls with rate limiting
class RateLimitedApiCall {
  static final _foodScanLimiter = FoodScanRateLimiter();

  /// Make a rate-limited food scan API call
  static Future<T> scanFood<T>(
    Future<T> Function() apiCall, {
    void Function()? onRateLimited,
  }) async {
    if (!_foodScanLimiter.canScan()) {
      onRateLimited?.call();
      throw RateLimitException(
        'Too many food scans. Wait ${_foodScanLimiter.timeUntilNextScan.inMilliseconds}ms',
        retryAfter: _foodScanLimiter.timeUntilNextScan,
      );
    }

    return apiCall();
  }

  /// Get current food scan rate
  static String getFoodScanStatus() => _foodScanLimiter.status;

  /// Check if can scan
  static bool canScanFood() => _foodScanLimiter.canScan();
}
