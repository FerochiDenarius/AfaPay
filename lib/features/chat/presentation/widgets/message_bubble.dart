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
    this.mediaType,
    this.localMediaPath,
    this.assetMediaPath,
    this.remoteMediaUrl,
  });

  final String text;
  final String time;
  final bool isOutgoing;
  final bool showReadReceipt;
  final ChatMediaType? mediaType;
  final String? localMediaPath;
  final String? assetMediaPath;
  final String? remoteMediaUrl;

  @override
  Widget build(BuildContext context) {
    final colors = context.chatColors;
    final maxWidth = MediaQuery.sizeOf(context).width * 0.7;

    return Align(
      alignment: isOutgoing ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth.clamp(188, 460)),
        margin: EdgeInsets.only(
          top: 6,
          bottom: 6,
          left: isOutgoing ? 46 : 0,
          right: isOutgoing ? 0 : 46,
        ),
        padding: EdgeInsets.fromLTRB(
          hasMedia ? 6 : 18,
          hasMedia ? 6 : 11,
          hasMedia ? 6 : 16,
          11,
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
            if (text.isNotEmpty)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: hasMedia ? 8 : 0),
                child: Text(
                  text,
                  style: TextStyle(
                    color: isOutgoing
                        ? colors.onAccentText
                        : colors.primaryText,
                    fontSize: 16,
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
                    time,
                    style: TextStyle(
                      color: isOutgoing
                          ? colors.onAccentText.withValues(alpha: 0.7)
                          : colors.secondaryText,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (showReadReceipt) ...[
                    const SizedBox(width: 8),
                    Icon(
                      Icons.done_all_rounded,
                      size: 20,
                      color: colors.readReceipt,
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
