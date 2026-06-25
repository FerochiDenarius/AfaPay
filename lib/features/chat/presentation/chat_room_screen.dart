import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../models/chat_media_draft.dart';
import '../models/chat_models.dart';
import '../models/chat_room_settings.dart';
import '../repositories/chat_repository.dart';
import '../services/chat_realtime_service.dart';
import 'chat_media_picker_screen.dart';
import 'widgets/chat_header.dart';
import 'widgets/chat_theme_sheet.dart';
import 'widgets/disappearing_messages_sheet.dart';
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
  final _realtime = ChatRealtimeService();

  bool _showEmojiMenu = false;
  bool _showAttachmentMenu = false;
  bool _sendingMedia = false;
  bool _isLoadingMessages = false;
  bool _peerTyping = false;
  String? _messageError;
  String? _currentUserId;
  Timer? _presenceTimer;
  Timer? _typingTimer;
  Timer? _peerTypingTimer;
  ChatConversation? _conversation;
  ChatRoomSettings _settings = ChatRoomSettings.defaults;
  _DisplayChatMessage? _replyingTo;
  late List<_DisplayChatMessage> _messages;

  bool get _isPreviewRoom =>
      widget.roomId == 'preview' || widget.roomId.isEmpty;

  @override
  void initState() {
    super.initState();
    _conversation = widget.conversation;
    _messages = _isPreviewRoom
        ? List.of(_mockMessages)
        : <_DisplayChatMessage>[];
    _presenceTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _refreshPresence(),
    );
    _messageController.addListener(_handleTypingChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshPresence();
      _loadMessages();
      _loadSettings();
      _connectRealtime();
    });
  }

  @override
  void dispose() {
    _presenceTimer?.cancel();
    _typingTimer?.cancel();
    _peerTypingTimer?.cancel();
    _realtime.disconnect(widget.roomId);
    _messageController.dispose();
    _inputFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _connectRealtime() async {
    if (_isPreviewRoom) return;
    await _realtime.connect(
      roomId: widget.roomId,
      onMessageCreated: (payload) {
        final message = ChatMessage.fromJson(payload);
        final currentUserId = _currentUserId;
        if (!mounted || _messages.any((item) => item.id == message.id)) return;
        setState(() {
          _messages = [
            ..._messages,
            _DisplayChatMessage.fromChatMessage(
              message,
              currentUserId: currentUserId,
            ),
          ];
        });
        _scrollToBottom();
        unawaited(_repository.markAsRead(widget.roomId));
      },
      onMessageEdited: (payload) {
        final message = ChatMessage.fromJson(payload);
        if (!mounted) return;
        setState(() {
          _messages = _messages
              .map(
                (item) => item.id == message.id
                    ? _DisplayChatMessage.fromChatMessage(
                        message,
                        currentUserId: _currentUserId,
                      )
                    : item,
              )
              .toList();
        });
      },
      onMessageDeleted: (messageId) {
        if (!mounted || messageId.isEmpty) return;
        setState(() {
          _messages = _messages
              .where((message) => message.id != messageId)
              .toList();
        });
      },
      onTyping: (payload) {
        if (!mounted || payload['userId']?.toString() == _currentUserId) return;
        setState(() => _peerTyping = payload['isTyping'] == true);
        _peerTypingTimer?.cancel();
        _peerTypingTimer = Timer(const Duration(seconds: 4), () {
          if (mounted) setState(() => _peerTyping = false);
        });
      },
      onRead: (_) {
        if (!mounted) return;
        setState(() {
          _messages = _messages
              .map(
                (message) => message.isOutgoing
                    ? message.copyWith(deliveryStatus: 'read')
                    : message,
              )
              .toList();
        });
      },
      onCallSignal: (event, _) {
        if (!mounted) return;
        _showTemporaryAction(
          event == 'callEnded' ? 'Call ended' : 'Incoming call signal',
        );
      },
    );
  }

  void _handleTypingChanged() {
    if (_isPreviewRoom || _messageController.text.trim().isEmpty) return;
    _realtime.sendTyping(roomId: widget.roomId, isTyping: true);
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      _realtime.sendTyping(roomId: widget.roomId, isTyping: false);
    });
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

  Future<void> _loadMessages() async {
    if (_isPreviewRoom) return;
    setState(() {
      _isLoadingMessages = true;
      _messageError = null;
    });
    try {
      final currentUserId = await _repository.currentUserId();
      final messages = await _repository.fetchMessages(widget.roomId);
      if (!mounted) return;
      setState(() {
        _currentUserId = currentUserId;
        _messages = messages
            .map(
              (message) => _DisplayChatMessage.fromChatMessage(
                message,
                currentUserId: currentUserId,
              ),
            )
            .toList();
        _isLoadingMessages = false;
      });
      _scrollToBottom();
      unawaited(_repository.markAsRead(widget.roomId));
    } on ChatAuthExpiredException {
      if (mounted) context.go('/login');
    } on ChatApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoadingMessages = false;
        _messageError = error.message;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _isLoadingMessages = false;
        _messageError = 'Unable to load messages.';
      });
    }
  }

  Future<void> _loadSettings() async {
    if (_isPreviewRoom) return;
    try {
      final settings = await _repository.fetchRoomSettings(widget.roomId);
      if (mounted) setState(() => _settings = settings);
    } on Object {
      // Settings are cosmetic; leave defaults if the request fails.
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    final replyingToId = _replyingTo?.id;

    final optimisticId = 'pending-${DateTime.now().microsecondsSinceEpoch}';
    final optimisticMessage = _DisplayChatMessage(
      id: optimisticId,
      text: text,
      time: TimeOfDay.now().format(context),
      isOutgoing: true,
      deliveryStatus: _isPreviewRoom ? 'read' : 'pending',
    );

    setState(() {
      _messages = [..._messages, optimisticMessage];
      _messageController.clear();
      _showEmojiMenu = false;
      _showAttachmentMenu = false;
      _replyingTo = null;
    });
    _scrollToBottom();

    if (_isPreviewRoom) return;

    try {
      final currentUserId = _currentUserId ?? await _repository.currentUserId();
      final sent = await _repository.sendMessage(
        roomId: widget.roomId,
        text: text,
        repliedToMessageId: replyingToId,
      );
      if (!mounted) return;
      setState(() {
        _currentUserId = currentUserId;
        _messages = _messages
            .map(
              (message) => message.id == optimisticId
                  ? _DisplayChatMessage.fromChatMessage(
                      sent,
                      currentUserId: currentUserId,
                    )
                  : message,
            )
            .toList();
      });
      _refreshPresence();
    } on ChatAuthExpiredException {
      if (mounted) context.go('/login');
    } on ChatApiException catch (error) {
      _markMessageFailed(optimisticId);
      _showTemporaryAction(error.message);
    } on Object {
      _markMessageFailed(optimisticId);
      _showTemporaryAction('Message failed to send.');
    }
  }

  Future<void> _sendSystemText(String text) async {
    _messageController.text = text;
    await _sendMessage();
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

  void _markMessageFailed(String messageId) {
    if (!mounted) return;
    setState(() {
      _messages = _messages
          .map(
            (message) => message.id == messageId
                ? message.copyWith(deliveryStatus: 'failed')
                : message,
          )
          .toList();
    });
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

  Future<void> _pickDocument() async {
    setState(() {
      _showAttachmentMenu = false;
      _showEmojiMenu = false;
    });
    final result = await FilePicker.platform.pickFiles();
    final file = result?.files.single;
    final path = file?.path;
    if (path == null || path.isEmpty) return;
    await _sendMediaDraft(
      ChatMediaDraft(
        type: ChatMediaType.file,
        caption: file?.name ?? 'Document',
        filePath: path,
        name: file?.name,
      ),
    );
  }

  Future<void> _sendMediaDraft(ChatMediaDraft draft) async {
    if (_sendingMedia) return;
    final replyingToId = _replyingTo?.id;
    final now = TimeOfDay.now().format(context);
    final localId = 'media-${DateTime.now().microsecondsSinceEpoch}';
    final localMessage = _DisplayChatMessage(
      id: localId,
      text: draft.caption,
      time: now,
      isOutgoing: true,
      mediaType: draft.type,
      localMediaPath: draft.filePath,
      assetMediaPath: draft.assetPath,
      deliveryStatus: _isPreviewRoom ? 'read' : 'pending',
    );

    setState(() {
      _sendingMedia = true;
      _messages = [..._messages, localMessage];
      _replyingTo = null;
    });
    _scrollToBottom();

    if (!draft.isDeviceFile || _isPreviewRoom) {
      setState(() => _sendingMedia = false);
      return;
    }

    try {
      final upload = await _repository.uploadChatMedia(
        filePath: draft.filePath!,
        type: draft.type,
      );
      final currentUserId = _currentUserId ?? await _repository.currentUserId();
      final sent = await _repository.sendMediaMessage(
        roomId: widget.roomId,
        upload: upload,
        text: draft.caption,
        repliedToMessageId: replyingToId,
      );
      if (!mounted) return;
      setState(() {
        _currentUserId = currentUserId;
        _messages = _messages
            .map(
              (message) => message.id == localId
                  ? _DisplayChatMessage.fromChatMessage(
                      sent,
                      currentUserId: currentUserId,
                    )
                  : message,
            )
            .toList();
      });
    } on ChatAuthExpiredException {
      _markMessageFailed(localId);
      if (mounted) context.go('/login');
    } on ChatApiException catch (error) {
      if (!mounted) return;
      _markMessageFailed(localId);
      _showTemporaryAction(error.message);
    } on Object {
      if (!mounted) return;
      _markMessageFailed(localId);
      _showTemporaryAction('Media failed to send.');
    } finally {
      if (mounted) setState(() => _sendingMedia = false);
    }
  }

  Future<void> _saveSettings(ChatRoomSettings settings) async {
    setState(() => _settings = settings);
    if (_isPreviewRoom) return;
    try {
      final saved = await _repository.saveRoomSettings(
        roomId: widget.roomId,
        settings: settings,
      );
      if (mounted) setState(() => _settings = saved);
    } on ChatApiException catch (error) {
      _showTemporaryAction(error.message);
    } on Object {
      _showTemporaryAction('Unable to save chat settings.');
    }
  }

  Future<void> _openMoreMenu() async {
    final conversation = _conversation ?? widget.conversation;
    final participant = conversation?.participant;
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: context.chatColors.menuSurface,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.palette_outlined),
              title: const Text('Chat theme'),
              onTap: () => Navigator.pop(context, 'theme'),
            ),
            ListTile(
              leading: Icon(
                _settings.muted
                    ? Icons.notifications_active_outlined
                    : Icons.notifications_off_outlined,
              ),
              title: Text(
                _settings.muted ? 'Unmute notifications' : 'Mute notifications',
              ),
              onTap: () => Navigator.pop(context, 'mute'),
            ),
            ListTile(
              leading: const Icon(Icons.timer_outlined),
              title: const Text('Disappearing messages'),
              onTap: () => Navigator.pop(context, 'disappearing'),
            ),
            ListTile(
              leading: const Icon(Icons.group_add_outlined),
              title: const Text('New group'),
              onTap: () => Navigator.pop(context, 'group'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_sweep_outlined),
              title: const Text('Clear chat'),
              onTap: () => Navigator.pop(context, 'clear'),
            ),
            if (participant != null) ...[
              ListTile(
                leading: const Icon(Icons.block_rounded),
                title: const Text('Block contact'),
                onTap: () => Navigator.pop(context, 'block'),
              ),
              ListTile(
                leading: const Icon(Icons.flag_outlined),
                title: const Text('Report contact'),
                onTap: () => Navigator.pop(context, 'report'),
              ),
            ],
          ],
        ),
      ),
    );
    if (!mounted || action == null) return;
    if (action == 'theme') {
      await showChatThemeSheet(
        context: context,
        settings: _settings,
        onChanged: _saveSettings,
      );
    } else if (action == 'mute') {
      await _saveSettings(_settings.copyWith(muted: !_settings.muted));
    } else if (action == 'disappearing') {
      await showDisappearingMessagesSheet(
        context: context,
        settings: _settings,
        onChanged: _saveSettings,
      );
    } else if (action == 'group') {
      context.push('/group-chat');
    } else if (action == 'clear') {
      final settings = await _repository.clearChat(widget.roomId);
      if (!mounted) return;
      setState(() {
        _settings = settings;
        _messages = [];
      });
    } else if (action == 'block') {
      if (participant == null) return;
      await _repository.blockContact(participant.id);
      _showTemporaryAction('Contact blocked.');
    } else if (action == 'report') {
      if (participant == null) return;
      await _repository.reportContact(
        userId: participant.id,
        roomId: widget.roomId,
        reason: 'Reported from chat',
      );
      _showTemporaryAction('Report sent.');
    }
  }

  Future<void> _openMessageActions(_DisplayChatMessage message) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: context.chatColors.menuSurface,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.reply_rounded),
              title: const Text('Reply'),
              onTap: () => Navigator.pop(context, 'reply'),
            ),
            if (message.isOutgoing && !message.hasMedia)
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Edit'),
                onTap: () => Navigator.pop(context, 'edit'),
              ),
            ListTile(
              leading: const Icon(Icons.forward_rounded),
              title: const Text('Forward'),
              onTap: () => Navigator.pop(context, 'forward'),
            ),
            if (message.isOutgoing)
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded),
                title: const Text('Delete'),
                onTap: () => Navigator.pop(context, 'delete'),
              ),
          ],
        ),
      ),
    );
    if (!mounted || action == null) return;
    if (action == 'reply') {
      setState(() => _replyingTo = message);
      _inputFocusNode.requestFocus();
    } else if (action == 'edit') {
      await _editMessage(message);
    } else if (action == 'delete') {
      await _deleteMessage(message);
    } else if (action == 'forward') {
      await _forwardMessage(message);
    }
  }

  Future<void> _editMessage(_DisplayChatMessage message) async {
    final controller = TextEditingController(text: message.text);
    final nextText = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit message'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 4,
          decoration: const InputDecoration(hintText: 'Message'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (nextText == null || nextText.isEmpty) return;
    try {
      final edited = await _repository.editMessage(
        messageId: message.id,
        text: nextText,
      );
      if (!mounted) return;
      setState(() {
        _messages = _messages
            .map(
              (item) => item.id == message.id
                  ? _DisplayChatMessage.fromChatMessage(
                      edited,
                      currentUserId: _currentUserId,
                    )
                  : item,
            )
            .toList();
      });
    } on ChatApiException catch (error) {
      _showTemporaryAction(error.message);
    }
  }

  Future<void> _deleteMessage(_DisplayChatMessage message) async {
    try {
      await _repository.deleteMessage(message.id);
      if (!mounted) return;
      setState(() {
        _messages = _messages.where((item) => item.id != message.id).toList();
      });
    } on ChatApiException catch (error) {
      _showTemporaryAction(error.message);
    }
  }

  Future<void> _forwardMessage(_DisplayChatMessage message) async {
    try {
      final chats = [
        ...await _repository.fetchPrivateChats(),
        ...await _repository.fetchGroups(),
      ].where((chat) => chat.id != widget.roomId).toList();
      if (!mounted) return;
      if (chats.isEmpty) {
        _showTemporaryAction('No other chats available to forward to.');
        return;
      }
      final target = await showDialog<ChatConversation>(
        context: context,
        builder: (context) => SimpleDialog(
          title: const Text('Forward to'),
          children: [
            for (final chat in chats)
              SimpleDialogOption(
                onPressed: () => Navigator.pop(context, chat),
                child: Text(chat.title),
              ),
          ],
        ),
      );
      if (target == null) return;
      await _repository.forwardMessage(
        messageId: message.id,
        targetRoomId: target.id,
      );
      _showTemporaryAction('Message forwarded.');
    } on ChatApiException catch (error) {
      _showTemporaryAction(error.message);
    } on Object {
      _showTemporaryAction('Unable to forward message.');
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
    final isOnline = conversation?.participant?.isOnline ?? _isPreviewRoom;
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
                onMore: _openMoreMenu,
              ),
              Expanded(
                child: _MessageArea(
                  messages: _messages,
                  isLoading: _isLoadingMessages,
                  errorMessage: _messageError,
                  peerTyping: _peerTyping,
                  onRetry: _loadMessages,
                  scrollController: _scrollController,
                  onMessageLongPress: _openMessageActions,
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
              if (_replyingTo != null)
                _ReplyingToBar(
                  message: _replyingTo!,
                  onCancel: () => setState(() => _replyingTo = null),
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
                onDocument: _pickDocument,
                onGallery: _openMediaPicker,
                onContact: () => _sendSystemText('[Contact card]'),
                onLocation: () => _sendSystemText('[Location]'),
                onPoll: () => _sendSystemText('[Poll]'),
                onEvent: () => _sendSystemText('[Event]'),
                onEmoji: () => _sendSystemText('🙂'),
                onGif: () => _sendSystemText('[GIF]'),
                onSticker: () => _sendSystemText('[Sticker]'),
                onSend: _sendMessage,
                onVoiceMessage: () => _sendSystemText('[Voice message]'),
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
    required this.isLoading,
    required this.errorMessage,
    required this.peerTyping,
    required this.onRetry,
    required this.scrollController,
    required this.onMessageLongPress,
    required this.onTap,
  });

  final List<_DisplayChatMessage> messages;
  final bool isLoading;
  final String? errorMessage;
  final bool peerTyping;
  final VoidCallback onRetry;
  final ScrollController scrollController;
  final ValueChanged<_DisplayChatMessage> onMessageLongPress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final horizontalPadding = width >= 700 ? 36.0 : 18.0;

    if (isLoading) {
      return Center(
        child: CircularProgressIndicator(color: context.chatColors.accent),
      );
    }

    final error = errorMessage;
    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                error,
                textAlign: TextAlign.center,
                style: TextStyle(color: context.chatColors.primaryText),
              ),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: onTap,
      child: ListView(
        controller: scrollController,
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          16,
          horizontalPadding,
          12,
        ),
        children: [
          const _DateDivider(label: 'Today'),
          const SizedBox(height: 10),
          for (final message in messages)
            MessageBubble(
              text: message.text,
              time: message.time,
              isOutgoing: message.isOutgoing,
              replyPreview: message.replyPreview,
              isEdited: message.isEdited,
              deliveryStatus: message.deliveryStatus,
              mediaType: message.mediaType,
              localMediaPath: message.localMediaPath,
              assetMediaPath: message.assetMediaPath,
              remoteMediaUrl: message.remoteMediaUrl,
              onLongPress: () => onMessageLongPress(message),
            ),
          if (peerTyping)
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 4),
              child: Text(
                'Typing...',
                style: TextStyle(
                  color: context.chatColors.secondaryText,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ReplyingToBar extends StatelessWidget {
  const _ReplyingToBar({required this.message, required this.onCancel});

  final _DisplayChatMessage message;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final colors = context.chatColors;
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 4, 18, 0),
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
      decoration: BoxDecoration(
        color: colors.composerSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: colors.accent, width: 4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.reply_rounded, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message.text.isEmpty ? 'Media message' : message.text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.primaryText,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Cancel reply',
            onPressed: onCancel,
            icon: const Icon(Icons.close_rounded),
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
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _DisplayChatMessage {
  const _DisplayChatMessage({
    required this.id,
    required this.text,
    required this.time,
    required this.isOutgoing,
    this.deliveryStatus,
    this.mediaType,
    this.localMediaPath,
    this.assetMediaPath,
    this.remoteMediaUrl,
    this.replyPreview,
    this.isEdited = false,
  });

  final String id;
  final String text;
  final String time;
  final bool isOutgoing;
  final String? deliveryStatus;
  final ChatMediaType? mediaType;
  final String? localMediaPath;
  final String? assetMediaPath;
  final String? remoteMediaUrl;
  final String? replyPreview;
  final bool isEdited;

  bool get hasMedia =>
      mediaType != null &&
      ((localMediaPath != null && localMediaPath!.isNotEmpty) ||
          (assetMediaPath != null && assetMediaPath!.isNotEmpty) ||
          (remoteMediaUrl != null && remoteMediaUrl!.isNotEmpty));

  _DisplayChatMessage copyWith({String? deliveryStatus}) {
    return _DisplayChatMessage(
      id: id,
      text: text,
      time: time,
      isOutgoing: isOutgoing,
      deliveryStatus: deliveryStatus ?? this.deliveryStatus,
      mediaType: mediaType,
      localMediaPath: localMediaPath,
      assetMediaPath: assetMediaPath,
      remoteMediaUrl: remoteMediaUrl,
      replyPreview: replyPreview,
      isEdited: isEdited,
    );
  }

  factory _DisplayChatMessage.fromChatMessage(
    ChatMessage message, {
    required String? currentUserId,
  }) {
    return _DisplayChatMessage(
      id: message.id,
      text: message.text ?? '',
      time: _formatMessageTime(message.createdAt),
      isOutgoing: message.isMine(currentUserId),
      deliveryStatus: message.status ?? 'sent',
      mediaType: _displayMediaType(message),
      remoteMediaUrl:
          message.imageUrl ??
          message.videoUrl ??
          message.audioUrl ??
          message.fileUrl,
      replyPreview: message.repliedTo == null
          ? null
          : (message.repliedTo!.text?.isNotEmpty == true
                ? message.repliedTo!.text
                : 'Media message'),
      isEdited: message.isEdited,
    );
  }
}

const _mockMessages = [
  _DisplayChatMessage(
    id: 'mock-1',
    text: 'hi',
    time: '11:30 AM',
    isOutgoing: true,
    deliveryStatus: 'read',
  ),
  _DisplayChatMessage(
    id: 'mock-2',
    text: 'how are you',
    time: '11:30 AM',
    isOutgoing: true,
    deliveryStatus: 'read',
  ),
  _DisplayChatMessage(
    id: 'mock-3',
    text: 'am fine and you',
    time: '11:30 AM',
    isOutgoing: false,
  ),
  _DisplayChatMessage(
    id: 'mock-4',
    text: 'sup for today',
    time: '11:31 AM',
    isOutgoing: true,
    deliveryStatus: 'read',
  ),
  _DisplayChatMessage(
    id: 'mock-5',
    text: 'nothing much',
    time: '11:31 AM',
    isOutgoing: false,
  ),
  _DisplayChatMessage(
    id: 'mock-6',
    text: 'ok preparing for class ?',
    time: '11:31 AM',
    isOutgoing: true,
    deliveryStatus: 'read',
  ),
  _DisplayChatMessage(
    id: 'mock-7',
    text: 'no am at the bank',
    time: '11:31 AM',
    isOutgoing: false,
  ),
  _DisplayChatMessage(
    id: 'mock-8',
    text: 'kk',
    time: '11:32 AM',
    isOutgoing: true,
    deliveryStatus: 'read',
  ),
  _DisplayChatMessage(
    id: 'mock-9',
    text: 'ok I will hit you up when am done',
    time: '11:32 AM',
    isOutgoing: false,
  ),
];

ChatMediaType? _displayMediaType(ChatMessage message) {
  final type = message.mediaType;
  if (type != null) {
    switch (type) {
      case 'video':
        return ChatMediaType.video;
      case 'audio':
        return ChatMediaType.audio;
      case 'file':
        return ChatMediaType.file;
      case 'image':
        return ChatMediaType.image;
    }
  }
  if (message.videoUrl != null) return ChatMediaType.video;
  if (message.audioUrl != null) return ChatMediaType.audio;
  if (message.fileUrl != null) return ChatMediaType.file;
  if (message.imageUrl != null) return ChatMediaType.image;
  return null;
}

String _formatMessageTime(DateTime? time) {
  final value = time ?? DateTime.now();
  final hour = value.hour == 0
      ? 12
      : value.hour > 12
      ? value.hour - 12
      : value.hour;
  final minute = value.minute.toString().padLeft(2, '0');
  final suffix = value.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minute $suffix';
}

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
