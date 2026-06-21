import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

const _gold = Color(0xFFF5B81F);

class PinSetupScreen extends StatefulWidget {
  const PinSetupScreen({super.key, required this.userId});

  final String userId;

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  final _controller = TextEditingController();
  String _pin = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
                  children: [
                    const Spacer(),
                    const Icon(
                      Icons.lock_outline_rounded,
                      color: _gold,
                      size: 70,
                    ),
                    const SizedBox(height: 25),
                    const Text(
                      'Create Your PIN',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'A 4-digit PIN is required to secure transactions.',
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
                        LengthLimitingTextInputFormatter(4),
                      ],
                      style: const TextStyle(
                        fontSize: 28,
                        letterSpacing: 22,
                        fontWeight: FontWeight.w800,
                      ),
                      onChanged: (value) => setState(() => _pin = value),
                      decoration: const InputDecoration(hintText: '••••'),
                    ),
                    const Spacer(flex: 2),
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: FilledButton(
                        onPressed: _pin.length == 4
                            ? () => context.go(
                                '/email-verification',
                                extra: <String, String>{
                                  'userId': widget.userId,
                                },
                              )
                            : null,
                        style: FilledButton.styleFrom(
                          backgroundColor: _gold,
                          foregroundColor: Colors.black,
                          disabledBackgroundColor: const Color(0xFF5B4C24),
                        ),
                        child: const Text(
                          'Continue',
                          style: TextStyle(
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
}
