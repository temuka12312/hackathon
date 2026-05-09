class RegisterResponse {
  const RegisterResponse({required this.message});

  factory RegisterResponse.fromJson(Map<String, dynamic> json) {
    return RegisterResponse(
      message: json['message'] as String? ?? 'Хэрэглэгч бүртгэгдлээ.',
    );
  }

  final String message;
}
