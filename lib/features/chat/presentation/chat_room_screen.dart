import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../models/chat_media_draft.dart';
import '../models/chat_models.dart';
import '../repositories/chat_repository.dart';
import 'chat_media_picker_screen.dart';
import 'widgets/chat_header.dart';
import 'widgets/message_bubble.dart';
import 'widgets/message_input_bar.dart';

class ChatRoomScreen extends StatefulWidget {
  const ChatRoomScreen({super.key, required this.roomId, this.conversation});

  final String roomId;
  final ChatConversation? conversation;

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final _messageController = TextEditingController();
  final _inputFocusNode = FocusNode();
  final _scrollController = ScrollController();
  final _repository = ChatRepository();

  bool _showEmojiMenu = true;
  bool _showAttachmentMenu = false;
  bool _sendingMedia = false;
  Timer? _presenceTimer;
  ChatConversation? _conversation;
  List<_MockChatMessage> _messages = List.of(_mockMessages);

  @override
  void initState() {
    super.initState();
    _conversation = widget.conversation;
    _presenceTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _refreshPresence(),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshPresence());
  }

  @override
  void dispose() {
    _presenceTimer?.cancel();
    _messageController.dispose();
    _inputFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _showToast(String label) {
    setState(() {
      _showEmojiMenu = false;
      _showAttachmentMenu = false;
    });
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(label)));
  }

  void _showTemporaryAction(String label) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(label)));
  }

  void _sendMockMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages = [
        ..._messages,
        _MockChatMessage(
          text: text,
          time: TimeOfDay.now().format(context),
          isOutgoing: true,
        ),
      ];
      _messageController.clear();
      _showEmojiMenu = false;
      _showAttachmentMenu = false;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _refreshPresence() async {
    final current = _conversation ?? widget.conversation;
    if (current == null || !mounted) return;
    try {
      final rooms = current.isGroup
          ? await _repository.fetchGroups()
          : await _repository.fetchPrivateChats();
      if (!mounted) return;
      for (final room in rooms) {
        if (room.id == widget.roomId) {
          setState(() => _conversation = room);
          return;
        }
      }
    } on Object {
      // Presence refresh is best-effort; chat UI should remain usable offline.
    }
  }

  Future<void> _openMediaPicker() async {
    setState(() {
      _showAttachmentMenu = false;
      _showEmojiMenu = false;
    });
    final title = (_conversation ?? widget.conversation)?.title ?? 'denarius';
    final draft = await Navigator.of(context).push<ChatMediaDraft>(
      MaterialPageRoute(
        builder: (_) => ChatMediaPickerScreen(recipientName: title),
        fullscreenDialog: true,
      ),
    );
    if (draft == null || !mounted) return;
    await _sendMediaDraft(draft);
  }

  Future<void> _sendMediaDraft(ChatMediaDraft draft) async {
    if (_sendingMedia) return;
    final now = TimeOfDay.now().format(context);
    final localMessage = _MockChatMessage(
      text: draft.caption,
      time: now,
      isOutgoing: true,
      mediaType: draft.type,
      localMediaPath: draft.filePath,
      assetMediaPath: draft.assetPath,
    );

    setState(() {
      _sendingMedia = true;
      _messages = [..._messages, localMessage];
    });
    _scrollToBottom();

    if (!draft.isDeviceFile) {
      setState(() => _sendingMedia = false);
      return;
    }

    try {
      final upload = await _repository.uploadChatMedia(
        filePath: draft.filePath!,
        type: draft.type,
      );
      await _repository.sendMediaMessage(
        roomId: widget.roomId,
        upload: upload,
        text: draft.caption,
      );
    } on ChatAuthExpiredException {
      if (!mounted) return;
      _showTemporaryAction('Media added locally. Sign in again to send it.');
    } on ChatApiException catch (error) {
      if (!mounted) return;
      _showTemporaryAction('Media added locally. ${error.message}');
    } on Object {
      if (!mounted) return;
      _showTemporaryAction('Media added locally. Backend send failed.');
    } finally {
      if (mounted) setState(() => _sendingMedia = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.chatColors;
    final conversation = _conversation ?? widget.conversation;
    final title = conversation?.title ?? 'denarius';
    final isOnline = conversation?.participant?.isOnline ?? true;
    final avatarUrl = conversation?.imageUrl;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: colors.background,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [colors.background, colors.backgroundSecondary],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              ChatHeader(
                username: title,
                avatarUrl: avatarUrl,
                isOnline: isOnline,
                onBack: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/chats');
                  }
                },
                onCall: () => context.push('/voice-call'),
                onVideoCall: () => context.push('/video-call'),
                onMore: () => _showTemporaryAction('More'),
              ),
              Expanded(
                child: _MessageArea(
                  messages: _messages,
                  scrollController: _scrollController,
                  onTap: () {
                    if (_showEmojiMenu || _showAttachmentMenu) {
                      setState(() {
                        _showEmojiMenu = false;
                        _showAttachmentMenu = false;
                      });
                    }
                    _inputFocusNode.unfocus();
                  },
                ),
              ),
              MessageInputBar(
                controller: _messageController,
                focusNode: _inputFocusNode,
                showEmojiMenu: _showEmojiMenu,
                showAttachmentMenu: _showAttachmentMenu,
                onAttachmentPressed: () {
                  setState(() {
                    _showAttachmentMenu = !_showAttachmentMenu;
                    _showEmojiMenu = false;
                  });
                },
                onCameraPressed: _openMediaPicker,
                onEmojiButtonPressed: () {
                  setState(() {
                    _showEmojiMenu = !_showEmojiMenu;
                    _showAttachmentMenu = false;
                  });
                },
                onDocument: () => _showToast('Document'),
                onGallery: _openMediaPicker,
                onContact: () => _showToast('Contact'),
                onLocation: () => _showToast('Location'),
                onPoll: () => _showToast('Poll'),
                onEvent: () => _showToast('Event'),
                onEmoji: () => _showToast('Emoji'),
                onGif: () => _showToast('GIF'),
                onSticker: () => _showToast('Sticker'),
                onSend: _sendMockMessage,
                onVoiceMessage: () => _showToast('Voice message'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageArea extends StatelessWidget {
  const _MessageArea({
    required this.messages,
    required this.scrollController,
    required this.onTap,
  });

  final List<_MockChatMessage> messages;
  final ScrollController scrollController;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final horizontalPadding = width >= 700 ? 40.0 : 24.0;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: onTap,
      child: ListView(
        controller: scrollController,
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          22,
          horizontalPadding,
          16,
        ),
        children: [
          const _DateDivider(label: 'Today'),
          const SizedBox(height: 12),
          for (final message in messages)
            MessageBubble(
              text: message.text,
              time: message.time,
              isOutgoing: message.isOutgoing,
              showReadReceipt: message.isOutgoing,
              mediaType: message.mediaType,
              localMediaPath: message.localMediaPath,
              assetMediaPath: message.assetMediaPath,
            ),
        ],
      ),
    );
  }
}

