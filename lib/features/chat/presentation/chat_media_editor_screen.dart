import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

import '../../../core/theme/app_theme.dart';
import '../models/chat_media_draft.dart';
import '../models/chat_models.dart';

class ChatMediaEditorScreen extends StatefulWidget {
  const ChatMediaEditorScreen({
    super.key,
    required this.initialDraft,
    required this.recipientName,
  });

  final ChatMediaDraft initialDraft;
  final String recipientName;

  @override
  State<ChatMediaEditorScreen> createState() => _ChatMediaEditorScreenState();
}

class _ChatMediaEditorScreenState extends State<ChatMediaEditorScreen> {
  late final TextEditingController _captionController;
  VideoPlayerController? _videoController;

  @override
  void initState() {
    super.initState();
    _captionController = TextEditingController(
      text: widget.initialDraft.caption,
    );
    if (widget.initialDraft.type == ChatMediaType.video &&
        widget.initialDraft.filePath != null) {
      _videoController =
          VideoPlayerController.file(File(widget.initialDraft.filePath!))
            ..initialize().then((_) {
              if (mounted) setState(() {});
            });
    }
  }

  @override
  void dispose() {
    _captionController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  void _send() {
    context.pop(
      widget.initialDraft.copyWith(caption: _captionController.text.trim()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.chatColors;

    return Scaffold(
      backgroundColor: colors.onAccentText,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: Row(
                children: [
                  _EditorToolButton(
                    tooltip: 'Close',
                    icon: Icons.close_rounded,
                    onPressed: () => context.pop(),
                  ),
                  const Spacer(),
                  _EditorToolButton(
                    tooltip: 'Download',
                    icon: Icons.file_download_outlined,
                    onPressed: () {},
                  ),
                  _EditorToolButton(
                    tooltip: 'HD',
                    label: 'HD',
                    onPressed: () {},
                  ),
                  _EditorToolButton(
                    tooltip: 'Crop',
                    icon: Icons.crop_rotate_rounded,
                    onPressed: () {},
                  ),
                  _EditorToolButton(
                    tooltip: 'Sticker',
                    icon: Icons.sticky_note_2_outlined,
                    onPressed: () {},
                  ),
                  _EditorToolButton(
                    tooltip: 'Text',
                    label: 'Aa',
                    onPressed: () {},
                  ),
                  _EditorToolButton(
                    tooltip: 'Draw',
                    icon: Icons.edit_outlined,
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 0),
                  child: _MediaPreview(
                    draft: widget.initialDraft,
                    videoController: _videoController,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 58),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: colors.strongGlassSurface,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: colors.border),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.add_photo_alternate_outlined,
                            color: colors.icon,
                            size: 26,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _captionController,
                              cursorColor: colors.cursor,
                              style: TextStyle(
                                color: colors.primaryText,
                                fontSize: 20,
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Add a caption...',
                                hintStyle: TextStyle(
                                  color: colors.placeholderText,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w500,
                                ),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                                filled: false,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.timer_outlined,
                            color: colors.icon,
                            size: 28,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  SizedBox.square(
                    dimension: 64,
                    child: IconButton(
                      tooltip: 'Send media',
                      style: IconButton.styleFrom(
                        backgroundColor: colors.glassSurface,
                        foregroundColor: colors.icon,
                        shape: const CircleBorder(),
                      ),
                      onPressed: _send,
                      icon: const Icon(Icons.send_rounded, size: 34),
                    ),
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: colors.strongGlassSurface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: colors.border),
                  ),
                  child: Text(
                    widget.recipientName,
                    style: TextStyle(
                      color: colors.primaryText,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditorToolButton extends StatelessWidget {
  const _EditorToolButton({
    required this.tooltip,
    required this.onPressed,
    this.icon,
    this.label,
  });

  final String tooltip;
  final VoidCallback onPressed;
  final IconData? icon;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final colors = context.chatColors;

    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: SizedBox.square(
        dimension: 50,
        child: IconButton(
          tooltip: tooltip,
          style: IconButton.styleFrom(
            backgroundColor: colors.strongGlassSurface,
            foregroundColor: colors.icon,
            shape: const CircleBorder(),
          ),
          onPressed: onPressed,
          icon: icon == null
              ? Text(
                  label ?? '',
                  style: TextStyle(
                    color: colors.icon,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                )
              : Icon(icon, size: 27),
        ),
      ),
    );
  }
}

class _MediaPreview extends StatelessWidget {
  const _MediaPreview({required this.draft, required this.videoController});

  final ChatMediaDraft draft;
  final VideoPlayerController? videoController;

  @override
  Widget build(BuildContext context) {
    final colors = context.chatColors;
    final radius = BorderRadius.circular(2);

    if (draft.type == ChatMediaType.video) {
      final controller = videoController;
      final ready = controller != null && controller.value.isInitialized;
      return Stack(
        alignment: Alignment.center,
        children: [
          ClipRRect(
            borderRadius: radius,
            child: ready
                ? AspectRatio(
                    aspectRatio: controller.value.aspectRatio,
                    child: VideoPlayer(controller),
                  )
                : Container(
                    width: double.infinity,
                    height: 320,
                    color: colors.background,
                  ),
          ),
          Icon(
            Icons.play_circle_fill_rounded,
            color: colors.glassSurface,
            size: 72,
          ),
        ],
      );
    }

    final filePath = draft.filePath;
    final assetPath = draft.assetPath;
    final image = filePath != null
        ? Image.file(File(filePath), fit: BoxFit.contain)
        : assetPath != null
        ? Image.asset(assetPath, fit: BoxFit.contain)
        : Icon(Icons.image_outlined, color: colors.icon, size: 88);

    return ClipRRect(borderRadius: radius, child: image);
  }
}
