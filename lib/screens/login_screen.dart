import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/services/auth_service.dart';

const _gold = Color(0xFFF2A900);
const _muted = Color(0xFFA9ABB2);
const _field = Color(0xFF0B111D);

class _LoginPalette {
  const _LoginPalette({
    required this.background,
    required this.primaryText,
    required this.secondaryText,
    required this.fieldFill,
    required this.fieldBorder,
    required this.icon,
    required this.divider,
    required this.buttonShadow,
    required this.isLight,
  });

  final Color background;
  final Color primaryText;
  final Color secondaryText;
  final Color fieldFill;
  final Color fieldBorder;
  final Color icon;
  final Color divider;
  final Color buttonShadow;
  final bool isLight;

  static const light = _LoginPalette(
    background: Color(0xFFF8FAFD),
    primaryText: Color(0xFF252D42),
    secondaryText: Color(0xFF8B92A6),
    fieldFill: Color(0xFFFDFEFF),
    fieldBorder: Color(0xFFD8DDE8),
    icon: Color(0xFF50586D),
    divider: Color(0xFFE0E4EC),
    buttonShadow: Color(0x33F2A900),
    isLight: true,
  );

  static const dark = _LoginPalette(
    background: Color(0xFF020712),
    primaryText: Color(0xFFFFFFFF),
    secondaryText: _muted,
    fieldFill: _field,
    fieldBorder: Color(0xFF303541),
    icon: _muted,
    divider: Color(0xFF353945),
    buttonShadow: Color(0x00000000),
    isLight: false,
  );
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscurePassword = true;
  bool _isLoading = false;
  String _identifier = '';
  String _password = '';

  Future<void> _login() async {
    if (_identifier.trim().isEmpty || _password.isEmpty || _isLoading) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _isLoading = true);
    try {
      final result = await AuthService().login(
        identifier: _identifier,
        password: _password,
      );
      if (!mounted) return;
      if (result.success) {
        context.go(result.pinConfigured ? '/dashboard' : '/pin-setup');
      }
    } on AuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to login. Please try again.')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final palette = isLight ? _LoginPalette.light : _LoginPalette.dark;

    return Scaffold(
      backgroundColor: palette.background,
      body: Container(
        decoration: BoxDecoration(
          gradient: isLight
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFFFFFFF),
                    Color(0xFFF8FAFD),
                    Color(0xFFFFFFFF),
                  ],
                )
              : const RadialGradient(
                  center: Alignment(0, -0.7),
                  radius: 1.15,
                  colors: [
                    Color(0xFF071735),
                    Color(0xFF020712),
                    Color(0xFF01040B),
                  ],
                  stops: [0, 0.48, 1],
                ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(bottom: isLight ? 26 : 30),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  children: [
                    _BrandHeader(isLight: isLight),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isLight ? 30 : 28,
                      ),
                      child: _LoginForm(
                        palette: palette,
                        obscurePassword: _obscurePassword,
                        isLoading: _isLoading,
                        canLogin:
                            _identifier.trim().isNotEmpty &&
                            _password.isNotEmpty,
                        onIdentifierChanged: (value) =>
                            setState(() => _identifier = value),
                        onPasswordChanged: (value) =>
                            setState(() => _password = value),
                        onLogin: _login,
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
  const _BrandHeader({required this.isLight});

  final bool isLight;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: isLight ? 1.27 : 1.32,
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
                    isLight
                        ? 'UIdesignImages/loginLightTheme.png'
                        : 'UIdesignImages/loginPage.png',
                    width: imageWidth,
                    fit: BoxFit.fitWidth,
                    alignment: Alignment.topCenter,
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: isLight
                            ? const [
                                Colors.transparent,
                                Colors.transparent,
                                Color(0xFFF8FAFD),
                              ]
                            : const [
                                Colors.transparent,
                                Colors.transparent,
                                Color(0xFF020712),
                              ],
                        stops: const [0, 0.86, 1],
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
    required this.palette,
    required this.obscurePassword,
    required this.onTogglePassword,
    required this.isLoading,
    required this.canLogin,
    required this.onIdentifierChanged,
    required this.onPasswordChanged,
    required this.onLogin,
  });

