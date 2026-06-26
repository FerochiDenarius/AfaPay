import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../models/chat_attachment.dart';
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
    required this.onAudioRecording,
    this.pendingAttachment,
    this.onRemoveAttachment,
    this.isRecordingAudio = false,
    this.onVoiceRecordingStart,
    this.onVoiceRecordingStop,
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
  final VoidCallback onAudioRecording;
  final ChatAttachment? pendingAttachment;
  final VoidCallback? onRemoveAttachment;
  final bool isRecordingAudio;
  final VoidCallback? onVoiceRecordingStart;
  final VoidCallback? onVoiceRecordingStop;

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
          final previewReserve = pendingAttachment != null || isRecordingAudio
              ? (compact ? 92.0 : 98.0)
              : 0.0;
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
                SizedBox(height: sendSize + menuReserve + previewReserve),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: controller,
                  builder: (context, value, _) {
                    final hasText = value.text.isNotEmpty;
                    final hasSendableContent =
                        hasText || pendingAttachment != null;

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (pendingAttachment != null || isRecordingAudio) ...[
                          _ComposerAttachmentPreview(
                            attachment: pendingAttachment,
                            isRecordingAudio: isRecordingAudio,
                            onRemove: onRemoveAttachment,
                          ),
                          const SizedBox(height: 10),
                        ],
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Container(
                                constraints: BoxConstraints(
                                  minHeight: sendSize,
                                ),
                                padding: EdgeInsets.fromLTRB(
                                  compact ? 7 : 9,
                                  compact ? 5 : 7,
                                  compact ? 7 : 9,
                                  compact ? 5 : 7,
                                ),
                                decoration: BoxDecoration(
                                  color: colors.composerSurface,
                                  borderRadius: BorderRadius.circular(
                                    sendSize / 2,
                                  ),
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
                                      duration: const Duration(
                                        milliseconds: 120,
                                      ),
                                      switchInCurve: Curves.easeOut,
                                      switchOutCurve: Curves.easeIn,
                                      child: hasText
                                          ? const SizedBox.shrink()
                                          : _InputIconButton(
                                              key: const ValueKey(
                                                'camera-tool',
                                              ),
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
                            _VoiceOrSendButton(
                              hasText: hasText,
                              hasSendableContent: hasSendableContent,
                              isRecordingAudio: isRecordingAudio,
                              dimension: sendSize,
                              onSend: onSend,
                              onVoiceMessage: onVoiceMessage,
                              onVoiceRecordingStart: onVoiceRecordingStart,
                              onVoiceRecordingStop: onVoiceRecordingStop,
                            ),
                          ],
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
                      onAudioRecording: onAudioRecording,
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

class _VoiceOrSendButton extends StatelessWidget {
  const _VoiceOrSendButton({
    required this.hasText,
    required this.hasSendableContent,
    required this.isRecordingAudio,
    required this.dimension,
    required this.onSend,
    required this.onVoiceMessage,
    required this.onVoiceRecordingStart,
    required this.onVoiceRecordingStop,
  });

  final bool hasText;
  final bool hasSendableContent;
  final bool isRecordingAudio;
  final double dimension;
  final VoidCallback onSend;
  final VoidCallback onVoiceMessage;
  final VoidCallback? onVoiceRecordingStart;
  final VoidCallback? onVoiceRecordingStop;

  @override
  Widget build(BuildContext context) {
    final colors = context.chatColors;

    final button = SizedBox.square(
      dimension: dimension,
      child: IconButton(
        tooltip: hasSendableContent ? 'Send' : 'Voice message',
        style: IconButton.styleFrom(
          padding: EdgeInsets.zero,
          backgroundColor: isRecordingAudio
              ? colors.incomingBubbleBorder
              : colors.accent,
          foregroundColor: colors.onAccentText,
          shape: const CircleBorder(),
          side: BorderSide(color: colors.outgoingBubbleBorder),
        ),
        onPressed: hasSendableContent ? onSend : onVoiceMessage,
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 120),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child: Icon(
            hasSendableContent ? Icons.send_rounded : Icons.mic_none,
            key: ValueKey('$hasSendableContent-$isRecordingAudio'),
            size: dimension < 50 ? 22 : 24,
          ),
        ),
      ),
    );

    if (hasSendableContent) return button;
    return GestureDetector(
      onLongPressStart: (_) => onVoiceRecordingStart?.call(),
      onLongPressEnd: (_) => onVoiceRecordingStop?.call(),
      onLongPressCancel: () => onVoiceRecordingStop?.call(),
      child: button,
    );
  }
}

class _ComposerAttachmentPreview extends StatelessWidget {
  const _ComposerAttachmentPreview({
    required this.attachment,
    required this.isRecordingAudio,
    required this.onRemove,
  });

  final ChatAttachment? attachment;
  final bool isRecordingAudio;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = context.chatColors;
    final attachment = this.attachment;

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 72),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colors.composerSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: isRecordingAudio
                ? const _PreviewLine(
                    icon: Icons.fiber_manual_record_rounded,
                    title: 'Recording audio',
                    subtitle: 'Release microphone to stop',
                  )
                : _AttachmentPreviewBody(attachment: attachment),
          ),
          if (attachment != null && onRemove != null)
            IconButton(
              tooltip: 'Remove attachment',
              onPressed: onRemove,
              icon: Icon(Icons.close_rounded, color: colors.icon),
            ),
        ],
      ),
    );
  }
}

