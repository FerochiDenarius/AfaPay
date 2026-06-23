class DeviceSession {
  const DeviceSession({
    required this.deviceId,
    required this.deviceName,
    required this.platform,
    required this.osVersion,
    required this.lastLogin,
    required this.lastIp,
  });

  final String deviceId;
  final String deviceName;
  final String platform;
  final String osVersion;
  final DateTime? lastLogin;
  final String lastIp;

  factory DeviceSession.fromJson(Map<String, dynamic> json) {
    return DeviceSession(
      deviceId: json['deviceId']?.toString() ?? '',
      deviceName: json['deviceName']?.toString() ?? 'Unknown device',
      platform: json['platform']?.toString() ?? '',
      osVersion: json['osVersion']?.toString() ?? '',
      lastLogin: DateTime.tryParse(json['lastLogin']?.toString() ?? ''),
      lastIp: json['lastIp']?.toString() ?? '',
    );
  }
}
