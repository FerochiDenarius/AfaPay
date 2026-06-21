class OtpVerificationRequest {
  const OtpVerificationRequest({required this.userId, required this.otp});

  final String userId;
  final String otp;

  Map<String, dynamic> toJson() => {'userId': userId, 'otp': otp};
}
