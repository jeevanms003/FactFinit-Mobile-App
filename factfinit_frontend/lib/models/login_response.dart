// lib/models/login_response.dart
class LoginResponse {
  final String message;
  final String? token;
  final String? error;

  LoginResponse({required this.message, this.token, this.error});

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      message: json['message'] ?? '',
      token: json['token'],
      error: json['error'],
    );
  }
}