class OtpVerificationResponse {
  const OtpVerificationResponse({
    required this.success,
    required this.verified,
    this.nextStep,
    this.message,
  });

  final bool success;
  final bool verified;
  final String? nextStep;
  final String? message;

  factory OtpVerificationResponse.fromJson(Map<String, dynamic> json) {
    return OtpVerificationResponse(
      success: json['success'] == true,
      verified: json['verified'] == true,
      nextStep: json['nextStep'] as String?,
      message: json['message'] as String?,
    );
  }
}
