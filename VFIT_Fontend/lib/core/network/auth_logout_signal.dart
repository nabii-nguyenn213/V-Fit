import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authLogoutSignalProvider = Provider<AuthLogoutSignal>((ref) {
  return AuthLogoutSignal();
});

class AuthLogoutSignal {
  final _controller = StreamController<void>.broadcast();

  Stream<void> get onLogout => _controller.stream;

  void triggerLogout() {
    _controller.add(null);
  }
}
