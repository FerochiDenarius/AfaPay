class EmailVerificationRequest {
  const EmailVerificationRequest({required this.userId, required this.email});

  final String userId;
  final String email;

  Map<String, dynamic> toJson() => {'userId': userId, 'email': email};
}
