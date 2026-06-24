import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_theme.dart';
import '../models/chat_media_draft.dart';
import '../models/chat_models.dart';
import 'chat_media_editor_screen.dart';

class ChatMediaPickerScreen extends StatefulWidget {
  const ChatMediaPickerScreen({super.key, required this.recipientName});

  final String recipientName;

  @override
  State<ChatMediaPickerScreen> createState() => _ChatMediaPickerScreenState();
}

class _ChatMediaPickerScreenState extends State<ChatMediaPickerScreen> {
  final _captionController = TextEditingController();
  final _picker = ImagePicker();
  ChatMediaDraft? _selected;

  static const _assetTiles = [
    'UIdesignImages/mediaPicker2.jpeg',
    'UIdesignImages/mainPageLightTheme.png',
    'UIdesignImages/loginLightTheme.png',
    'UIdesignImages/loginPage.png',
    'UIdesignImages/logo.png',
    'UIdesignImages/logoEmblem.png',
    'UIdesignImages/registrationsPage.png',
    'UIdesignImages/EmailEntryPage.png',
    'UIdesignImages/EmailCodePage.png',
  ];

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _pickDeviceMedia() async {
    final media = await _picker.pickMedia();
    if (media == null || !mounted) return;

    final mimeType = media.mimeType ?? '';
    final type = mimeType.startsWith('video/')
        ? ChatMediaType.video
        : ChatMediaType.image;
    final draft = ChatMediaDraft(
      type: type,
      filePath: media.path,
      caption: _captionController.text.trim(),
      name: media.name,
      mimeType: media.mimeType,
    );
    await _openEditor(draft);
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

  void _selectAsset(String assetPath) {
    setState(() {
      _selected = ChatMediaDraft(
        type: ChatMediaType.image,
        assetPath: assetPath,
        caption: _captionController.text.trim(),
        name: assetPath.split('/').last,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.chatColors;
    final selected = _selected;

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
                              'Recents',
                              style: TextStyle(
                                color: colors.primaryText,
                                fontSize: 30,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Icon(
                              Icons.arrow_drop_down_rounded,
                              color: colors.icon,
                              size: 34,
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
                        child: GridView.builder(
                          padding: EdgeInsets.zero,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 3,
                                mainAxisSpacing: 3,
                              ),
                          itemCount: _assetTiles.length + 1,
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              return _DeviceMediaTile(onTap: _pickDeviceMedia);
                            }
                            final asset = _assetTiles[index - 1];
                            final isSelected = selected?.assetPath == asset;
                            return _AssetMediaTile(
                              assetPath: asset,
                              selected: isSelected,
                              selectedIndex: isSelected ? 1 : null,
                              onTap: () => _selectAsset(asset),
                            );
                          },
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 18),
                        color: colors.backgroundSecondary,
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: selected == null
                                  ? null
                                  : () => _openEditor(
                                      selected.copyWith(
                                        caption: _captionController.text.trim(),
                                      ),
                                    ),
                              child: _SelectedThumbnail(draft: selected),
                            ),
                            const SizedBox(width: 12),
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
                            Container(
                              width: 50,
                              height: 50,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: colors.icon,
                                  width: 2,
                                ),
                              ),
                              child: Text(
                                selected == null ? '0' : '1',
                                style: TextStyle(
                                  color: colors.icon,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox.square(
                              dimension: 66,
                              child: IconButton(
                                tooltip: 'Open media editor',
                                style: IconButton.styleFrom(
                                  backgroundColor: colors.onAccentText,
                                  foregroundColor: colors.glassSurface,
                                  shape: const CircleBorder(),
                                ),
                                onPressed: selected == null
                                    ? null
                                    : () => _openEditor(
                                        selected.copyWith(
                                          caption: _captionController.text
                                              .trim(),
                                        ),
                                      ),
                                icon: const Icon(Icons.send_rounded, size: 34),
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

class _DeviceMediaTile extends StatelessWidget {
  const _DeviceMediaTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.chatColors;

    return InkWell(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.strongGlassSurface,
          border: Border.all(color: colors.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_library_outlined, color: colors.accent, size: 36),
            const SizedBox(height: 8),
            Text(
              'Device media',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.primaryText,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AssetMediaTile extends StatelessWidget {
  const _AssetMediaTile({
    required this.assetPath,
    required this.selected,
    required this.onTap,
    this.selectedIndex,
  });

  final String assetPath;
  final bool selected;
  final VoidCallback onTap;
  final int? selectedIndex;

  @override
  Widget build(BuildContext context) {
    final colors = context.chatColors;

    return InkWell(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(assetPath, fit: BoxFit.cover),
          if (selected)
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: colors.accent, width: 3),
              ),
            ),
          if (selectedIndex != null)
            Align(
              alignment: Alignment.topRight,
              child: Container(
                width: 34,
                height: 34,
                margin: const EdgeInsets.all(8),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.onAccentText,
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.glassSurface, width: 2),
                ),
                child: Text(
                  selectedIndex.toString(),
                  style: TextStyle(
                    color: colors.glassSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SelectedThumbnail extends StatelessWidget {
  const _SelectedThumbnail({required this.draft});

  final ChatMediaDraft? draft;

  @override
  Widget build(BuildContext context) {
    final colors = context.chatColors;
    final item = draft;

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: colors.composerButtonSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: item == null
          ? Icon(Icons.photo_outlined, color: colors.mutedIcon)
          : item.filePath != null
          ? Image.file(File(item.filePath!), fit: BoxFit.cover)
          : Image.asset(item.assetPath!, fit: BoxFit.cover),
    );
  }
}
