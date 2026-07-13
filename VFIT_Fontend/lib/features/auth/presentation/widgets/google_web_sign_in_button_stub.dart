import 'package:flutter/widgets.dart';

class GoogleWebSignInButton extends StatelessWidget {
  const GoogleWebSignInButton({
    super.key,
    required this.loading,
    required this.onIdToken,
    required this.onError,
  });

  final bool loading;
  final Future<void> Function(String idToken) onIdToken;
  final void Function(String message) onError;

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
