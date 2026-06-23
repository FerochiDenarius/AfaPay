import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../security/repositories/security_repository.dart';

const _gold = Color(0xFFF5B81F);

class PinSetupScreen extends StatefulWidget {
  const PinSetupScreen({super.key, required this.userId, this.email = ''});

  final String userId;
  final String email;

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  final _controller = TextEditingController();
  String _pin = '';
  String? _firstPin;
  bool _loading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isConfirming = _firstPin != null;
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
                  children: [
                    const Spacer(),
                    const Icon(
                      Icons.lock_outline_rounded,
                      color: _gold,
                      size: 70,
                    ),
                    const SizedBox(height: 25),
                    Text(
                      isConfirming ? 'Confirm Your PIN' : 'Create Your PIN',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'A 4-6 digit PIN is required for app unlock and money actions.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFFA9ABB2), fontSize: 16),
                    ),
                    const SizedBox(height: 36),
                    TextField(
                      controller: _controller,
                      autofocus: true,
                      obscureText: true,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(6),
                      ],
                      style: const TextStyle(
                        fontSize: 28,
                        letterSpacing: 22,
                        fontWeight: FontWeight.w800,
                      ),
                      onChanged: (value) => setState(() => _pin = value),
                      onSubmitted: (_) => _continue(),
                      decoration: const InputDecoration(hintText: '••••'),
                    ),
                    const Spacer(flex: 2),
                    SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: FilledButton(
                        onPressed: _pin.length >= 4 && !_loading
                            ? _continue
                            : null,
                        style: FilledButton.styleFrom(
                          backgroundColor: _gold,
                          foregroundColor: Colors.black,
                          disabledBackgroundColor: const Color(0xFF5B4C24),
                        ),
                        child: _loading
                            ? const CircularProgressIndicator(color: Colors.black)
                            : Text(
                                isConfirming ? 'Save PIN' : 'Continue',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                      ),
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

  Future<void> _continue() async {
    if (_pin.length < 4 || _loading) return;
    if (_firstPin == null) {
      setState(() {
        _firstPin = _pin;
        _pin = '';
        _controller.clear();
      });
      return;
    }
    if (_pin != _firstPin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PINs do not match. Try again.')),
      );
      setState(() {
        _firstPin = null;
        _pin = '';
        _controller.clear();
      });
      return;
    }
    setState(() => _loading = true);
    try {
      await SecurityRepository().setupPin(_pin);
      if (!mounted) return;
      context.go('/enable-biometrics');
    } on SecurityException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
