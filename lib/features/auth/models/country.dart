class Country {
  const Country({
    required this.name,
    required this.dialCode,
    required this.flag,
    required this.localNumberLength,
  });

  final String name;
  final String dialCode;
  final String flag;
  final int localNumberLength;

  String get displayName => '$name ($dialCode)';
}

const supportedCountries = <Country>[
  Country(name: 'Ghana', dialCode: '+233', flag: '🇬🇭', localNumberLength: 9),
  Country(
    name: 'Nigeria',
    dialCode: '+234',
    flag: '🇳🇬',
    localNumberLength: 10,
  ),
  Country(name: 'Kenya', dialCode: '+254', flag: '🇰🇪', localNumberLength: 9),
  Country(
    name: 'South Africa',
    dialCode: '+27',
    flag: '🇿🇦',
    localNumberLength: 9,
  ),
  Country(
    name: 'Cameroon',
    dialCode: '+237',
    flag: '🇨🇲',
    localNumberLength: 9,
  ),
  Country(
    name: 'Senegal',
    dialCode: '+221',
    flag: '🇸🇳',
    localNumberLength: 9,
  ),
];
