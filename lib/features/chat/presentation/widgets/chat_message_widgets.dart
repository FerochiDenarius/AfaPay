import 'package:flutter/material.dart';

import '../../models/chat_models.dart';
import '../../models/chat_room_settings.dart';

class SwipeToReplyMessage extends StatefulWidget {
  const SwipeToReplyMessage({
    super.key,
    required this.child,
    required this.onReply,
    required this.isMine,
    required this.accent,
  });

  final Widget child;
  final VoidCallback onReply;
  final bool isMine;
  final Color accent;

  @override
  State<SwipeToReplyMessage> createState() => _SwipeToReplyMessageState();
}

class _SwipeToReplyMessageState extends State<SwipeToReplyMessage> {
  double _dragOffset = 0;

  @override
  Widget build(BuildContext context) {
    final direction = widget.isMine ? -1.0 : 1.0;
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragUpdate: (details) {
        final movement = details.delta.dx * direction;
        if (movement <= 0 && _dragOffset <= 0) return;
        setState(() => _dragOffset = (_dragOffset + movement).clamp(0, 76));
      },
      onHorizontalDragEnd: (_) {
        if (_dragOffset > 48) widget.onReply();
        setState(() => _dragOffset = 0);
      },
      onHorizontalDragCancel: () => setState(() => _dragOffset = 0),
      child: Stack(
        alignment: widget.isMine ? Alignment.centerRight : Alignment.centerLeft,
        children: [
          Positioned(
            left: widget.isMine ? null : 12,
            right: widget.isMine ? 12 : null,
            child: Opacity(
              opacity: (_dragOffset / 76).clamp(0, 1),
              child: CircleAvatar(
                radius: 15,
                backgroundColor: widget.accent.withValues(alpha: 0.2),
                child: Icon(
                  Icons.reply_rounded,
                  size: 18,
                  color: widget.accent,
                  textDirection: widget.isMine
                      ? TextDirection.rtl
                      : TextDirection.ltr,
                ),
              ),
            ),
          ),
          Transform.translate(
            offset: Offset(_dragOffset * direction, 0),
            child: widget.child,
          ),
        ],
      ),
    );
  }
}

class ChatMessageBubble extends StatelessWidget {
  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.isMine,
    required this.accent,
  });

  final ChatMessage message;
  final bool isMine;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMine ? accent : chatPanel.withValues(alpha: 0.96),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMine ? 18 : 4),
            bottomRight: Radius.circular(isMine ? 4 : 18),
          ),
          border: isMine ? null : Border.all(color: const Color(0xFF162337)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.repliedTo != null) ...[
              ReplySnippet(
                message: message.repliedTo!,
                isMine: isMine,
                accent: accent,
              ),
              const SizedBox(height: 8),
            ],
            Text(
              message.text?.isNotEmpty == true ? message.text! : 'Message',
              style: TextStyle(
                color: isMine ? Colors.black : Colors.white,
                fontWeight: FontWeight.w600,
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ReplySnippet extends StatelessWidget {
  const ReplySnippet({
    super.key,
    required this.message,
    required this.isMine,
    required this.accent,
  });

  final ChatMessage message;
  final bool isMine;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final foreground = isMine ? Colors.black : Colors.white;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isMine
            ? Colors.white.withValues(alpha: 0.32)
            : Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(color: isMine ? Colors.black : accent, width: 3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message.senderName ?? 'Message',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: foreground.withValues(alpha: 0.86),
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            message.text?.isNotEmpty == true ? message.text! : 'Message',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: foreground.withValues(alpha: 0.78),
              fontSize: 12,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class ReplyComposerPreview extends StatelessWidget {
  const ReplyComposerPreview({
    super.key,
    required this.message,
    required this.accent,
    required this.onClose,
  });

  final ChatMessage message;
  final Color accent;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 9, 8, 9),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1624),
        borderRadius: BorderRadius.circular(10),
        border: Border(left: BorderSide(color: accent, width: 3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.reply_rounded, color: chatMuted, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message.senderName ?? 'Replying to message',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: accent, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 2),
                Text(
                  message.text?.isNotEmpty == true ? message.text! : 'Message',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: chatMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Cancel reply',
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }
}
