import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../config/environment.dart';

/// Manages WebSocket connections with automatic token refresh support
class WebSocketManager {
  WebSocketChannel? _channel;
  String _authToken = '';
  String _path = '';
  Map<String, String> _queryParameters = {};
  bool _isConnecting = false;
  bool _isConnected = false;
  Timer? _heartbeatTimer;
  final int _heartbeatIntervalSeconds = 30;

  /// Stream controller for connection state changes
  final _connectionStateController = StreamController<bool>.broadcast();
  Stream<bool> get connectionStateStream => _connectionStateController.stream;

  /// Stream controller for receiving messages
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;

  /// Get connection status
  bool get isConnected => _isConnected;

  /// Connect to WebSocket with auth token
  Future<bool> connect({
    required String path,
    required String authToken,
    Map<String, String> queryParameters = const {},
    bool autoReconnect = true,
  }) async {
    try {
      if (_isConnecting || _isConnected) {
        return true;
      }

      _isConnecting = true;
      _authToken = authToken;
      _path = path;
      _queryParameters = queryParameters;

      // Build WebSocket URL
      final baseUrl = Environment.apiBaseUrl
          .replaceFirst('http', 'ws')
          .replaceFirst('https', 'wss');
      final queryString = _queryParameters.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');
      final url = '$baseUrl$path?token=$authToken${queryString.isNotEmpty ? '&$queryString' : ''}';

      // Connect
      _channel = WebSocketChannel.connect(Uri.parse(url));

      // Wait for connection
      await _channel!.ready;

      _isConnected = true;
      _isConnecting = false;

      // Start listening for messages
      _startListening();

      // Start heartbeat
      _startHeartbeat();

      // Notify listeners
      _connectionStateController.add(true);

      if (kDebugMode) {
        print('[WebSocket] Connected to $path');
      }

      return true;
    } catch (e) {
      _isConnected = false;
      _isConnecting = false;
      _connectionStateController.add(false);
      if (kDebugMode) {
        print('[WebSocket] Connection failed: $e');
      }
      return false;
    }
  }

  /// Send message through WebSocket
  void send(Map<String, dynamic> message) {
    if (!_isConnected || _channel == null) {
      if (kDebugMode) {
        print('[WebSocket] Cannot send: not connected');
      }
      return;
    }

    try {
      _channel!.sink.add(jsonEncode(message));
    } catch (e) {
      if (kDebugMode) {
        print('[WebSocket] Send error: $e');
      }
    }
  }

  /// Send binary data (for camera frames)
  void sendBinary(List<int> data) {
    if (!_isConnected || _channel == null) {
      return;
    }

    try {
      _channel!.sink.add(data);
    } catch (e) {
      if (kDebugMode) {
        print('[WebSocket] Binary send error: $e');
      }
    }
  }

  /// Refresh token and reconnect
  Future<bool> refreshTokenAndReconnect(String newToken) async {
    try {
      disconnect();
      await Future.delayed(const Duration(milliseconds: 500));

      return await connect(
        path: _path,
        authToken: newToken,
        queryParameters: _queryParameters,
      );
    } catch (e) {
      if (kDebugMode) {
        print('[WebSocket] Token refresh reconnect failed: $e');
      }
      return false;
    }
  }

  /// Start listening for messages
  void _startListening() {
    _channel?.stream.listen(
      (dynamic message) {
        try {
          if (message is String) {
            final decoded = jsonDecode(message) as Map<String, dynamic>;
            _messageController.add(decoded);
          }
        } catch (e) {
          if (kDebugMode) {
            print('[WebSocket] Message decode error: $e');
          }
        }
      },
      onError: (error) {
        if (kDebugMode) {
          print('[WebSocket] Stream error: $error');
        }
        _handleConnectionError();
      },
      onDone: () {
        if (kDebugMode) {
          print('[WebSocket] Connection closed');
        }
        _handleConnectionClosed();
      },
    );
  }

  /// Start heartbeat to keep connection alive
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(
      Duration(seconds: _heartbeatIntervalSeconds),
      (_) {
        if (_isConnected) {
          send({'type': 'ping'});
        }
      },
    );
  }

  /// Handle connection error
  void _handleConnectionError() {
    _isConnected = false;
    _connectionStateController.add(false);
  }

  /// Handle connection closed
  void _handleConnectionClosed() {
    _isConnected = false;
    _connectionStateController.add(false);
    _stopHeartbeat();
  }

  /// Stop heartbeat
  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  /// Disconnect from WebSocket
  Future<void> disconnect() async {
    _stopHeartbeat();
    _isConnected = false;

    try {
      await _channel?.sink.close();
    } catch (e) {
      if (kDebugMode) {
        print('[WebSocket] Disconnect error: $e');
      }
    }

    _channel = null;
    _connectionStateController.add(false);
  }

  /// Dispose resources
  void dispose() {
    disconnect();
    _connectionStateController.close();
    _messageController.close();
  }
}

/// Global WebSocket manager instance
final webSocketManager = WebSocketManager();