class _AttachmentPreviewBody extends StatelessWidget {
  const _AttachmentPreviewBody({required this.attachment});

  final ChatAttachment? attachment;

  @override
  Widget build(BuildContext context) {
    final attachment = this.attachment;
    if (attachment == null) return const SizedBox.shrink();

    return switch (attachment) {
      DocumentAttachment(
        :final fileName,
        :final fileSizeBytes,
        :final mimeType,
      ) =>
        _PreviewLine(
          icon: Icons.description_outlined,
          title: fileName,
          subtitle: '${_formatBytes(fileSizeBytes)} - $mimeType',
        ),
      ImageAttachment(
        :final previewFile,
        :final fileSizeBytes,
        :final width,
        :final height,
      ) =>
        Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: SizedBox(
                width: 56,
                height: 56,
                child: previewFile == null
                    ? const Icon(Icons.image_outlined)
                    : Image.file(previewFile, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _PreviewText(
                title: 'Image',
                subtitle: '${width}x$height - ${_formatBytes(fileSizeBytes)}',
              ),
            ),
          ],
        ),
      ContactAttachment(:final name, :final phoneNumber) => _PreviewLine(
        icon: Icons.person_outline,
        title: name,
        subtitle: phoneNumber,
      ),
      LocationAttachment(:final latitude, :final longitude) => _PreviewLine(
        icon: Icons.location_on_outlined,
        title: 'Current Location',
        subtitle:
            'Lat: ${latitude.toStringAsFixed(6)}\nLng: ${longitude.toStringAsFixed(6)}',
      ),
      PollAttachment(:final question, :final options) => _PreviewLine(
        icon: Icons.poll_outlined,
        title: question,
        subtitle: options.join(' - '),
      ),
      EventAttachment(:final title, :final date, :final time) => _PreviewLine(
        icon: Icons.event_outlined,
        title: title,
        subtitle: '$date at $time',
      ),
      AudioAttachment(:final duration, :final fileSizeBytes) => _AudioPreview(
        duration: duration,
        fileSizeBytes: fileSizeBytes,
      ),
    };
  }
}

class _AudioPreview extends StatelessWidget {
  const _AudioPreview({required this.duration, required this.fileSizeBytes});

  final Duration duration;
  final int fileSizeBytes;

  @override
  Widget build(BuildContext context) {
    final colors = context.chatColors;
    return Row(
      children: [
        Icon(Icons.play_arrow_rounded, color: colors.icon, size: 30),
        const SizedBox(width: 8),
        Expanded(
          child: SizedBox(
            height: 34,
            child: CustomPaint(painter: _WaveformPlaceholderPainter(colors)),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '${_formatDuration(duration)}\n${_formatBytes(fileSizeBytes)}',
          textAlign: TextAlign.right,
          style: TextStyle(color: colors.secondaryText, fontSize: 11),
        ),
      ],
    );
  }
}

class _PreviewLine extends StatelessWidget {
  const _PreviewLine({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = context.chatColors;
    return Row(
      children: [
        Icon(icon, color: colors.icon, size: 30),
        const SizedBox(width: 12),
        Expanded(
          child: _PreviewText(title: title, subtitle: subtitle),
        ),
      ],
    );
  }
}

class _PreviewText extends StatelessWidget {
  const _PreviewText({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = context.chatColors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: colors.primaryText,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: colors.secondaryText,
            fontSize: 12,
            height: 1.2,
          ),
        ),
      ],
    );
  }
}

class _WaveformPlaceholderPainter extends CustomPainter {
  const _WaveformPlaceholderPainter(this.colors);

  final ChatThemeColors colors;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = colors.accent.withValues(alpha: 0.78)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 24; i++) {
      final x = (size.width / 23) * i;
      final height = 8 + ((i % 5) * 4);
      final center = size.height / 2;
      canvas.drawLine(
        Offset(x, center - height / 2),
        Offset(x, center + height / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPlaceholderPainter oldDelegate) {
    return oldDelegate.colors != colors;
  }
}

String _formatBytes(int bytes) {
  if (bytes <= 0) return '0 KB';
  if (bytes >= 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  return '${(bytes / 1024).ceil()} KB';
}

String _formatDuration(Duration duration) {
  final minutes = duration.inMinutes.remainder(60).toString();
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
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
