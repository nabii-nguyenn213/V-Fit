import '../../../profile/data/models/user_model.dart';

class LoginRequest {
  const LoginRequest({required this.email, required this.password});

  final String email;
  final String password;

  Map<String, dynamic> toJson() => {
        'email': email.trim(),
        'password': password,
      };
}

class RegisterRequest {
  const RegisterRequest({
    required this.email,
    required this.password,
    required this.fullName,
  });

  final String email;
  final String password;
  final String fullName;

  Map<String, dynamic> toJson() => {
        'email': email.trim(),
        'password': password,
        'fullName': fullName.trim(),
      };
}

class TokenResponse {
  const TokenResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.expiresInMs,
  });

  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final int expiresInMs;

  factory TokenResponse.fromJson(Map<String, dynamic> json) {
    return TokenResponse(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      tokenType: json['tokenType']?.toString() ?? 'Bearer',
      expiresInMs: (json['expiresInMs'] as num).toInt(),
    );
  }
}

class AuthResponse {
  const AuthResponse({required this.user, required this.tokens});

  final UserModel user;
  final TokenResponse tokens;

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      user: UserModel.fromJson(Map<String, dynamic>.from(json['user'] as Map)),
      tokens: TokenResponse.fromJson(
          Map<String, dynamic>.from(json['tokens'] as Map)),
    );
  }
}
