import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authLogoutSignalProvider = Provider<AuthLogoutSignal>((ref) {
  final signal = AuthLogoutSignal();
  ref.onDispose(signal.dispose);
  return signal;
});

class AuthLogoutSignal {
  final _controller = StreamController<void>.broadcast();

  Stream<void> get onLogout => _controller.stream;

  void triggerLogout() {
    _controller.add(null);
  }

  void dispose() {
    _controller.close();
  }
}
