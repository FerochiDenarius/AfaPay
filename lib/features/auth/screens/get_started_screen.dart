import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

const _gold = Color(0xFFF2A900);
const _navy = Color(0xFF020B1C);
const _ink = Color(0xFF07122A);

class GetStartedScreen extends StatelessWidget {
  const GetStartedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final palette = isLight ? _StartPalette.light : _StartPalette.dark;

    return Scaffold(
      backgroundColor: palette.background,
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: palette.backgroundGradient),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(painter: _PatternPainter(palette: palette)),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxHeight < 780;
                  return SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(20, isLight ? 10 : 8, 20, 14),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight:
                            constraints.maxHeight -
                            MediaQuery.paddingOf(context).vertical -
                            24,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 460),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _TopBar(palette: palette, showLanguage: isLight),
                              _HeroContent(palette: palette, compact: compact),
                              _BottomActions(palette: palette),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StartPalette {
  const _StartPalette({
    required this.background,
    required this.primaryText,
    required this.secondaryText,
    required this.surface,
    required this.surfaceText,
    required this.border,
    required this.shadow,
    required this.pattern,
    required this.backgroundGradient,
    required this.isLight,
  });

  final Color background;
  final Color primaryText;
  final Color secondaryText;
  final Color surface;
  final Color surfaceText;
  final Color border;
  final Color shadow;
  final Color pattern;
  final Gradient backgroundGradient;
  final bool isLight;

  static const light = _StartPalette(
    background: Color(0xFFFCFAF6),
    primaryText: _ink,
    secondaryText: Color(0xFF606A7B),
    surface: Color(0xFFFFFFFF),
    surfaceText: _ink,
    border: Color(0xFFEBD7A1),
    shadow: Color(0x26000000),
    pattern: Color(0x18D99A00),
    backgroundGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFFFFFFF), Color(0xFFFBF8F1), Color(0xFFFFFFFF)],
    ),
    isLight: true,
  );

  static const dark = _StartPalette(
    background: _navy,
    primaryText: Color(0xFFFFFFFF),
    secondaryText: Color(0xFFCFD4DE),
    surface: Color(0x3308142B),
    surfaceText: Color(0xFFFFFFFF),
    border: Color(0x8A8B6A24),
    shadow: Color(0x88000000),
    pattern: Color(0x222B6FB8),
    backgroundGradient: RadialGradient(
      center: Alignment(0, -0.55),
      radius: 1.2,
      colors: [Color(0xFF073A79), Color(0xFF03142D), _navy],
      stops: [0, 0.48, 1],
    ),
    isLight: false,
  );
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.palette, required this.showLanguage});

  final _StartPalette palette;
  final bool showLanguage;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: showLanguage ? 52 : 16,
      child: Align(
        alignment: Alignment.centerRight,
        child: showLanguage
            ? OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.language_rounded, size: 22),
                label: const Text('English'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: palette.primaryText,
                  side: const BorderSide(color: _gold),
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}

class _HeroContent extends StatelessWidget {
  const _HeroContent({required this.palette, required this.compact});

  final _StartPalette palette;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final logoSize = compact ? 86.0 : 112.0;
    return Column(
      children: [
        SizedBox(height: compact ? 2 : 10),
        _LogoMark(size: logoSize, palette: palette),
        SizedBox(height: compact ? 12 : 18),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text.rich(
            TextSpan(
              text: 'Welcome to ',
              children: const [
                TextSpan(
                  text: 'AFA',
                  style: TextStyle(color: _gold),
                ),
              ],
            ),
            maxLines: 1,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: palette.primaryText,
              fontSize: compact ? 32 : 40,
              fontWeight: FontWeight.w900,
              height: 1.08,
            ),
          ),
        ),
        SizedBox(height: compact ? 8 : 10),
        _GoldDivider(isLight: palette.isLight),
        SizedBox(height: compact ? 9 : 12),
        Text(
          'Chat, Pay, Connect - all in one place.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: palette.secondaryText,
            fontSize: compact ? 15 : 17,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: compact ? 14 : 20),
        _FeatureRow(palette: palette),
        SizedBox(height: compact ? 10 : 16),
        _AfricaIllustration(palette: palette, compact: compact),
      ],
    );
  }
}

class _LogoMark extends StatelessWidget {
  const _LogoMark({required this.size, required this.palette});

