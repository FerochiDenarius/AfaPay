import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';

import '../models/chat_models.dart';
import '../repositories/chat_repository.dart';

const _gold = Color(0xFFF5B81F);
const _navy = Color(0xFF020712);
const _panel = Color(0xFF07101C);
const _muted = Color(0xFFA9ABB2);
const _unset = Object();

enum _ChatMenuAction {
  viewContact,
  chatTheme,
  block,
  mute,
  disappearingMessages,
  report,
  newGroup,
  clearChat,
}

enum _ChatThemeOption {
  gold('Afa Gold', Color(0xFFF5B81F)),
  emerald('Emerald', Color(0xFF36D399)),
  sky('Sky', Color(0xFF38BDF8)),
  rose('Rose', Color(0xFFFB7185));

  const _ChatThemeOption(this.label, this.accent);

  final String label;
  final Color accent;
}

enum _WallpaperOption {
  midnight('Midnight'),
  graphite('Graphite'),
  aurora('Aurora'),
  clean('Clean');

  const _WallpaperOption(this.label);

  final String label;
}

class ChatRoomScreen extends StatefulWidget {
  const ChatRoomScreen({super.key, required this.roomId, this.conversation});

  final String roomId;
  final ChatConversation? conversation;

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final _repository = ChatRepository();
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _inputFocusNode = FocusNode();
  final _settingsStorage = const FlutterSecureStorage();

  Timer? _pollTimer;
  bool _isRefreshing = false;
  bool _isLoading = true;
  bool _isSending = false;
  String? _errorMessage;
  String? _currentUserId;
  ChatMessage? _replyingTo;
  _ChatRoomSettings _settings = _ChatRoomSettings.defaults;
  List<ChatMessage> _messages = const [];

  Color get _accent => _settings.theme.accent;

