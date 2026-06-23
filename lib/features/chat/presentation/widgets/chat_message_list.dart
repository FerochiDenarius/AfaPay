import 'package:flutter/material.dart';

import '../../models/chat_models.dart';
import '../../models/chat_room_settings.dart';
import 'chat_message_widgets.dart';
import 'chat_room_error.dart';

class ChatMessageList extends StatelessWidget {
  const ChatMessageList({
    super.key,
    required this.isLoading,
    required this.errorMessage,
    required this.accent,
    required this.messages,
    required this.currentUserId,
    required this.scrollController,
    required this.onRetry,
    required this.onReply,
  });

  final bool isLoading;
  final String? errorMessage;
  final Color accent;
  final List<ChatMessage> messages;
  final String? currentUserId;
  final ScrollController scrollController;
  final VoidCallback onRetry;
  final ValueChanged<ChatMessage> onReply;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(child: CircularProgressIndicator(color: accent));
    }
    if (errorMessage != null) {
      return ChatRoomError(message: errorMessage!, onRetry: onRetry);
    }
    if (messages.isEmpty) {
      return const Center(
        child: Text(
          'No messages here yet.',
          style: TextStyle(color: chatMuted),
        ),
      );
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final isMine = message.isMine(currentUserId);
        return SwipeToReplyMessage(
          onReply: () => onReply(message),
          isMine: isMine,
          accent: accent,
          child: ChatMessageBubble(
            message: message,
            isMine: isMine,
            accent: accent,
          ),
        );
      },
    );
  }
}
