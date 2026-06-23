import 'package:flutter/material.dart';

import '../../models/chat_room_settings.dart';

class ChatRoomTitle extends StatelessWidget {
  const ChatRoomTitle({
    super.key,
    required this.title,
    required this.isGroup,
    required this.muted,
    required this.accent,
  });

  final String title;
  final bool isGroup;
  final bool muted;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: accent.withValues(alpha: 0.18),
          child: Icon(
            isGroup ? Icons.groups_rounded : Icons.person_rounded,
            color: accent,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              if (muted)
                const Text(
                  'Muted',
                  style: TextStyle(color: chatMuted, fontSize: 12),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