class _DateDivider extends StatelessWidget {
  const _DateDivider({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.chatColors;

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 7),
        decoration: BoxDecoration(
          color: colors.glassSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: colors.secondaryText,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _MockChatMessage {
  const _MockChatMessage({
    required this.text,
    required this.time,
    required this.isOutgoing,
    this.mediaType,
    this.localMediaPath,
    this.assetMediaPath,
  });

  final String text;
  final String time;
  final bool isOutgoing;
  final ChatMediaType? mediaType;
  final String? localMediaPath;
  final String? assetMediaPath;
}

const _mockMessages = [
  _MockChatMessage(text: 'hi', time: '11:30 AM', isOutgoing: true),
  _MockChatMessage(text: 'how are you', time: '11:30 AM', isOutgoing: true),
  _MockChatMessage(
    text: 'am fine and you',
    time: '11:30 AM',
    isOutgoing: false,
  ),
  _MockChatMessage(text: 'sup for today', time: '11:31 AM', isOutgoing: true),
  _MockChatMessage(text: 'nothing much', time: '11:31 AM', isOutgoing: false),
  _MockChatMessage(
    text: 'ok preparing for class ?',
    time: '11:31 AM',
    isOutgoing: true,
  ),
  _MockChatMessage(
    text: 'no am at the bank',
    time: '11:31 AM',
    isOutgoing: false,
  ),
  _MockChatMessage(text: 'kk', time: '11:32 AM', isOutgoing: true),
  _MockChatMessage(
    text: 'ok I will hit you up when am done',
    time: '11:32 AM',
    isOutgoing: false,
  ),
];

class ChatRoomDarkPreview extends StatelessWidget {
  const ChatRoomDarkPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildAfaPayTheme(Brightness.dark),
      home: const ChatRoomScreen(roomId: 'preview'),
    );
  }
}

class ChatRoomLightPreview extends StatelessWidget {
  const ChatRoomLightPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildAfaPayTheme(Brightness.light),
      home: const ChatRoomScreen(roomId: 'preview'),
    );
  }
}
