import 'package:flutter/material.dart';

import 'registration_screen.dart';

const _gold = Color(0xFFF2A900);
const _muted = Color(0xFFA9ABB2);
const _field = Color(0xFF0B111D);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.7),
            radius: 1.15,
            colors: [Color(0xFF071735), Color(0xFF020712), Color(0xFF01040B)],
            stops: [0, 0.48, 1],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 30),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  children: [
                    const _BrandHeader(),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: _LoginForm(
                        obscurePassword: _obscurePassword,
                        onTogglePassword: () => setState(
                          () => _obscurePassword = !_obscurePassword,
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

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.32,
      child: ClipRect(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final imageWidth = constraints.maxWidth;
            return Stack(
              fit: StackFit.expand,
              children: [
                Positioned(
                  top: -imageWidth * 0.095,
                  left: 0,
                  right: 0,
                  child: Image.asset(
                    'UIdesignImages/loginPage.png',
                    width: imageWidth,
                    fit: BoxFit.fitWidth,
                    alignment: Alignment.topCenter,
                  ),
                ),
                const Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.transparent,
                          Color(0xFF020712),
                        ],
                        stops: [0, 0.86, 1],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _LoginForm extends StatelessWidget {
  const _LoginForm({
    required this.obscurePassword,
    required this.onTogglePassword,
  });

  final bool obscurePassword;
  final VoidCallback onTogglePassword;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Welcome Back!',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 27, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        const Text(
          'Login to your AFA account',
          textAlign: TextAlign.center,
          style: TextStyle(color: _muted, fontSize: 18),
        ),
        const SizedBox(height: 28),
        const _FieldLabel('Email or Phone Number'),
        const SizedBox(height: 8),
        const TextField(
          keyboardType: TextInputType.emailAddress,
          style: TextStyle(fontSize: 17),
          decoration: InputDecoration(
            hintText: 'Enter email or phone number',
            prefixIcon: Icon(Icons.person_outline_rounded),
          ),
        ),
        const SizedBox(height: 20),
        const _FieldLabel('Password'),
        const SizedBox(height: 8),
        TextField(
          obscureText: obscurePassword,
          style: const TextStyle(fontSize: 17),
          decoration: InputDecoration(
            hintText: 'Enter your password',
            prefixIcon: const Icon(Icons.lock_outline_rounded),
            suffixIcon: IconButton(
              tooltip: obscurePassword ? 'Show password' : 'Hide password',
              onPressed: onTogglePassword,
              icon: Icon(
                obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {},
            child: const Text(
              'Forgot Password?',
              style: TextStyle(color: _gold, fontSize: 16),
            ),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 58,
          child: FilledButton(
            onPressed: () {},
            style: FilledButton.styleFrom(
              backgroundColor: _gold,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'Login',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
          ),
        ),
        const SizedBox(height: 28),
        const _SectionDivider(),
        const SizedBox(height: 22),
        const Row(
          children: [
            Expanded(
              child: _SocialButton(icon: _GoogleMark(), label: 'Google'),
            ),
            SizedBox(width: 10),
            Expanded(
              child: _SocialButton(
                icon: Icon(Icons.apple, size: 34, color: Color(0xFFE4E5E8)),
                label: 'Apple',
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: _SocialButton(icon: _FacebookMark(), label: 'Facebook'),
            ),
            SizedBox(width: 10),
            Expanded(
              child: _SocialButton(
                icon: Icon(Icons.phone_outlined, size: 31, color: _gold),
                label: 'Phone',
              ),
            ),
          ],
        ),
        const SizedBox(height: 30),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Flexible(
              child: Text(
                "Don't have an account? ",
                style: TextStyle(color: _muted, fontSize: 16),
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const RegistrationScreen()),
                );
              },
              child: const Text(
                'Sign Up',
                style: TextStyle(
                  color: _gold,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: Divider(color: Color(0xFF353945))),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'or continue with',
            style: TextStyle(color: _muted, fontSize: 15),
          ),
        ),
        Expanded(child: Divider(color: Color(0xFF353945))),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({required this.icon, required this.label});

  final Widget icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(15),
      child: Container(
        height: 94,
        decoration: BoxDecoration(
          color: _field.withValues(alpha: 0.78),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color(0xFF303541)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: const TextStyle(color: _muted, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'G',
      style: TextStyle(
        color: Color(0xFF4285F4),
        fontSize: 31,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _FacebookMark extends StatelessWidget {
  const _FacebookMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.bottomCenter,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFF1877F2),
      ),
      child: const Text(
        'f',
        style: TextStyle(
          height: 1.08,
          color: Colors.white,
          fontSize: 32,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
