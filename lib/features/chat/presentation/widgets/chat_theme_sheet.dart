import 'package:flutter/material.dart';

import '../../models/chat_room_settings.dart';

Future<void> showChatThemeSheet({
  required BuildContext context,
  required ChatRoomSettings settings,
  required ValueChanged<ChatRoomSettings> onChanged,
}) {
  var currentSettings = settings;
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: chatPanel,
    showDragHandle: true,
    builder: (context) => StatefulBuilder(
      builder: (context, setSheetState) {
        void update(ChatRoomSettings next) {
          setSheetState(() => currentSettings = next);
          onChanged(next);
        }

        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
            children: [
              const Text(
                'Chat Theme',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: ChatThemeOption.values.map((theme) {
                  return _ThemeChip(
                    label: theme.label,
                    color: theme.accent,
                    selected: currentSettings.theme == theme,
                    onTap: () => update(currentSettings.copyWith(theme: theme)),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              const Text(
                'Wallpaper',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              ...ChatWallpaperOption.values.map(
                (wallpaper) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(wallpaper.label),
                  leading: Icon(
                    currentSettings.wallpaper == wallpaper
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_off_rounded,
                    color: currentSettings.wallpaper == wallpaper
                        ? currentSettings.theme.accent
                        : chatMuted,
                  ),
                  onTap: () =>
                      update(currentSettings.copyWith(wallpaper: wallpaper)),
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}

class _ThemeChip extends StatelessWidget {
  const _ThemeChip({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        width: 142,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF0B1624),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? color : const Color(0xFF223047)),
        ),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
