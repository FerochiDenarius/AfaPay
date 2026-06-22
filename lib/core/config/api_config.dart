class ApiConfig {
  const ApiConfig._();

  static const productionBaseUrl = 'https://afapay.xyz';

  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: productionBaseUrl,
  );

  static const useMockAuth = bool.fromEnvironment(
    'USE_MOCK_AUTH',
    defaultValue: false,
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
