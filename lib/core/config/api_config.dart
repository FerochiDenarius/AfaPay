class ApiConfig {
  const ApiConfig._();

  static const productionBaseUrl = 'https://afapay.xyz';

  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8080',
  );

  static const useMockAuth = bool.fromEnvironment(
    'USE_MOCK_AUTH',
    defaultValue: true,
  );

  static const requireEmailVerification = bool.fromEnvironment(
    'REQUIRE_EMAIL_VERIFICATION',
    defaultValue: true,
  );

  static const initialRoute = String.fromEnvironment(
    'INITIAL_ROUTE',
    defaultValue: '/register',
  );
}
