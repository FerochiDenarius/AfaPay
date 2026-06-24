import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../models/chat_media_draft.dart';
import '../models/chat_models.dart';
import '../models/chat_room_settings.dart';
import '../repositories/chat_repository.dart';
import '../services/chat_realtime_service.dart';
import 'chat_media_picker_screen.dart';
import 'widgets/chat_room_menu.dart';
import 'widgets/chat_header.dart';
import 'widgets/chat_theme_sheet.dart';
import 'widgets/chat_wallpaper.dart';
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
  final _realtime = ChatRealtimeService.instance;

  bool _showEmojiMenu = false;
  bool _showAttachmentMenu = false;
  bool _sendingMedia = false;
  bool _isLoadingMessages = false;
  String? _messageError;
  String? _currentUserId;
  Timer? _presenceTimer;
  StreamSubscription<Set<String>>? _onlineUsersSubscription;
  StreamSubscription<ChatPresenceEvent>? _presenceSubscription;
  ChatRoomSettings _settings = ChatRoomSettings.defaults;
  ChatConversation? _conversation;
  late List<_DisplayChatMessage> _messages;

  bool get _isPreviewRoom =>
      widget.roomId == 'preview' || widget.roomId.isEmpty;

  bool get _hasCustomRoomAppearance =>
      _settings.theme != ChatThemeOption.gold ||
      _settings.wallpaper != ChatWallpaperOption.midnight;

  @override
  void initState() {
    super.initState();
    _conversation = widget.conversation;
    _messages = _isPreviewRoom
        ? List.of(_mockMessages)
        : <_DisplayChatMessage>[];
    if (!_isPreviewRoom) {
      _connectRealtime();
    }
    _presenceTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _refreshPresence(),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSettings();
      _refreshPresence();
      _loadMessages();
    });
  }

  @override
  void dispose() {
    _presenceTimer?.cancel();
    _onlineUsersSubscription?.cancel();
    _presenceSubscription?.cancel();
    _messageController.dispose();
    _inputFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _connectRealtime() {
    _onlineUsersSubscription = _realtime.onlineUsersStream.listen(
      _applyOnlineUsers,
    );
    _presenceSubscription = _realtime.presenceStream.listen(
      _applyPresenceEvent,
    );
    unawaited(_realtime.connect());
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

  Future<void> _loadSettings() async {
    if (_isPreviewRoom) return;
    try {
      final settings = await _repository.fetchRoomSettings(widget.roomId);
      if (!mounted) return;
      setState(() => _settings = settings);
    } on ChatAuthExpiredException {
      if (mounted) context.go('/login');
    } on Object {
      // Settings are not critical for opening the room.
    }
  }

  Future<void> _saveSettings(
    ChatRoomSettings settings, {
    bool reloadMessages = false,
  }) async {
    setState(() => _settings = settings);
    if (_isPreviewRoom) return;

    try {
      final saved = await _repository.saveRoomSettings(
        roomId: widget.roomId,
        settings: settings,
      );
      if (!mounted) return;
      setState(() => _settings = saved);
      if (reloadMessages) await _loadMessages();
    } on ChatAuthExpiredException {
      if (mounted) context.go('/login');
    } on ChatApiException catch (error) {
      _showTemporaryAction(error.message);
      unawaited(_loadSettings());
    } on Object {
      _showTemporaryAction('Unable to save chat settings.');
      unawaited(_loadSettings());
    }
  }

  Future<void> _showRoomMenu() {
    final conversation = _conversation ?? widget.conversation;
    final contactAvailable =
        !_isPreviewRoom &&
        conversation?.isGroup == false &&
        conversation?.participant != null;

    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.chatColors.menuSurface,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 18),
          children: [
            _roomMenuTile(
              context,
              ChatRoomMenuAction.viewContact,
              conversation?.isGroup == true
                  ? Icons.groups_rounded
                  : Icons.person_rounded,
              conversation?.isGroup == true ? 'View group' : 'View contact',
            ),
            _roomMenuTile(
              context,
              ChatRoomMenuAction.chatTheme,
              Icons.palette_outlined,
              'Chat theme',
            ),
            _roomMenuTile(
              context,
              ChatRoomMenuAction.block,
              Icons.block_rounded,
              'Block',
              enabled: contactAvailable,
            ),
            _roomMenuTile(
              context,
              ChatRoomMenuAction.mute,
              _settings.muted
                  ? Icons.notifications_active_outlined
                  : Icons.notifications_off_outlined,
              _settings.muted ? 'Unmute notifications' : 'Mute notifications',
            ),
            _roomMenuTile(
              context,
              ChatRoomMenuAction.disappearingMessages,
              Icons.timer_outlined,
              'Disappearing messages',
            ),
            _roomMenuTile(
              context,
              ChatRoomMenuAction.report,
              Icons.flag_outlined,
              'Report',
              enabled: contactAvailable,
            ),
            _roomMenuTile(
              context,
              ChatRoomMenuAction.newGroup,
              Icons.group_add_outlined,
              'New group',
            ),
            _roomMenuTile(
              context,
              ChatRoomMenuAction.clearChat,
              Icons.delete_sweep_outlined,
              'Clear chat',
            ),
          ],
        ),
      ),
    );
  }

  Widget _roomMenuTile(
    BuildContext context,
    ChatRoomMenuAction action,
    IconData icon,
    String label, {
    bool enabled = true,
  }) {
    final colors = context.chatColors;
    return ListTile(
      enabled: enabled,
      leading: Icon(icon, color: enabled ? colors.accent : colors.mutedIcon),
      title: Text(label),
      onTap: enabled
          ? () {
              Navigator.pop(context);
              _handleRoomMenuAction(action);
            }
          : null,
    );
  }

  void _handleRoomMenuAction(ChatRoomMenuAction action) {
    switch (action) {
      case ChatRoomMenuAction.viewContact:
        _showContactDetails();
      case ChatRoomMenuAction.chatTheme:
        showChatThemeSheet(
          context: context,
          settings: _settings,
          onChanged: (settings) => unawaited(_saveSettings(settings)),
        );
      case ChatRoomMenuAction.block:
        unawaited(_blockContact());
      case ChatRoomMenuAction.mute:
        unawaited(_saveSettings(_settings.copyWith(muted: !_settings.muted)));
      case ChatRoomMenuAction.disappearingMessages:
        showDisappearingMessagesSheet(
          context: context,
          settings: _settings,
          onChanged: (settings) =>
              unawaited(_saveSettings(settings, reloadMessages: true)),
        );
      case ChatRoomMenuAction.report:
        unawaited(_reportContact());
      case ChatRoomMenuAction.newGroup:
        context.go('/group-chat');
      case ChatRoomMenuAction.clearChat:
        unawaited(_clearChat());
    }
  }

  void _showContactDetails() {
    final conversation = _conversation ?? widget.conversation;
    final title = conversation?.title ?? 'Chat';
    final status = conversation?.participant?.isOnline == true
        ? 'Online'
        : 'Offline';
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(conversation?.isGroup == true ? 'Group chat' : status),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _clearChat() async {
    final confirmed = await _confirmDestructiveAction(
      title: 'Clear chat?',
      message: 'Messages in this chat will be hidden for you.',
      actionLabel: 'Clear',
    );
    if (confirmed != true) return;

    try {
      final settings = await _repository.clearChat(widget.roomId);
      if (!mounted) return;
      setState(() {
        _settings = settings;
        _messages = const [];
      });
      _showTemporaryAction('Chat cleared.');
    } on ChatAuthExpiredException {
      if (mounted) context.go('/login');
    } on ChatApiException catch (error) {
      _showTemporaryAction(error.message);
    } on Object {
      _showTemporaryAction('Unable to clear chat.');
    }
  }

  Future<void> _blockContact() async {
    final participant = (_conversation ?? widget.conversation)?.participant;
    if (participant == null) return;
    final confirmed = await _confirmDestructiveAction(
      title: 'Block ${participant.username}?',
      message: 'They will not be able to message you in this chat.',
      actionLabel: 'Block',
    );
    if (confirmed != true) return;

    try {
      await _repository.blockContact(participant.id);
      if (!mounted) return;
      _showTemporaryAction('${participant.username} blocked.');
      context.go('/chats');
    } on ChatAuthExpiredException {
      if (mounted) context.go('/login');
    } on ChatApiException catch (error) {
      _showTemporaryAction(error.message);
    } on Object {
      _showTemporaryAction('Unable to block contact.');
    }
  }

  Future<void> _reportContact() async {
    final participant = (_conversation ?? widget.conversation)?.participant;
    if (participant == null) return;
    final reason = await _showReportDialog(participant.username);
    if (reason == null) return;

    try {
      await _repository.reportContact(
        userId: participant.id,
        roomId: widget.roomId,
        reason: reason,
      );
      if (!mounted) return;
      _showTemporaryAction('Report sent.');
    } on ChatAuthExpiredException {
      if (mounted) context.go('/login');
    } on ChatApiException catch (error) {
      _showTemporaryAction(error.message);
    } on Object {
      _showTemporaryAction('Unable to report contact.');
    }
  }

  Future<bool?> _confirmDestructiveAction({
    required String title,
    required String message,
    required String actionLabel,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }

  Future<String?> _showReportDialog(String username) {
    final controller = TextEditingController(text: 'Reported from chat');
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Report $username'),
        content: TextField(
          controller: controller,
          autofocus: true,
          minLines: 3,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'Reason',
            alignLabelWithHint: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final reason = controller.text.trim();
              Navigator.pop(
                context,
                reason.isEmpty ? 'Reported from chat' : reason,
              );
            },
            child: const Text('Report'),
          ),
        ],
      ),
    ).whenComplete(controller.dispose);
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

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

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
    });
    _scrollToBottom();

    if (_isPreviewRoom) return;

    try {
      final currentUserId = _currentUserId ?? await _repository.currentUserId();
      final sent = await _repository.sendMessage(
        roomId: widget.roomId,
        text: text,
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
          _realtime.requestOnlineUsers();
          return;
        }
      }
    } on Object {
      // Presence refresh is best-effort; chat UI should remain usable offline.
    }
  }

  void _applyOnlineUsers(Set<String> userIds) {
    final conversation = _conversation ?? widget.conversation;
    final participant = conversation?.participant;
    if (!mounted || conversation == null || participant == null) return;
    setState(() {
      _conversation = conversation.copyWith(
        participant: participant.copyWith(
          isOnline: userIds.contains(participant.id),
        ),
      );
    });
  }

  void _applyPresenceEvent(ChatPresenceEvent event) {
    final conversation = _conversation ?? widget.conversation;
    final participant = conversation?.participant;
    if (!mounted ||
        conversation == null ||
        participant == null ||
        participant.id != event.userId) {
      return;
    }
    setState(() {
      _conversation = conversation.copyWith(
        participant: participant.copyWith(
          isOnline: event.isOnline,
          lastSeen: event.lastSeen,
        ),
      );
    });
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

  Future<void> _sendMediaDraft(ChatMediaDraft draft) async {
    if (_sendingMedia) return;
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
      body: Stack(
        children: [
          if (_hasCustomRoomAppearance)
            ChatWallpaperBackdrop(settings: _settings)
          else
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [colors.background, colors.backgroundSecondary],
                ),
              ),
              child: const SizedBox.expand(),
            ),
          SafeArea(
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
                  onMore: _showRoomMenu,
                ),
                Expanded(
                  child: _MessageArea(
                    messages: _messages,
                    isLoading: _isLoadingMessages,
                    errorMessage: _messageError,
                    onRetry: _loadMessages,
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
                  onSend: _sendMessage,
                  onVoiceMessage: () => _showToast('Voice message'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageArea extends StatelessWidget {
  const _MessageArea({
    required this.messages,
    required this.isLoading,
    required this.errorMessage,
    required this.onRetry,
    required this.scrollController,
    required this.onTap,
  });

  final List<_DisplayChatMessage> messages;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onRetry;
  final ScrollController scrollController;
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
              deliveryStatus: message.deliveryStatus,
              mediaType: message.mediaType,
              localMediaPath: message.localMediaPath,
              assetMediaPath: message.assetMediaPath,
              remoteMediaUrl: message.remoteMediaUrl,
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
