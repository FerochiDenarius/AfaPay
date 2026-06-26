import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_theme.dart';
import '../models/chat_media_draft.dart';
import '../models/chat_models.dart';
import 'chat_media_editor_screen.dart';

class ChatMediaPickerScreen extends StatefulWidget {
  const ChatMediaPickerScreen({
    super.key,
    required this.recipientName,
    this.autoOpenDevicePicker = false,
  });

  final String recipientName;
  final bool autoOpenDevicePicker;

  @override
  State<ChatMediaPickerScreen> createState() => _ChatMediaPickerScreenState();
}

class _ChatMediaPickerScreenState extends State<ChatMediaPickerScreen> {
  final _captionController = TextEditingController();
  final _picker = ImagePicker();

  bool _openingDeviceMedia = false;

  @override
  void initState() {
    super.initState();
    if (widget.autoOpenDevicePicker) {
      unawaited(
        WidgetsBinding.instance.endOfFrame.then((_) {
          if (mounted) return _pickDeviceMedia();
        }),
      );
    }
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _pickDeviceMedia() async {
    if (_openingDeviceMedia) return;
    setState(() => _openingDeviceMedia = true);
    try {
      final media = await _picker.pickMedia();
      if (media == null || !mounted) return;

      final type = mediaTypeForPickedFile(
        mimeType: media.mimeType,
        fileName: media.name,
        filePath: media.path,
      );
      final draft = ChatMediaDraft(
        type: type,
        filePath: media.path,
        caption: _captionController.text.trim(),
        name: media.name,
        mimeType: media.mimeType,
      );
      await _openEditor(draft);
    } finally {
      if (mounted) setState(() => _openingDeviceMedia = false);
    }
  }

  Future<void> _openEditor(ChatMediaDraft draft) async {
    final edited = await Navigator.of(context).push<ChatMediaDraft>(
      MaterialPageRoute(
        builder: (_) => ChatMediaEditorScreen(
          initialDraft: draft,
          recipientName: widget.recipientName,
        ),
      ),
    );
    if (edited != null && mounted) {
      context.pop(edited);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.chatColors;

    return Scaffold(
      backgroundColor: colors.background.withValues(alpha: 0.62),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const SizedBox(height: 84),
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                child: ColoredBox(
                  color: colors.backgroundSecondary,
                  child: Column(
                    children: [
                      const SizedBox(height: 14),
                      Container(
                        width: 56,
                        height: 6,
                        decoration: BoxDecoration(
                          color: colors.placeholderText,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 18, 14, 16),
                        child: Row(
                          children: [
                            IconButton(
                              tooltip: 'Close media picker',
                              onPressed: () => context.pop(),
                              icon: Icon(
                                Icons.close_rounded,
                                color: colors.icon,
                                size: 36,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              'Gallery',
                              style: TextStyle(
                                color: colors.primaryText,
                                fontSize: 30,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              width: 36,
                              height: 36,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: colors.icon,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'HD',
                                style: TextStyle(
                                  color: colors.icon,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: _DeviceMediaTile(
                            busy: _openingDeviceMedia,
                            onTap: _pickDeviceMedia,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 18),
                        color: colors.backgroundSecondary,
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 58,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                decoration: BoxDecoration(
                                  color: colors.composerSurface,
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(color: colors.border),
                                ),
                                child: TextField(
                                  controller: _captionController,
                                  cursorColor: colors.cursor,
                                  style: TextStyle(
                                    color: colors.primaryText,
                                    fontSize: 22,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Add a caption...',
                                    hintStyle: TextStyle(
                                      color: colors.placeholderText,
                                      fontSize: 22,
                                    ),
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    filled: false,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox.square(
                              dimension: 66,
                              child: IconButton(
                                tooltip: 'Open device gallery',
                                style: IconButton.styleFrom(
                                  backgroundColor: colors.onAccentText,
                                  foregroundColor: colors.glassSurface,
                                  shape: const CircleBorder(),
                                ),
                                onPressed: _openingDeviceMedia
                                    ? null
                                    : _pickDeviceMedia,
                                icon: const Icon(
                                  Icons.photo_library_outlined,
                                  size: 34,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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

ChatMediaType mediaTypeForPickedFile({
  String? mimeType,
  String? fileName,
  String? filePath,
}) {
  final normalizedMime = mimeType?.toLowerCase() ?? '';
  if (normalizedMime.startsWith('video/')) return ChatMediaType.video;
  if (normalizedMime.startsWith('image/')) return ChatMediaType.image;

  final source = '${fileName ?? ''} ${filePath ?? ''}'.toLowerCase();
  if (RegExp(r'\.(mp4|mov|m4v|webm|3gp|mkv)\b').hasMatch(source)) {
    return ChatMediaType.video;
  }
  return ChatMediaType.image;
}

class _DeviceMediaTile extends StatelessWidget {
  const _DeviceMediaTile({required this.busy, required this.onTap});

  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.chatColors;

    return InkWell(
      onTap: busy ? null : onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 220,
        height: 180,
        decoration: BoxDecoration(
          color: colors.strongGlassSurface,
          border: Border.all(color: colors.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: busy
              ? CircularProgressIndicator(color: colors.accent)
              : Icon(
                  Icons.photo_library_outlined,
                  color: colors.accent,
                  size: 64,
                ),
        ),
      ),
    );
  }
}
