import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
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
    this.replyPreview,
    this.isEdited = false,
    this.onLongPress,
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
  final String? replyPreview;
  final bool isEdited;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final colors = context.chatColors;
    final maxWidth = MediaQuery.sizeOf(context).width * 0.68;

    return GestureDetector(
      onLongPress: onLongPress,
      child: Align(
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
          hasMedia ? 6 : 18,
          hasMedia ? 6 : 10,
          hasMedia ? 6 : 15,
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
            if (replyPreview != null) ...[
              Container(
                width: double.infinity,
                margin: EdgeInsets.fromLTRB(hasMedia ? 8 : 0, 0, hasMedia ? 8 : 0, 8),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: colors.glassSurface.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(8),
                  border: Border(
                    left: BorderSide(color: colors.accent, width: 3),
                  ),
                ),
                child: Text(
                  replyPreview!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isOutgoing
                        ? colors.onAccentText.withValues(alpha: 0.78)
                        : colors.secondaryText,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
            if (hasMedia) ...[
              _BubbleMediaPreview(
                mediaType: mediaType!,
                localMediaPath: localMediaPath,
                assetMediaPath: assetMediaPath,
                remoteMediaUrl: remoteMediaUrl,
              ),
              if (text.isNotEmpty) const SizedBox(height: 9),
            ],
            if (text.isNotEmpty)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: hasMedia ? 8 : 0),
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
              padding: EdgeInsets.symmetric(horizontal: hasMedia ? 8 : 0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isEdited ? '$time edited' : time,
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
      ),
    );
  }

  bool get hasMedia =>
      mediaType != null &&
      ((localMediaPath != null && localMediaPath!.isNotEmpty) ||
          (assetMediaPath != null && assetMediaPath!.isNotEmpty) ||
          (remoteMediaUrl != null && remoteMediaUrl!.isNotEmpty));
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
    if (mediaType == ChatMediaType.video) {
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