  ChatParticipant? get _targetParticipant => widget.conversation?.participant;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadMessages();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _refreshMessages(),
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final raw = await _settingsStorage.read(key: _settingsKey);
    if (!mounted || raw == null) return;
    try {
      final json = jsonDecode(raw);
      if (json is Map<String, dynamic>) {
        setState(() => _settings = _ChatRoomSettings.fromJson(json));
      }
    } on FormatException {
      await _settingsStorage.delete(key: _settingsKey);
    }
  }

  String get _settingsKey => 'chat_room_settings_${widget.roomId}';

  Future<void> _saveSettings(_ChatRoomSettings settings) async {
    setState(() => _settings = settings);
    await _settingsStorage.write(
      key: _settingsKey,
      value: jsonEncode(settings.toJson()),
    );
  }

  Future<void> _loadMessages() async {
    await _refreshMessages(showLoading: true, forceScrollToEnd: true);
  }

  Future<void> _refreshMessages({
    bool showLoading = false,
    bool forceScrollToEnd = false,
  }) async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    if (showLoading && mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    final wasNearBottom =
        !_scrollController.hasClients ||
        _scrollController.position.maxScrollExtent -
                _scrollController.position.pixels <
            120;
    try {
      final results = await Future.wait([
        _repository.fetchMessages(widget.roomId),
        _repository.currentUserId(),
      ]);
      await _repository.markAsRead(widget.roomId);
      if (!mounted) return;
      final nextMessages = results[0] as List<ChatMessage>;
      final hadNewMessages =
          nextMessages.length != _messages.length ||
          (nextMessages.isNotEmpty &&
              _messages.isNotEmpty &&
              nextMessages.last.id != _messages.last.id) ||
          (nextMessages.isNotEmpty && _messages.isEmpty);
      setState(() {
        _messages = nextMessages;
        _currentUserId = results[1] as String?;
        _isLoading = false;
        _errorMessage = null;
      });
      if (forceScrollToEnd || (hadNewMessages && wasNearBottom)) {
        _scrollToEnd();
      }
    } on ChatAuthExpiredException {
      if (mounted) context.go('/login');
    } on ChatApiException catch (error) {
      if (!mounted) return;
      if (showLoading) {
        setState(() {
          _isLoading = false;
          _errorMessage = error.message;
        });
      }
    } catch (_) {
      if (!mounted) return;
      if (showLoading) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Unable to load messages.';
        });
      }
    } finally {
      _isRefreshing = false;
    }
  }

  Future<void> _send() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;
    final reply = _replyingTo;
    setState(() => _isSending = true);
    try {
      final message = await _repository.sendMessage(
        roomId: widget.roomId,
        text: text,
        repliedToMessageId: reply?.id,
      );
      if (!mounted) return;
      _messageController.clear();
      setState(() {
        _messages = [..._messages, message];
        _replyingTo = null;
        _isSending = false;
      });
      _scrollToEnd();
    } on ChatAuthExpiredException {
      if (mounted) context.go('/login');
    } on ChatApiException catch (error) {
      _showError(error.message);
      if (mounted) setState(() => _isSending = false);
    } catch (_) {
      _showError('Unable to send message.');
      if (mounted) setState(() => _isSending = false);
    }
  }

  List<ChatMessage> _visibleMessages() {
    final now = DateTime.now();
    final disappearingSeconds = _settings.disappearingSeconds;
    final disappearingCutoff = disappearingSeconds == null
        ? null
        : now.subtract(Duration(seconds: disappearingSeconds));
    return _messages.where((message) {
      final createdAt = message.createdAt;
      final clearedBefore = _settings.clearedBefore;
      if (clearedBefore != null &&
          createdAt != null &&
          !createdAt.isAfter(clearedBefore)) {
        return false;
      }
      if (disappearingCutoff != null &&
          createdAt != null &&
          !createdAt.isAfter(disappearingCutoff)) {
        return false;
      }
      return true;
    }).toList();
  }

  void _setReplyTarget(ChatMessage message) {
    setState(() => _replyingTo = message);
    _inputFocusNode.requestFocus();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _handleMenuAction(_ChatMenuAction action) async {
    switch (action) {
      case _ChatMenuAction.viewContact:
        _showContactDialog();
      case _ChatMenuAction.chatTheme:
        _showThemeSheet();
      case _ChatMenuAction.block:
        await _blockContact();
      case _ChatMenuAction.mute:
        final next = _settings.copyWith(muted: !_settings.muted);
        await _saveSettings(next);
        _showInfo(
          next.muted ? 'Notifications muted for this chat.' : 'Notifications unmuted.',
        );
      case _ChatMenuAction.disappearingMessages:
        _showDisappearingSheet();
      case _ChatMenuAction.report:
        await _reportContact();
      case _ChatMenuAction.newGroup:
        context.push('/group-chat');
      case _ChatMenuAction.clearChat:
        await _clearChat();
    }
  }

  void _showContactDialog() {
    final title = widget.conversation?.title ?? 'Chat';
    final isGroup = widget.conversation?.isGroup ?? false;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _panel,
        title: Text(isGroup ? 'Group Info' : 'Contact Info'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 34,
              backgroundColor: _accent.withValues(alpha: 0.18),
              child: Icon(
                isGroup ? Icons.groups_rounded : Icons.person_rounded,
                color: _accent,
                size: 34,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              isGroup
                  ? '${widget.conversation?.memberCount ?? 0} members'
                  : '@${_targetParticipant?.username ?? title}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: _muted),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showThemeSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: _panel,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          Future<void> update(_ChatRoomSettings settings) async {
            setSheetState(() => _settings = settings);
            await _saveSettings(settings);
          }

          return SafeArea(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
              children: [
                const Text(
                  'Chat Theme',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _ChatThemeOption.values.map((theme) {
                    return _ThemeChip(
                      label: theme.label,
                      color: theme.accent,
                      selected: _settings.theme == theme,
                      onTap: () => update(_settings.copyWith(theme: theme)),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Wallpaper',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 10),
                ..._WallpaperOption.values.map(
                  (wallpaper) => RadioListTile<_WallpaperOption>(
                    value: wallpaper,
                    groupValue: _settings.wallpaper,
                    activeColor: _accent,
                    contentPadding: EdgeInsets.zero,
                    title: Text(wallpaper.label),
                    onChanged: (value) {
                      if (value == null) return;
                      update(_settings.copyWith(wallpaper: value));
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showDisappearingSheet() {
    final options = <int?, String>{
      null: 'Off',
      86400: '24 hours',
      604800: '7 days',
      2592000: '30 days',
    };
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: _panel,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
          children: [
            const Text(
              'Disappearing Messages',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            const Text(
              'Messages older than the selected time are hidden on this device.',
              style: TextStyle(color: _muted),
            ),
            const SizedBox(height: 14),
            ...options.entries.map(
              (entry) => RadioListTile<int?>(
                value: entry.key,
                groupValue: _settings.disappearingSeconds,
                activeColor: _accent,
                contentPadding: EdgeInsets.zero,
                title: Text(entry.value),
                onChanged: (value) {
                  _saveSettings(
                    _settings.copyWith(disappearingSeconds: value),
                  );
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _blockContact() async {
    final contact = _targetParticipant;
    if (contact == null) {
      _showError('Block is available for private chats.');
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _panel,
        title: const Text('Block Contact'),
        content: Text('Block ${contact.username}? You will not be able to send messages to this contact.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Block'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _repository.blockContact(contact.id);
      _showInfo('${contact.username} blocked.');
    } on ChatAuthExpiredException {
      if (mounted) context.go('/login');
    } on ChatApiException catch (error) {
      _showError(error.message);
    } catch (_) {
      _showError('Unable to block contact.');
    }
  }

  Future<void> _reportContact() async {
    final contact = _targetParticipant;
    if (contact == null) {
      _showError('Report is available for private chats.');
      return;
    }
    final controller = TextEditingController(text: 'Reported from chat');
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _panel,
        title: const Text('Report Contact'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Reason',
            prefixIcon: Icon(Icons.flag_outlined),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Report'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (reason == null) return;
    try {
      await _repository.reportContact(
        userId: contact.id,
        roomId: widget.roomId,
        reason: reason.isEmpty ? 'Reported from chat' : reason,
      );
      _showInfo('Report submitted.');
    } on ChatAuthExpiredException {
      if (mounted) context.go('/login');
    } on ChatApiException catch (error) {
      _showError(error.message);
    } catch (_) {
      _showError('Unable to submit report.');
    }
  }

  Future<void> _clearChat() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _panel,
        title: const Text('Clear Chat'),
        content: const Text('Clear visible messages from this device?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _saveSettings(_settings.copyWith(clearedBefore: DateTime.now()));
    _showInfo('Chat cleared on this device.');
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF8A1C24),
      ),
    );
  }

  void _showInfo(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.conversation?.title ?? 'Chat';
    final isGroup = widget.conversation?.isGroup ?? false;
    final visibleMessages = _visibleMessages();
    final contact = _targetParticipant;

    return Scaffold(
      backgroundColor: _navy,
      appBar: AppBar(
        backgroundColor: _navy,
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: _accent.withValues(alpha: 0.18),
              child: Icon(
                isGroup ? Icons.groups_rounded : Icons.person_rounded,
                color: _accent,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  if (_settings.muted)
                    const Text(
                      'Muted',
                      style: TextStyle(color: _muted, fontSize: 12),
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Voice Call',
            onPressed: () => context.push('/voice-call'),
            icon: const Icon(Icons.call_outlined),
          ),
          IconButton(
            tooltip: 'Video Call',
            onPressed: () => context.push('/video-call'),
            icon: const Icon(Icons.videocam_outlined),
          ),
          PopupMenuButton<_ChatMenuAction>(
            tooltip: 'Chat menu',
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              _menuItem(
                _ChatMenuAction.viewContact,
                isGroup ? Icons.groups_rounded : Icons.person_rounded,
                isGroup ? 'View group' : 'View contact',
              ),
              _menuItem(
                _ChatMenuAction.chatTheme,
                Icons.palette_outlined,
                'Chat theme',
              ),
              _menuItem(
                _ChatMenuAction.block,
                Icons.block_rounded,
                'Block',
                enabled: contact != null,
              ),
              _menuItem(
                _ChatMenuAction.mute,
                _settings.muted
                    ? Icons.notifications_active_outlined
                    : Icons.notifications_off_outlined,
                _settings.muted ? 'Unmute notifications' : 'Mute notifications',
              ),
              _menuItem(
                _ChatMenuAction.disappearingMessages,
                Icons.timer_outlined,
                'Disappearing messages',
              ),
              _menuItem(
                _ChatMenuAction.report,
                Icons.flag_outlined,
                'Report',
                enabled: contact != null,
              ),
              _menuItem(
                _ChatMenuAction.newGroup,
                Icons.group_add_outlined,
                'New group',
              ),
              _menuItem(
                _ChatMenuAction.clearChat,
                Icons.delete_sweep_outlined,
                'Clear chat',
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: _WallpaperBackdrop(settings: _settings),
                ),
                _isLoading
                    ? Center(child: CircularProgressIndicator(color: _accent))
                    : _errorMessage != null
                    ? _ChatRoomError(
                        message: _errorMessage!,
                        onRetry: _loadMessages,
                      )
                    : visibleMessages.isEmpty
                    ? const Center(
                        child: Text(
                          'No messages here yet.',
                          style: TextStyle(color: _muted),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
                        itemCount: visibleMessages.length,
                        itemBuilder: (context, index) {
                          final message = visibleMessages[index];
                          return _SwipeToReplyMessage(
                            onReply: () => _setReplyTarget(message),
                            isMine: message.isMine(_currentUserId),
                            accent: _accent,
                            child: _MessageBubble(
                              message: message,
                              isMine: message.isMine(_currentUserId),
                              accent: _accent,
                            ),
                          );
                        },
                      ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              decoration: const BoxDecoration(
                color: _panel,
                border: Border(top: BorderSide(color: Color(0xFF162337))),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_replyingTo != null)
                    _ReplyComposerPreview(
                      message: _replyingTo!,
                      accent: _accent,
                      onClose: () => setState(() => _replyingTo = null),
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          focusNode: _inputFocusNode,
                          minLines: 1,
                          maxLines: 4,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _send(),
                          decoration: const InputDecoration(
                            hintText: 'Type a message',
                            prefixIcon: Icon(Icons.message_outlined),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton.filled(
                        style: IconButton.styleFrom(
                          backgroundColor: _accent,
                          foregroundColor: Colors.black,
                        ),
                        onPressed: _isSending ? null : _send,
                        icon: _isSending
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.send_rounded),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

PopupMenuItem<_ChatMenuAction> _menuItem(
  _ChatMenuAction action,
  IconData icon,
  String label, {
  bool enabled = true,
}) {
  return PopupMenuItem<_ChatMenuAction>(
    value: action,
    enabled: enabled,
    child: Row(
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 12),
        Flexible(child: Text(label)),
      ],
    ),
  );
}

class _ChatRoomSettings {
  const _ChatRoomSettings({
    required this.theme,
    required this.wallpaper,
    required this.muted,
    required this.disappearingSeconds,
    required this.clearedBefore,
  });

  static const defaults = _ChatRoomSettings(
    theme: _ChatThemeOption.gold,
    wallpaper: _WallpaperOption.midnight,
    muted: false,
    disappearingSeconds: null,
    clearedBefore: null,
  );

  final _ChatThemeOption theme;
  final _WallpaperOption wallpaper;
  final bool muted;
  final int? disappearingSeconds;
  final DateTime? clearedBefore;

  _ChatRoomSettings copyWith({
    _ChatThemeOption? theme,
    _WallpaperOption? wallpaper,
    bool? muted,
    Object? disappearingSeconds = _unset,
    Object? clearedBefore = _unset,
  }) {
    return _ChatRoomSettings(
      theme: theme ?? this.theme,
      wallpaper: wallpaper ?? this.wallpaper,
      muted: muted ?? this.muted,
      disappearingSeconds: identical(disappearingSeconds, _unset)
          ? this.disappearingSeconds
          : disappearingSeconds as int?,
      clearedBefore: identical(clearedBefore, _unset)
          ? this.clearedBefore
          : clearedBefore as DateTime?,
    );
  }

  factory _ChatRoomSettings.fromJson(Map<String, dynamic> json) {
    return _ChatRoomSettings(
      theme: _enumByName(
        _ChatThemeOption.values,
        json['theme'],
        _ChatThemeOption.gold,
      ),
      wallpaper: _enumByName(
        _WallpaperOption.values,
        json['wallpaper'],
        _WallpaperOption.midnight,
      ),
      muted: json['muted'] == true,
      disappearingSeconds: json['disappearingSeconds'] is int
          ? json['disappearingSeconds'] as int
          : null,
      clearedBefore: DateTime.tryParse(json['clearedBefore']?.toString() ?? ''),
    );
  }

  Map<String, Object?> toJson() => {
    'theme': theme.name,
    'wallpaper': wallpaper.name,
    'muted': muted,
    'disappearingSeconds': disappearingSeconds,
    'clearedBefore': clearedBefore?.toIso8601String(),
  };
}

T _enumByName<T extends Enum>(List<T> values, Object? name, T fallback) {
  for (final value in values) {
    if (value.name == name) return value;
  }
  return fallback;
}

class _SwipeToReplyMessage extends StatefulWidget {
  const _SwipeToReplyMessage({
    required this.child,
    required this.onReply,
    required this.isMine,
    required this.accent,
  });

  final Widget child;
  final VoidCallback onReply;
  final bool isMine;
  final Color accent;

  @override
  State<_SwipeToReplyMessage> createState() => _SwipeToReplyMessageState();
}

class _SwipeToReplyMessageState extends State<_SwipeToReplyMessage> {
  double _dragOffset = 0;

  @override
  Widget build(BuildContext context) {
    final direction = widget.isMine ? -1.0 : 1.0;
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragUpdate: (details) {
        final movement = details.delta.dx * direction;
        if (movement <= 0 && _dragOffset <= 0) return;
        setState(() => _dragOffset = (_dragOffset + movement).clamp(0, 76));
      },
      onHorizontalDragEnd: (_) {
        if (_dragOffset > 48) widget.onReply();
        setState(() => _dragOffset = 0);
      },
      onHorizontalDragCancel: () => setState(() => _dragOffset = 0),
      child: Stack(
        alignment: widget.isMine ? Alignment.centerRight : Alignment.centerLeft,
        children: [
          Positioned(
            left: widget.isMine ? null : 12,
            right: widget.isMine ? 12 : null,
            child: Opacity(
              opacity: (_dragOffset / 76).clamp(0, 1),
              child: CircleAvatar(
                radius: 15,
                backgroundColor: widget.accent.withValues(alpha: 0.2),
                child: Icon(
                  Icons.reply_rounded,
                  size: 18,
                  color: widget.accent,
                  textDirection:
                      widget.isMine ? TextDirection.rtl : TextDirection.ltr,
                ),
              ),
            ),
          ),
          Transform.translate(
            offset: Offset(_dragOffset * direction, 0),
            child: widget.child,
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.isMine,
    required this.accent,
  });

  final ChatMessage message;
  final bool isMine;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMine ? accent : _panel.withValues(alpha: 0.96),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMine ? 18 : 4),
            bottomRight: Radius.circular(isMine ? 4 : 18),
          ),
          border: isMine ? null : Border.all(color: const Color(0xFF162337)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.repliedTo != null) ...[
              _ReplySnippet(
                message: message.repliedTo!,
                isMine: isMine,
                accent: accent,
              ),
              const SizedBox(height: 8),
            ],
            Text(
              message.text?.isNotEmpty == true ? message.text! : 'Message',
              style: TextStyle(
                color: isMine ? Colors.black : Colors.white,
                fontWeight: FontWeight.w600,
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReplySnippet extends StatelessWidget {
  const _ReplySnippet({
    required this.message,
    required this.isMine,
    required this.accent,
  });

  final ChatMessage message;
  final bool isMine;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final foreground = isMine ? Colors.black : Colors.white;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isMine
            ? Colors.white.withValues(alpha: 0.32)
            : Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: isMine ? Colors.black : accent, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message.senderName ?? 'Message',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: foreground.withValues(alpha: 0.86),
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            message.text?.isNotEmpty == true ? message.text! : 'Message',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: foreground.withValues(alpha: 0.78),
              fontSize: 12,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReplyComposerPreview extends StatelessWidget {
  const _ReplyComposerPreview({
    required this.message,
    required this.accent,
    required this.onClose,
  });

  final ChatMessage message;
  final Color accent;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 9, 8, 9),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1624),
        borderRadius: BorderRadius.circular(10),
        border: Border(left: BorderSide(color: accent, width: 3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.reply_rounded, color: _muted, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message.senderName ?? 'Replying to message',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: accent, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 2),
                Text(
                  message.text?.isNotEmpty == true ? message.text! : 'Message',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _muted, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Cancel reply',
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }
}

class _WallpaperBackdrop extends StatelessWidget {
  const _WallpaperBackdrop({required this.settings});

  final _ChatRoomSettings settings;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _WallpaperPainter(settings),
      child: const SizedBox.expand(),
    );
  }
}

class _WallpaperPainter extends CustomPainter {
  const _WallpaperPainter(this.settings);

  final _ChatRoomSettings settings;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final accent = settings.theme.accent;
    final basePaint = Paint();
    switch (settings.wallpaper) {
      case _WallpaperOption.midnight:
        basePaint.shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF020712), Color(0xFF08111E), Color(0xFF020712)],
        ).createShader(rect);
      case _WallpaperOption.graphite:
        basePaint.shader = const LinearGradient(
          colors: [Color(0xFF111827), Color(0xFF030712)],
        ).createShader(rect);
      case _WallpaperOption.aurora:
        basePaint.shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            accent.withValues(alpha: 0.24),
            const Color(0xFF031018),
            const Color(0xFF020712),
          ],
        ).createShader(rect);
      case _WallpaperOption.clean:
        basePaint.color = const Color(0xFF07101C);
    }
    canvas.drawRect(rect, basePaint);

    if (settings.wallpaper == _WallpaperOption.clean) return;

    final dotPaint = Paint()..color = Colors.white.withValues(alpha: 0.035);
    for (double y = 18; y < size.height; y += 34) {
      for (double x = 18; x < size.width; x += 34) {
        canvas.drawCircle(Offset(x, y), 1.2, dotPaint);
      }
    }

    final accentPaint = Paint()
      ..color = accent.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (double y = 40; y < size.height; y += 110) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y + 42), accentPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _WallpaperPainter oldDelegate) {
    return oldDelegate.settings != settings;
  }
}

class _ThemeChip extends StatelessWidget {
  const _ThemeChip({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        width: 142,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF0B1624),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? color : const Color(0xFF223047)),
        ),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatRoomError extends StatelessWidget {
  const _ChatRoomError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFFFF7373)),
            ),
            const SizedBox(height: 14),
            OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
