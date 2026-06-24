import 'package:flutter/material.dart';

import '../../models/chat_models.dart';
import '../../models/chat_room_settings.dart';
import 'chat_message_widgets.dart';

class ChatComposer extends StatelessWidget {
  const ChatComposer({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.replyingTo,
    required this.accent,
    required this.isSending,
    required this.onCancelReply,
    required this.onAttachmentPressed,
    required this.onCameraPressed,
    required this.onEmojiPressed,
    required this.onGifPressed,
    required this.onStickerPressed,
    required this.onSend,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ChatMessage? replyingTo;
  final Color accent;
  final bool isSending;
  final VoidCallback onCancelReply;
  final VoidCallback onAttachmentPressed;
  final VoidCallback onCameraPressed;
  final VoidCallback onEmojiPressed;
  final VoidCallback onGifPressed;
  final VoidCallback onStickerPressed;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
        decoration: const BoxDecoration(
          color: chatPanel,
          border: Border(top: BorderSide(color: Color(0xFF162337))),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (replyingTo != null)
              ReplyComposerPreview(
                message: replyingTo!,
                accent: accent,
                onClose: onCancelReply,
              ),
            _ComposerActionBar(
              accent: accent,
              onAttachmentPressed: onAttachmentPressed,
              onCameraPressed: onCameraPressed,
              onEmojiPressed: onEmojiPressed,
              onGifPressed: onGifPressed,
              onStickerPressed: onStickerPressed,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => onSend(),
                    decoration: const InputDecoration(
                      hintText: 'Type a message',
                      prefixIcon: Icon(Icons.message_outlined),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton.filled(
                  style: IconButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.black,
                  ),
                  onPressed: isSending ? null : onSend,
                  icon: isSending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_rounded),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ComposerActionBar extends StatelessWidget {
  const _ComposerActionBar({
    required this.accent,
    required this.onAttachmentPressed,
    required this.onCameraPressed,
    required this.onEmojiPressed,
    required this.onGifPressed,
    required this.onStickerPressed,
  });

  final Color accent;
  final VoidCallback onAttachmentPressed;
  final VoidCallback onCameraPressed;
  final VoidCallback onEmojiPressed;
  final VoidCallback onGifPressed;
  final VoidCallback onStickerPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ComposerToolButton(
          tooltip: 'Attachments',
          icon: Icons.attach_file_rounded,
          accent: accent,
          onPressed: onAttachmentPressed,
        ),
        _ComposerToolButton(
          tooltip: 'Camera',
          icon: Icons.photo_camera_outlined,
          accent: accent,
          onPressed: onCameraPressed,
        ),
        const Spacer(),
        _ComposerToolButton(
          tooltip: 'Emoji',
          icon: Icons.emoji_emotions_outlined,
          accent: accent,
          onPressed: onEmojiPressed,
        ),
        _ComposerToolButton(
          tooltip: 'GIF',
          icon: Icons.gif_box_outlined,
          accent: accent,
          onPressed: onGifPressed,
        ),
        _ComposerToolButton(
          tooltip: 'Stickers',
          icon: Icons.sticky_note_2_outlined,
          accent: accent,
          onPressed: onStickerPressed,
        ),
      ],
    );
  }
}

class _ComposerToolButton extends StatelessWidget {
  const _ComposerToolButton({
    required this.tooltip,
    required this.icon,
    required this.accent,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final Color accent;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 38,
      child: IconButton(
        tooltip: tooltip,
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
        style: IconButton.styleFrom(
          backgroundColor: const Color(0xFF0B1624),
          foregroundColor: chatMuted,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: Color(0xFF1B2A3E)),
          ),
        ),
        hoverColor: accent.withValues(alpha: 0.14),
        highlightColor: accent.withValues(alpha: 0.2),
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
      ),
    );
  }
}
