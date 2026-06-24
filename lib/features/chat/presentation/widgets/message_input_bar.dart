import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import 'attachment_menu_popup.dart';
import 'emoji_menu_popup.dart';

class MessageInputBar extends StatelessWidget {
  const MessageInputBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.showEmojiMenu,
    required this.showAttachmentMenu,
    required this.onAttachmentPressed,
    required this.onCameraPressed,
    required this.onEmojiButtonPressed,
    required this.onDocument,
    required this.onGallery,
    required this.onContact,
    required this.onLocation,
    required this.onPoll,
    required this.onEvent,
    required this.onEmoji,
    required this.onGif,
    required this.onSticker,
    required this.onSend,
    required this.onVoiceMessage,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool showEmojiMenu;
  final bool showAttachmentMenu;
  final VoidCallback onAttachmentPressed;
  final VoidCallback onCameraPressed;
  final VoidCallback onEmojiButtonPressed;
  final VoidCallback onDocument;
  final VoidCallback onGallery;
  final VoidCallback onContact;
  final VoidCallback onLocation;
  final VoidCallback onPoll;
  final VoidCallback onEvent;
  final VoidCallback onEmoji;
  final VoidCallback onGif;
  final VoidCallback onSticker;
  final VoidCallback onSend;
  final VoidCallback onVoiceMessage;

  @override
  Widget build(BuildContext context) {
    final colors = context.chatColors;

    return SafeArea(
      top: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 520;
          final horizontalPadding = compact ? 14.0 : 24.0;
          final sendSize = compact ? 48.0 : 52.0;
          final toolSize = compact ? 32.0 : 36.0;
          final menuReserve = showAttachmentMenu
              ? (compact ? 276.0 : 286.0)
              : 0.0;

          return Padding(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              10,
              horizontalPadding,
              22,
            ),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.bottomRight,
              children: [
                SizedBox(height: sendSize + menuReserve),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: controller,
                  builder: (context, value, _) {
                    final hasText = value.text.isNotEmpty;

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Container(
                            constraints: BoxConstraints(minHeight: sendSize),
                            padding: EdgeInsets.fromLTRB(
                              compact ? 7 : 9,
                              compact ? 5 : 7,
                              compact ? 7 : 9,
                              compact ? 5 : 7,
                            ),
                            decoration: BoxDecoration(
                              color: colors.composerSurface,
                              borderRadius: BorderRadius.circular(sendSize / 2),
                              border: Border.all(color: colors.border),
                              boxShadow: [
                                BoxShadow(
                                  color: colors.shadow,
                                  blurRadius: 18,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                _InputIconButton(
                                  tooltip: 'Add',
                                  icon: Icons.add_rounded,
                                  dimension: toolSize,
                                  filled: true,
                                  selected: showAttachmentMenu,
                                  onPressed: onAttachmentPressed,
                                ),
                                SizedBox(width: compact ? 4 : 8),
                                Expanded(
                                  child: TextField(
                                    controller: controller,
                                    focusNode: focusNode,
                                    cursorColor: colors.cursor,
                                    minLines: 1,
                                    maxLines: 4,
                                    textInputAction: TextInputAction.send,
                                    onSubmitted: (_) => onSend(),
                                    style: TextStyle(
                                      color: colors.primaryText,
                                      fontSize: compact ? 15 : 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: 'Type a message...',
                                      hintStyle: TextStyle(
                                        color: colors.placeholderText,
                                        fontSize: compact ? 15 : 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      filled: false,
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      isDense: true,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            vertical: 9,
                                          ),
                                    ),
                                  ),
                                ),
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 120),
                                  switchInCurve: Curves.easeOut,
                                  switchOutCurve: Curves.easeIn,
                                  child: hasText
                                      ? const SizedBox.shrink()
                                      : _InputIconButton(
                                          key: const ValueKey('camera-tool'),
                                          tooltip: 'Camera',
                                          icon: Icons.photo_camera_outlined,
                                          dimension: toolSize,
                                          onPressed: onCameraPressed,
                                        ),
                                ),
                                SizedBox(
                                  width: hasText ? 0 : (compact ? 2 : 4),
                                ),
                                _InputIconButton(
                                  tooltip: 'Emoji, GIF, or sticker',
                                  icon: Icons.sticky_note_2_outlined,
                                  dimension: toolSize,
                                  selected: showEmojiMenu,
                                  onPressed: onEmojiButtonPressed,
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: compact ? 10 : 12),
                        SizedBox.square(
                          dimension: sendSize,
                          child: IconButton(
                            tooltip: hasText ? 'Send' : 'Voice message',
                            style: IconButton.styleFrom(
                              padding: EdgeInsets.zero,
                              backgroundColor: colors.accent,
                              foregroundColor: colors.onAccentText,
                              shape: const CircleBorder(),
                              side: BorderSide(
                                color: colors.outgoingBubbleBorder,
                              ),
                            ),
                            onPressed: hasText ? onSend : onVoiceMessage,
                            icon: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 120),
                              switchInCurve: Curves.easeOut,
                              switchOutCurve: Curves.easeIn,
                              child: Icon(
                                hasText ? Icons.send_rounded : Icons.mic_none,
                                key: ValueKey(hasText),
                                size: compact ? 22 : 24,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                if (showEmojiMenu)
                  Positioned(
                    right: compact ? 0 : 78,
                    bottom: compact ? 76 : 86,
                    child: EmojiMenuPopup(
                      onEmoji: onEmoji,
                      onGif: onGif,
                      onSticker: onSticker,
                    ),
                  ),
                if (showAttachmentMenu)
                  Positioned(
                    left: 0,
                    bottom: compact ? 76 : 86,
                    child: AttachmentMenuPopup(
                      onDocument: onDocument,
                      onGallery: onGallery,
                      onContact: onContact,
                      onLocation: onLocation,
                      onPoll: onPoll,
                      onEvent: onEvent,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _InputIconButton extends StatelessWidget {
  const _InputIconButton({
    super.key,
    required this.tooltip,
    required this.icon,
    required this.dimension,
    required this.onPressed,
    this.filled = false,
    this.selected = false,
  });

  final String tooltip;
  final IconData icon;
  final double dimension;
  final VoidCallback onPressed;
  final bool filled;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = context.chatColors;

    return SizedBox.square(
      dimension: dimension,
      child: IconButton(
        tooltip: tooltip,
        style: IconButton.styleFrom(
          padding: EdgeInsets.zero,
          backgroundColor: filled || selected
              ? colors.composerButtonSurface
              : colors.composerSurface,
          foregroundColor: filled || selected ? colors.icon : colors.mutedIcon,
          shape: const CircleBorder(),
          side: BorderSide(color: selected ? colors.border : colors.softBorder),
        ),
        onPressed: onPressed,
        icon: Icon(icon, size: filled ? dimension * 0.63 : dimension * 0.52),
      ),
    );
  }
}
