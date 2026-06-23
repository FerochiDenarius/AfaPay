import 'package:flutter/material.dart';

import '../../models/chat_room_settings.dart';

class ChatWallpaperBackdrop extends StatelessWidget {
  const ChatWallpaperBackdrop({super.key, required this.settings});

  final ChatRoomSettings settings;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _WallpaperPainter(settings),
      child: const SizedBox.expand(),
    );
  }
}

class _WallpaperPainter extends CustomPainter {
  const _WallpaperPainter(this.settings);

  final ChatRoomSettings settings;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final accent = settings.theme.accent;
    final basePaint = Paint();
    switch (settings.wallpaper) {
      case ChatWallpaperOption.midnight:
        basePaint.shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF020712), Color(0xFF08111E), Color(0xFF020712)],
        ).createShader(rect);
      case ChatWallpaperOption.graphite:
        basePaint.shader = const LinearGradient(
          colors: [Color(0xFF111827), Color(0xFF030712)],
        ).createShader(rect);
      case ChatWallpaperOption.aurora:
        basePaint.shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            accent.withValues(alpha: 0.24),
            const Color(0xFF031018),
            const Color(0xFF020712),
          ],
        ).createShader(rect);
      case ChatWallpaperOption.clean:
        basePaint.color = const Color(0xFF07101C);
    }
    canvas.drawRect(rect, basePaint);

    if (settings.wallpaper == ChatWallpaperOption.clean) return;

    final dotPaint = Paint()..color = Colors.white.withValues(alpha: 0.035);
    for (double y = 18; y < size.height; y += 34) {
      for (double x = 18; x < size.width; x += 34) {
        canvas.drawCircle(Offset(x, y), 1.2, dotPaint);
      }
    }

    final accentPaint = Paint()
      ..color = accent.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (double y = 40; y < size.height; y += 110) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y + 42), accentPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _WallpaperPainter oldDelegate) {
    return oldDelegate.settings != settings;
  }
}
