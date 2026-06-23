import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/chat_models.dart';
import '../models/chat_room_settings.dart';
import '../repositories/chat_repository.dart';
import 'widgets/chat_composer.dart';
import 'widgets/chat_message_list.dart';
import 'widgets/chat_room_menu.dart';
import 'widgets/chat_room_title.dart';
import 'widgets/chat_theme_sheet.dart';
import 'widgets/chat_wallpaper.dart';
import 'widgets/disappearing_messages_sheet.dart';

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

  Timer? _pollTimer;
  bool _isRefreshing = false;
  bool _isLoading = true;
  bool _isSending = false;
  String? _errorMessage;
  String? _currentUserId;
  ChatMessage? _replyingTo;
  ChatRoomSettings _settings = ChatRoomSettings.defaults;
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
    try {
      final settings = await _repository.fetchRoomSettings(widget.roomId);
      if (!mounted) return;
      setState(() => _settings = settings);
    } on ChatAuthExpiredException {
      if (mounted) context.go('/login');
    } catch (_) {
      if (!mounted) return;
      setState(() => _settings = ChatRoomSettings.defaults);
    }
  }

  Future<void> _saveSettings(ChatRoomSettings settings) async {
    setState(() => _settings = settings);
    try {
      final savedSettings = await _repository.saveRoomSettings(
        roomId: widget.roomId,
        settings: settings,
      );
      if (!mounted) return;
      setState(() => _settings = savedSettings);
    } on ChatAuthExpiredException {
      if (mounted) context.go('/login');
    } on ChatApiException catch (error) {
      _showError(error.message);
    } catch (_) {
      _showError('Unable to save chat settings.');
    }
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
    final disappearingCutoff = _settings.disappearingSeconds == null
        ? null
        : now.subtract(Duration(seconds: _settings.disappearingSeconds!));

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

  Future<void> _handleMenuAction(ChatRoomMenuAction action) async {
    switch (action) {
      case ChatRoomMenuAction.viewContact:
        _showContactDialog();
      case ChatRoomMenuAction.chatTheme:
        await showChatThemeSheet(
          context: context,
          settings: _settings,
          onChanged: (settings) => _saveSettings(settings),
        );
      case ChatRoomMenuAction.block:
        await _blockContact();
      case ChatRoomMenuAction.mute:
        final next = _settings.copyWith(muted: !_settings.muted);
        await _saveSettings(next);
        _showInfo(
          next.muted
              ? 'Notifications muted for this chat.'
              : 'Notifications unmuted.',
        );
      case ChatRoomMenuAction.disappearingMessages:
        await showDisappearingMessagesSheet(
          context: context,
          settings: _settings,
          onChanged: (settings) => _saveSettings(settings),
        );
      case ChatRoomMenuAction.report:
        await _reportContact();
      case ChatRoomMenuAction.newGroup:
        context.push('/group-chat');
      case ChatRoomMenuAction.clearChat:
        await _clearChat();
    }
  }

  void _showContactDialog() {
    final title = widget.conversation?.title ?? 'Chat';
    final isGroup = widget.conversation?.isGroup ?? false;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: chatPanel,
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
              style: const TextStyle(color: chatMuted),
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

  Future<void> _blockContact() async {
    final contact = _targetParticipant;
    if (contact == null) {
      _showError('Block is available for private chats.');
      return;
    }
    final confirmed = await _confirmAction(
      title: 'Block Contact',
      message:
          'Block ${contact.username}? You will not be able to send messages to this contact.',
      confirmLabel: 'Block',
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
    final reason = await _showReportDialog();
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

  Future<String?> _showReportDialog() async {
    final controller = TextEditingController(text: 'Reported from chat');
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: chatPanel,
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
    return reason;
  }

  Future<void> _clearChat() async {
    final confirmed = await _confirmAction(
      title: 'Clear Chat',
      message: 'Clear visible messages for you only?',
      confirmLabel: 'Clear',
    );
    if (confirmed != true) return;
    try {
      final settings = await _repository.clearChat(widget.roomId);
      if (!mounted) return;
      setState(() => _settings = settings);
      _showInfo('Chat cleared for you.');
    } on ChatAuthExpiredException {
      if (mounted) context.go('/login');
    } on ChatApiException catch (error) {
      _showError(error.message);
    } catch (_) {
      _showError('Unable to clear chat.');
    }
  }

  Future<bool?> _confirmAction({
    required String title,
    required String message,
    required String confirmLabel,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: chatPanel,
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.conversation?.title ?? 'Chat';
    final isGroup = widget.conversation?.isGroup ?? false;
    final visibleMessages = _visibleMessages();
    final contact = _targetParticipant;

    return Scaffold(
      backgroundColor: chatNavy,
      appBar: AppBar(
        backgroundColor: chatNavy,
        titleSpacing: 0,
        title: ChatRoomTitle(
          title: title,
          isGroup: isGroup,
          muted: _settings.muted,
          accent: _accent,
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
          ChatRoomMenu(
            isGroup: isGroup,
            settings: _settings,
            contactAvailable: contact != null,
            onSelected: _handleMenuAction,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: ChatWallpaperBackdrop(settings: _settings),
                ),
                ChatMessageList(
                  isLoading: _isLoading,
                  errorMessage: _errorMessage,
                  accent: _accent,
                  messages: visibleMessages,
                  currentUserId: _currentUserId,
                  scrollController: _scrollController,
                  onRetry: _loadMessages,
                  onReply: _setReplyTarget,
                ),
              ],
            ),
          ),
          ChatComposer(
            controller: _messageController,
            focusNode: _inputFocusNode,
            replyingTo: _replyingTo,
            accent: _accent,
            isSending: _isSending,
            onCancelReply: () => setState(() => _replyingTo = null),
            onSend: _send,
          ),
        ],
      ),
    );
  }
}
