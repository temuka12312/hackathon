class AuthResponse {
  const AuthResponse({required this.message, this.name, this.email});

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    final userMap = user is Map<String, dynamic> ? user : null;

    return AuthResponse(
      message: json['message'] as String? ?? 'Амжилттай.',
      name: userMap?['name'] as String?,
      email: userMap?['email'] as String?,
    );
  }

  final String message;
  final String? name;
  final String? email;
}
