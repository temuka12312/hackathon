class BackendResponse {
  const BackendResponse({
    required this.status,
    required this.message,
    required this.timestamp,
  });

  factory BackendResponse.fromJson(Map<String, dynamic> json) {
    return BackendResponse(
      status: json['status'] as String? ?? 'unknown',
      message: json['message'] as String? ?? 'No message',
      timestamp: json['timestamp'] as String? ?? '',
    );
  }

  final String status;
  final String message;
  final String timestamp;
}
