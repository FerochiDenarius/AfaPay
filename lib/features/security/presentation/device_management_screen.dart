import 'package:flutter/material.dart';

import '../models/device_session.dart';
import '../repositories/security_repository.dart';

const _gold = Color(0xFFF5B81F);
const _muted = Color(0xFFA9ABB2);

class DeviceManagementScreen extends StatefulWidget {
  const DeviceManagementScreen({super.key});

  @override
  State<DeviceManagementScreen> createState() => _DeviceManagementScreenState();
}

class _DeviceManagementScreenState extends State<DeviceManagementScreen> {
  late Future<List<DeviceSession>> _devices;

  @override
  void initState() {
    super.initState();
    _devices = SecurityRepository().fetchDevices();
  }

  Future<void> _remove(String deviceId) async {
    await SecurityRepository().removeDevice(deviceId);
    if (!mounted) return;
    setState(() => _devices = SecurityRepository().fetchDevices());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Active Devices')),
      body: FutureBuilder<List<DeviceSession>>(
        future: _devices,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator(color: _gold));
          }
          final devices = snapshot.data ?? const [];
          if (devices.isEmpty) {
            return const Center(
              child: Text('No active devices found.', style: TextStyle(color: _muted)),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(18),
            itemBuilder: (context, index) {
              final device = devices[index];
              return Card(
                color: const Color(0xFF081120),
                child: ListTile(
                  leading: const Icon(Icons.phone_android_rounded, color: _gold),
                  title: Text(device.deviceName),
                  subtitle: Text(
                    [
                      if (device.platform.isNotEmpty) device.platform,
                      if (device.osVersion.isNotEmpty) device.osVersion,
                      if (device.lastIp.isNotEmpty) device.lastIp,
                    ].join(' • '),
                    style: const TextStyle(color: _muted),
                  ),
                  trailing: IconButton(
                    tooltip: 'Remove device',
                    onPressed: () => _remove(device.deviceId),
                    icon: const Icon(Icons.logout_rounded, color: _gold),
                  ),
                ),
              );
            },
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemCount: devices.length,
          );
        },
      ),
    );
  }
}
