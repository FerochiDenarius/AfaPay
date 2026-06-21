class RegisterRequest {
  const RegisterRequest({
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.country,
    required this.phoneNumber,
    required this.email,
    required this.password,
  });

  final String firstName;
  final String lastName;
  final String username;
  final String country;
  final String phoneNumber;
  final String email;
  final String password;

  Map<String, dynamic> toJson() => {
    'firstName': firstName,
    'lastName': lastName,
    'username': username,
    'country': country,
    'phoneNumber': phoneNumber,
    'email': email,
    'password': password,
  };
}
