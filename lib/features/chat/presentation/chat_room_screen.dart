import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../models/chat_models.dart';
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

  bool _showEmojiMenu = true;
  bool _showAttachmentMenu = false;
  List<_MockChatMessage> _messages = List.of(_mockMessages);

  @override
  void dispose() {
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

  @override
  Widget build(BuildContext context) {
    final colors = context.chatColors;
    final title = widget.conversation?.title ?? 'denarius';
    final isOnline = widget.conversation?.participant?.isOnline ?? true;
    final avatarUrl = widget.conversation?.imageUrl;

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
                onCameraPressed: () => _showTemporaryAction('Camera'),
                onEmojiButtonPressed: () {
                  setState(() {
                    _showEmojiMenu = !_showEmojiMenu;
                    _showAttachmentMenu = false;
                  });
                },
                onDocument: () => _showToast('Document'),
                onGallery: () => _showToast('Gallery'),
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
  });

  final String text;
  final String time;
  final bool isOutgoing;
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
