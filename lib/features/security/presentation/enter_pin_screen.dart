import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../repositories/security_repository.dart';

const _gold = Color(0xFFF5B81F);

class EnterPinScreen extends StatefulWidget {
  const EnterPinScreen({super.key});

  @override
  State<EnterPinScreen> createState() => _EnterPinScreenState();
}

class _EnterPinScreenState extends State<EnterPinScreen> {
  final _controller = TextEditingController();
  bool _loading = false;
  String _pin = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (_loading || _pin.length < 4) return;
    setState(() => _loading = true);
    try {
      await SecurityRepository().reauthenticateWithPin(_pin);
      if (!mounted) return;
      context.go('/dashboard');
    } on SecurityException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.55),
            radius: 1.2,
            colors: [Color(0xFF071735), Color(0xFF020712), Color(0xFF01040B)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.lock_open_rounded, color: _gold, size: 72),
                    const SizedBox(height: 24),
                    const Text(
                      'Enter PIN',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 28),
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
                        letterSpacing: 14,
                        fontWeight: FontWeight.w800,
                      ),
                      onChanged: (value) => setState(() => _pin = value),
                      onSubmitted: (_) => _verify(),
                      decoration: const InputDecoration(hintText: '••••'),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      height: 58,
                      child: FilledButton(
                        onPressed: _pin.length >= 4 && !_loading
                            ? _verify
                            : null,
                        style: FilledButton.styleFrom(
                          backgroundColor: _gold,
                          foregroundColor: Colors.black,
                        ),
                        child: _loading
                            ? const CircularProgressIndicator(
                                color: Colors.black,
                              )
                            : const Text(
                                'Unlock',
                                style: TextStyle(
                                  fontSize: 18,
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
}
