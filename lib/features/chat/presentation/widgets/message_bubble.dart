import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../models/chat_attachment.dart';
import '../../models/chat_models.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.text,
    required this.time,
    required this.isOutgoing,
    this.showReadReceipt = false,
    this.deliveryStatus,
    this.mediaType,
    this.localMediaPath,
    this.assetMediaPath,
    this.remoteMediaUrl,
    this.attachment,
  });

  final String text;
  final String time;
  final bool isOutgoing;
  final bool showReadReceipt;
  final String? deliveryStatus;
  final ChatMediaType? mediaType;
  final String? localMediaPath;
  final String? assetMediaPath;
  final String? remoteMediaUrl;
  final ChatAttachment? attachment;

  @override
  Widget build(BuildContext context) {
    final colors = context.chatColors;
    final maxWidth = MediaQuery.sizeOf(context).width * 0.68;

    return Align(
      alignment: isOutgoing ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth.clamp(188, 460)),
        margin: EdgeInsets.only(
          top: 6,
          bottom: 6,
          left: isOutgoing ? 54 : 0,
          right: isOutgoing ? 0 : 54,
        ),
        padding: EdgeInsets.fromLTRB(
          hasRichContent ? 6 : 18,
          hasRichContent ? 6 : 10,
          hasRichContent ? 6 : 15,
          10,
        ),
        decoration: BoxDecoration(
          color: isOutgoing ? colors.outgoingBubble : colors.incomingBubble,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(
            color: isOutgoing
                ? colors.outgoingBubbleBorder
                : colors.incomingBubbleBorder,
          ),
          boxShadow: [
            BoxShadow(
              color: colors.shadow,
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasMedia) ...[
              _BubbleMediaPreview(
                mediaType: mediaType!,
                localMediaPath: localMediaPath,
                assetMediaPath: assetMediaPath,
                remoteMediaUrl: remoteMediaUrl,
              ),
              if (text.isNotEmpty) const SizedBox(height: 9),
            ],
            if (attachment != null) ...[
              _BubbleAttachmentPreview(attachment: attachment!),
              if (text.isNotEmpty) const SizedBox(height: 9),
            ],
            if (text.isNotEmpty)
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: hasRichContent ? 8 : 0,
                ),
                child: Text(
                  text,
                  style: TextStyle(
                    color: isOutgoing
                        ? colors.onAccentText
                        : colors.primaryText,
                    fontSize: 15,
                    height: 1.22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: hasRichContent ? 8 : 0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    time,
                    style: TextStyle(
                      color: isOutgoing
                          ? colors.onAccentText.withValues(alpha: 0.7)
                          : colors.secondaryText,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (isOutgoing) ...[
                    const SizedBox(width: 8),
                    _DeliveryIndicator(
                      status: deliveryStatus,
                      fallbackRead: showReadReceipt,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool get hasMedia =>
      mediaType != null &&
      ((localMediaPath != null && localMediaPath!.isNotEmpty) ||
          (assetMediaPath != null && assetMediaPath!.isNotEmpty) ||
          (remoteMediaUrl != null && remoteMediaUrl!.isNotEmpty));

  bool get hasRichContent => hasMedia || attachment != null;
}

class _DeliveryIndicator extends StatelessWidget {
  const _DeliveryIndicator({required this.status, required this.fallbackRead});

  final String? status;
  final bool fallbackRead;

  @override
  Widget build(BuildContext context) {
    final colors = context.chatColors;
    final normalized = status?.toLowerCase().trim();

    final IconData icon;
    final Color color;
    switch (normalized) {
      case 'pending':
        icon = Icons.schedule_rounded;
        color = colors.onAccentText.withValues(alpha: 0.68);
      case 'failed':
        icon = Icons.error_outline_rounded;
        color = colors.incomingBubbleBorder;
      case 'read':
        icon = Icons.done_all_rounded;
        color = colors.readReceipt;
      case 'delivered':
        icon = Icons.done_all_rounded;
        color = colors.onAccentText.withValues(alpha: 0.68);
      case 'sent':
        icon = Icons.done_rounded;
        color = colors.onAccentText.withValues(alpha: 0.68);
      default:
        icon = fallbackRead ? Icons.done_all_rounded : Icons.done_rounded;
        color = fallbackRead
            ? colors.readReceipt
            : colors.onAccentText.withValues(alpha: 0.68);
    }

    return Icon(icon, size: 17, color: color);
  }
}

class _BubbleMediaPreview extends StatelessWidget {
  const _BubbleMediaPreview({
    required this.mediaType,
    this.localMediaPath,
    this.assetMediaPath,
    this.remoteMediaUrl,
  });

  final ChatMediaType mediaType;
  final String? localMediaPath;
  final String? assetMediaPath;
  final String? remoteMediaUrl;

  @override
  Widget build(BuildContext context) {
    final colors = context.chatColors;
    final width = MediaQuery.sizeOf(context).width;
    final previewWidth = (width * 0.56).clamp(176.0, 320.0);

    Widget preview;
    if (mediaType == ChatMediaType.file || mediaType == ChatMediaType.audio) {
      preview = _MediaIconPreview(mediaType: mediaType);
    } else if (mediaType == ChatMediaType.video) {
      preview = Stack(
        alignment: Alignment.center,
        children: [
          _ImageLikePreview(
            localMediaPath: localMediaPath,
            assetMediaPath: assetMediaPath,
            remoteMediaUrl: remoteMediaUrl,
            fallbackIcon: Icons.videocam_outlined,
          ),
          Icon(
            Icons.play_circle_fill_rounded,
            color: colors.glassSurface,
            size: 54,
          ),
        ],
      );
    } else {
      preview = _ImageLikePreview(
        localMediaPath: localMediaPath,
        assetMediaPath: assetMediaPath,
        remoteMediaUrl: remoteMediaUrl,
        fallbackIcon: Icons.image_outlined,
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(13),
      child: SizedBox(
        width: previewWidth,
        height: previewWidth * 0.78,
        child: preview,
      ),
    );
  }
}

class _MediaIconPreview extends StatelessWidget {
  const _MediaIconPreview({required this.mediaType});

  final ChatMediaType mediaType;

  @override
  Widget build(BuildContext context) {
    final colors = context.chatColors;
    final icon = mediaType == ChatMediaType.audio
        ? Icons.play_arrow_rounded
        : Icons.description_outlined;
    final label = mediaType == ChatMediaType.audio ? 'Voice message' : 'File';
    return ColoredBox(
      color: colors.composerButtonSurface,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: colors.icon, size: 42),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: colors.primaryText,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageLikePreview extends StatelessWidget {
  const _ImageLikePreview({
    required this.fallbackIcon,
    this.localMediaPath,
    this.assetMediaPath,
    this.remoteMediaUrl,
  });

  final IconData fallbackIcon;
  final String? localMediaPath;
  final String? assetMediaPath;
  final String? remoteMediaUrl;

  @override
  Widget build(BuildContext context) {
    final colors = context.chatColors;
    final local = localMediaPath;
    final asset = assetMediaPath;
    final remote = remoteMediaUrl;

    if (local != null && local.isNotEmpty) {
      return Image.file(File(local), fit: BoxFit.cover);
    }
    if (asset != null && asset.isNotEmpty) {
      return Image.asset(asset, fit: BoxFit.cover);
    }
    if (remote != null && remote.isNotEmpty) {
      return Image.network(remote, fit: BoxFit.cover);
    }
    return ColoredBox(
      color: colors.composerButtonSurface,
      child: Icon(fallbackIcon, color: colors.mutedIcon, size: 44),
    );
  }
}

class _BubbleAttachmentPreview extends StatelessWidget {
  const _BubbleAttachmentPreview({required this.attachment});

  final ChatAttachment attachment;

  @override
  Widget build(BuildContext context) {
    final colors = context.chatColors;
    final width = MediaQuery.sizeOf(context).width;
    final previewWidth = (width * 0.56).clamp(176.0, 320.0);
    final data = _attachmentPreviewData(attachment);

    return Container(
      width: previewWidth,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.composerButtonSurface,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: colors.softBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(data.icon, color: colors.icon, size: 30),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.primaryText,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (data.subtitle.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    data.subtitle,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.secondaryText,
                      fontSize: 12,
                      height: 1.25,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

({IconData icon, String title, String subtitle}) _attachmentPreviewData(
  ChatAttachment attachment,
) {
  return switch (attachment) {
    ContactAttachment(:final name, :final phoneNumber) => (
      icon: Icons.person_outline,
      title: name.isEmpty ? 'Contact' : name,
      subtitle: phoneNumber,
    ),
    LocationAttachment(:final latitude, :final longitude) => (
      icon: Icons.location_on_outlined,
      title: 'Current Location',
      subtitle:
          'Lat: ${latitude.toStringAsFixed(6)}\nLng: ${longitude.toStringAsFixed(6)}',
    ),
    PollAttachment(:final question, :final options) => (
      icon: Icons.poll_outlined,
      title: question,
      subtitle: options.join('\n'),
    ),
    EventAttachment(
      :final title,
      :final date,
      :final time,
      :final description,
    ) =>
      (
        icon: Icons.event_outlined,
        title: title,
        subtitle: [
          '$date at $time',
          if (description.isNotEmpty) description,
        ].join('\n'),
      ),
    DocumentAttachment(
      :final fileName,
      :final fileSizeBytes,
      :final mimeType,
    ) =>
      (
        icon: Icons.description_outlined,
        title: fileName,
        subtitle: '${_formatBytes(fileSizeBytes)} - $mimeType',
      ),
    ImageAttachment(:final fileSizeBytes, :final width, :final height) => (
      icon: Icons.image_outlined,
      title: 'Image',
      subtitle: '${width}x$height - ${_formatBytes(fileSizeBytes)}',
    ),
    AudioAttachment(:final duration, :final fileSizeBytes) => (
      icon: Icons.play_arrow_rounded,
      title: 'Voice message',
      subtitle: '${_formatDuration(duration)} - ${_formatBytes(fileSizeBytes)}',
    ),
  };
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
