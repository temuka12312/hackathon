class LoginResponse {
  const LoginResponse({
    required this.message,
    required this.name,
    required this.email,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>? ?? const {};

    return LoginResponse(
      message: json['message'] as String? ?? 'Амжилттай нэвтэрлээ.',
      name: user['name'] as String? ?? '',
      email: user['email'] as String? ?? '',
    );
  }

  final String message;
  final String name;
  final String email;
}
