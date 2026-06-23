import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../repositories/security_repository.dart';

const _gold = Color(0xFFF5B81F);
const _muted = Color(0xFFA9ABB2);

class EnableBiometricsScreen extends StatefulWidget {
  const EnableBiometricsScreen({super.key});

  @override
  State<EnableBiometricsScreen> createState() => _EnableBiometricsScreenState();
}

class _EnableBiometricsScreenState extends State<EnableBiometricsScreen> {
  bool _loading = false;

  Future<void> _setBiometrics(bool enabled) async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      await SecurityRepository().setBiometricsEnabled(enabled);
      if (!mounted) return;
      context.go('/dashboard');
    } on SecurityException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.55),
            radius: 1.2,
            colors: [Color(0xFF071735), Color(0xFF020712), Color(0xFF01040B)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 34, 28, 28),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.fingerprint_rounded, color: _gold, size: 84),
                    const SizedBox(height: 24),
                    const Text(
                      'Enable Biometrics',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Use fingerprint or face unlock for app reopen and transaction checks. PIN remains the fallback.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: _muted, fontSize: 16, height: 1.4),
                    ),
                    const SizedBox(height: 34),
                    SizedBox(
                      height: 58,
                      child: FilledButton(
                        onPressed: _loading ? null : () => _setBiometrics(true),
                        style: FilledButton.styleFrom(
                          backgroundColor: _gold,
                          foregroundColor: Colors.black,
                        ),
                        child: _loading
                            ? const CircularProgressIndicator(color: Colors.black)
                            : const Text(
                                'Enable Biometrics',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                              ),
                      ),
                    ),
                    TextButton(
                      onPressed: _loading ? null : () => _setBiometrics(false),
                      child: const Text('Skip for now', style: TextStyle(color: _gold)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
