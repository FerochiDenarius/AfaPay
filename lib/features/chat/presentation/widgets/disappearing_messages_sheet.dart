import 'package:flutter/material.dart';

import '../../models/chat_room_settings.dart';

Future<void> showDisappearingMessagesSheet({
  required BuildContext context,
  required ChatRoomSettings settings,
  required ValueChanged<ChatRoomSettings> onChanged,
}) {
  const options = <int?, String>{
    null: 'Off',
    86400: '24 hours',
    604800: '7 days',
    2592000: '30 days',
  };
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: chatPanel,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
        children: [
          const Text(
            'Disappearing Messages',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          const Text(
            'Messages older than the selected time are hidden on this device.',
            style: TextStyle(color: chatMuted),
          ),
          const SizedBox(height: 14),
          ...options.entries.map(
            (entry) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(entry.value),
              leading: Icon(
                settings.disappearingSeconds == entry.key
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                color: settings.disappearingSeconds == entry.key
                    ? settings.theme.accent
                    : chatMuted,
              ),
              onTap: () {
                onChanged(settings.copyWith(disappearingSeconds: entry.key));
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    ),
  );
}