  final double size;
  final _StartPalette palette;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: size,
          height: size,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: palette.isLight ? Colors.white : const Color(0x33000000),
            shape: BoxShape.circle,
            border: Border.all(color: _gold.withValues(alpha: 0.45)),
            boxShadow: [
              BoxShadow(
                color: palette.shadow,
                blurRadius: 28,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset(
              palette.isLight
                  ? 'UIdesignImages/appIcon.png'
                  : 'UIdesignImages/logo.png',
              fit: BoxFit.cover,
              filterQuality: FilterQuality.high,
            ),
          ),
        ),
        SizedBox(height: size < 100 ? 6 : 8),
        Text(
          'AFA',
          style: TextStyle(
            color: _gold,
            fontSize: size * 0.27,
            fontWeight: FontWeight.w900,
            height: 0.9,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'ALL FEATURES AFRICA',
          style: TextStyle(
            color: palette.primaryText,
            fontSize: size < 100 ? 9.5 : 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.8,
          ),
        ),
      ],
    );
  }
}

class _GoldDivider extends StatelessWidget {
  const _GoldDivider({required this.isLight});

  final bool isLight;

  @override
  Widget build(BuildContext context) {
    final lineColor = isLight ? const Color(0xFFEBCB77) : _gold;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(width: 82, height: 1, color: lineColor),
        Container(
          width: 10,
          height: 10,
          margin: const EdgeInsets.symmetric(horizontal: 10),
          transform: Matrix4.rotationZ(0.78),
          decoration: const BoxDecoration(color: _gold),
        ),
        Container(width: 82, height: 1, color: lineColor),
      ],
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.palette});

  final _StartPalette palette;

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.chat_bubble_outline_rounded, 'Chat'),
      (Icons.credit_card_rounded, 'Pay'),
      (Icons.groups_2_outlined, 'Connect'),
    ];

    return Row(
      children: [
        for (final item in items) ...[
          Expanded(
            child: _FeaturePill(
              icon: item.$1,
              label: item.$2,
              palette: palette,
            ),
          ),
          if (item != items.last) const SizedBox(width: 10),
        ],
      ],
    );
  }
}

class _FeaturePill extends StatelessWidget {
  const _FeaturePill({
    required this.icon,
    required this.label,
    required this.palette,
  });

  final IconData icon;
  final String label;
  final _StartPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.border),
        boxShadow: [
          if (palette.isLight)
            BoxShadow(
              color: palette.shadow,
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: _gold, size: 24),
          const SizedBox(width: 6),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: TextStyle(
                  color: palette.surfaceText,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AfricaIllustration extends StatelessWidget {
  const _AfricaIllustration({required this.palette, required this.compact});

  final _StartPalette palette;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final asset = palette.isLight
        ? 'UIdesignImages/afa_onboarding_africa_light.png'
        : 'UIdesignImages/afa_onboarding_africa_dark.png';
    return Semantics(
      image: true,
      label: 'Africa connected through chat, payments, and community',
      child: SizedBox(
        height: compact ? 190 : 250,
        width: double.infinity,
        child: Image.asset(
          asset,
          fit: BoxFit.contain,
          alignment: Alignment.center,
          filterQuality: FilterQuality.high,
          gaplessPlayback: true,
        ),
      ),
    );
  }
}

class _BottomActions extends StatelessWidget {
  const _BottomActions({required this.palette});

  final _StartPalette palette;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        SizedBox(
          height: 56,
          child: FilledButton.icon(
            onPressed: () => context.go('/register'),
            iconAlignment: IconAlignment.end,
            icon: const Icon(Icons.chevron_right_rounded, size: 34),
            label: const Text('Get Started'),
            style: FilledButton.styleFrom(
              backgroundColor: _gold,
              foregroundColor: Colors.black,
              elevation: palette.isLight ? 10 : 0,
              shadowColor: const Color(0x55D99100),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              textStyle: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                'Already have an account? ',
                style: TextStyle(
                  color: palette.secondaryText,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            TextButton(
              onPressed: () => context.go('/login'),
              style: TextButton.styleFrom(
                foregroundColor: _gold,
                padding: const EdgeInsets.symmetric(horizontal: 2),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              child: const Text('Sign In'),
            ),
          ],
        ),
      ],
    );
  }
}

class _PatternPainter extends CustomPainter {
  const _PatternPainter({required this.palette});

  final _StartPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = palette.pattern
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final center = Offset(size.width * 0.5, size.height * 0.32);
    for (var radius = size.width * 0.18; radius < size.width; radius += 56) {
      canvas.drawCircle(center, radius, paint);
    }

    final dotPaint = Paint()
      ..color = _gold.withValues(alpha: palette.isLight ? 0.16 : 0.08);
    for (var y = 0.0; y < size.height; y += 18) {
      for (var x = 0.0; x < size.width; x += 18) {
        if (x < size.width * 0.16 || x > size.width * 0.86) {
          canvas.drawCircle(Offset(x, y), 1.6, dotPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PatternPainter oldDelegate) {
    return oldDelegate.palette != palette;
  }
}
