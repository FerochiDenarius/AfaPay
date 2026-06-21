class EmailVerificationResponse {
  const EmailVerificationResponse({
    required this.success,
    required this.message,
    this.email,
  });

  final bool success;
  final String message;
  final String? email;

  factory EmailVerificationResponse.fromJson(Map<String, dynamic> json) {
    return EmailVerificationResponse(
      success: json['success'] == true,
      message: json['message'] as String? ?? 'Unable to process request',
      email: json['email'] as String?,
    );
  }
}