  final _LoginPalette palette;
  final bool obscurePassword;
  final VoidCallback onTogglePassword;
  final bool isLoading;
  final bool canLogin;
  final ValueChanged<String> onIdentifierChanged;
  final ValueChanged<String> onPasswordChanged;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Welcome Back!',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: palette.primaryText,
            fontSize: palette.isLight ? 31 : 27,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Login to your AFA account',
          textAlign: TextAlign.center,
          style: TextStyle(color: palette.secondaryText, fontSize: 18),
        ),
        SizedBox(height: palette.isLight ? 30 : 28),
        _FieldLabel('Email or Phone Number', palette: palette),
        const SizedBox(height: 8),
        TextField(
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.username, AutofillHints.email],
          onChanged: onIdentifierChanged,
          style: TextStyle(color: palette.primaryText, fontSize: 17),
          decoration: _inputDecoration(
            palette,
            hintText: 'Enter email or phone number',
            prefixIcon: Icons.person_outline_rounded,
          ),
        ),
        SizedBox(height: palette.isLight ? 22 : 20),
        _FieldLabel('Password', palette: palette),
        const SizedBox(height: 8),
        TextField(
          obscureText: obscurePassword,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.password],
          onChanged: onPasswordChanged,
          onSubmitted: (_) {
            if (canLogin) onLogin();
          },
          style: TextStyle(color: palette.primaryText, fontSize: 17),
          decoration: _inputDecoration(
            palette,
            hintText: 'Enter your password',
            prefixIcon: Icons.lock_outline_rounded,
            suffixIcon: IconButton(
              tooltip: obscurePassword ? 'Show password' : 'Hide password',
              onPressed: onTogglePassword,
              color: palette.icon,
              icon: Icon(
                obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
              ),
            ),
          ),
        ),
        SizedBox(height: palette.isLight ? 14 : 12),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {},
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Forgot Password?',
                  style: TextStyle(color: _gold, fontSize: 16),
                ),
                if (palette.isLight) ...[
                  const SizedBox(width: 5),
                  const Icon(Icons.chevron_right_rounded, color: _gold),
                ],
              ],
            ),
          ),
        ),
        SizedBox(height: palette.isLight ? 26 : 14),
        SizedBox(
          height: palette.isLight ? 64 : 58,
          child: FilledButton(
            onPressed: canLogin && !isLoading ? onLogin : null,
            style: FilledButton.styleFrom(
              backgroundColor: _gold,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(palette.isLight ? 14 : 14),
              ),
              elevation: palette.isLight ? 14 : 0,
              shadowColor: palette.buttonShadow,
            ),
            child: isLoading
                ? const SizedBox(
                    width: 25,
                    height: 25,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.6,
                      color: Colors.black,
                    ),
                  )
                : const Text(
                    'Login',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
          ),
        ),
        SizedBox(height: palette.isLight ? 34 : 28),
        _SectionDivider(palette: palette),
        if (palette.isLight) ...[
          const SizedBox(height: 24),
          SizedBox(
            height: 58,
            child: OutlinedButton(
              onPressed: () => context.go('/register'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _gold,
                side: const BorderSide(color: _gold),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Sign Up',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ] else ...[
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
                  context.go('/register');
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
      ],
    );
  }
}

InputDecoration _inputDecoration(
  _LoginPalette palette, {
  required String hintText,
  required IconData prefixIcon,
  Widget? suffixIcon,
}) {
  return InputDecoration(
    hintText: hintText,
    prefixIcon: Icon(prefixIcon, color: palette.icon),
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: palette.fieldFill,
    hintStyle: TextStyle(color: palette.secondaryText, fontSize: 17),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 21),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: palette.fieldBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: _gold, width: 1.3),
    ),
  );
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label, {required this.palette});

  final String label;
  final _LoginPalette palette;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        color: palette.primaryText,
        fontSize: 16,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider({required this.palette});

  final _LoginPalette palette;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: palette.divider)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            palette.isLight ? "Don’t have an account?" : 'or continue with',
            style: TextStyle(color: palette.secondaryText, fontSize: 15),
          ),
        ),
        Expanded(child: Divider(color: palette.divider)),
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
