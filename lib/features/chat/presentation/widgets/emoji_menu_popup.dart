import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class EmojiMenuPopup extends StatelessWidget {
  const EmojiMenuPopup({
    super.key,
    required this.onEmoji,
    required this.onGif,
    required this.onSticker,
  });

  final VoidCallback onEmoji;
  final VoidCallback onGif;
  final VoidCallback onSticker;

  @override
  Widget build(BuildContext context) {
    final colors = context.chatColors;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomRight,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: colors.menuSurface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: colors.border),
            boxShadow: [
              BoxShadow(
                color: colors.shadow,
                blurRadius: 24,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _EmojiMenuItem(
                label: 'Emoji',
                icon: Icons.emoji_emotions_outlined,
                onTap: onEmoji,
              ),
              const SizedBox(width: 18),
              _EmojiMenuItem(
                label: 'GIF',
                icon: Icons.gif_box_outlined,
                onTap: onGif,
              ),
              const SizedBox(width: 18),
              _EmojiMenuItem(
                label: 'Sticker',
                icon: Icons.sticky_note_2_outlined,
                onTap: onSticker,
              ),
            ],
          ),
        ),
        Positioned(
          right: 62,
          bottom: -12,
          child: Transform.rotate(
            angle: 0.785398,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: colors.menuSurface,
                border: Border(
                  right: BorderSide(color: colors.border),
                  bottom: BorderSide(color: colors.border),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _EmojiMenuItem extends StatelessWidget {
  const _EmojiMenuItem({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.chatColors;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: colors.icon, size: 28),
            const SizedBox(height: 7),
            Text(
              label,
              style: TextStyle(
                color: colors.primaryText,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
