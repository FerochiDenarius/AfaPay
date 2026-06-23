import 'package:flutter/material.dart';

import '../../models/chat_room_settings.dart';

enum ChatRoomMenuAction {
  viewContact,
  chatTheme,
  block,
  mute,
  disappearingMessages,
  report,
  newGroup,
  clearChat,
}

class ChatRoomMenu extends StatelessWidget {
  const ChatRoomMenu({
    super.key,
    required this.isGroup,
    required this.settings,
    required this.contactAvailable,
    required this.onSelected,
  });

  final bool isGroup;
  final ChatRoomSettings settings;
  final bool contactAvailable;
  final ValueChanged<ChatRoomMenuAction> onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<ChatRoomMenuAction>(
      tooltip: 'Chat menu',
      icon: const Icon(Icons.more_vert_rounded),
      onSelected: onSelected,
      itemBuilder: (context) => [
        _menuItem(
          ChatRoomMenuAction.viewContact,
          isGroup ? Icons.groups_rounded : Icons.person_rounded,
          isGroup ? 'View group' : 'View contact',
        ),
        _menuItem(
          ChatRoomMenuAction.chatTheme,
          Icons.palette_outlined,
          'Chat theme',
        ),
        _menuItem(
          ChatRoomMenuAction.block,
          Icons.block_rounded,
          'Block',
          enabled: contactAvailable,
        ),
        _menuItem(
          ChatRoomMenuAction.mute,
          settings.muted
              ? Icons.notifications_active_outlined
              : Icons.notifications_off_outlined,
          settings.muted ? 'Unmute notifications' : 'Mute notifications',
        ),
        _menuItem(
          ChatRoomMenuAction.disappearingMessages,
          Icons.timer_outlined,
          'Disappearing messages',
        ),
        _menuItem(
          ChatRoomMenuAction.report,
          Icons.flag_outlined,
          'Report',
          enabled: contactAvailable,
        ),
        _menuItem(
          ChatRoomMenuAction.newGroup,
          Icons.group_add_outlined,
          'New group',
        ),
        _menuItem(
          ChatRoomMenuAction.clearChat,
          Icons.delete_sweep_outlined,
          'Clear chat',
        ),
      ],
    );
  }

  PopupMenuItem<ChatRoomMenuAction> _menuItem(
    ChatRoomMenuAction action,
    IconData icon,
    String label, {
    bool enabled = true,
  }) {
    return PopupMenuItem<ChatRoomMenuAction>(
      value: action,
      enabled: enabled,
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Flexible(child: Text(label)),
        ],
      ),
    );
  }
}
