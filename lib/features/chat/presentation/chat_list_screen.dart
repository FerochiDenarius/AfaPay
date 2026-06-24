import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../models/chat_models.dart';
import '../repositories/chat_repository.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _repository = ChatRepository();
  final _searchController = TextEditingController();

  bool _isLoading = true;
  String? _errorMessage;
  List<ChatConversation> _privateChats = const [];
  List<ChatConversation> _groups = const [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 1),
    );
    _loadChats();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadChats() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final results = await Future.wait([
        _repository.fetchPrivateChats(),
        _repository.fetchGroups(),
      ]);
      if (!mounted) return;
      setState(() {
        _privateChats = results[0];
        _groups = results[1];
        _isLoading = false;
      });
    } on ChatAuthExpiredException {
      if (mounted) context.go('/login');
    } on ChatApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Unable to load chats.';
      });
    }
  }

  List<ChatConversation> _filter(List<ChatConversation> chats) {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return chats;
    return chats
        .where(
          (chat) =>
              chat.title.toLowerCase().contains(query) ||
              (chat.subtitle ?? '').toLowerCase().contains(query),
        )
        .toList();
  }

  Future<void> _startPrivateChat() async {
    final user = await _showUserSearchDialog();
    if (user == null) return;

    try {
      final chat = await _repository.startPrivateChat(userId: user.id);
      if (!mounted) return;
      context.push('/chat/${chat.id}', extra: chat).then((_) => _loadChats());
    } on ChatAuthExpiredException {
      if (mounted) context.go('/login');
    } on ChatApiException catch (error) {
      _showError(error.message);
    } catch (_) {
      _showError('Unable to start chat.');
    }
  }

  Future<ChatParticipant?> _showUserSearchDialog() {
    final controller = TextEditingController();
    var isSearching = false;
    var results = <ChatParticipant>[];
    String? errorMessage;

    return showDialog<ChatParticipant>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          Future<void> search(String query) async {
            if (query.trim().length < 2) {
              setDialogState(() {
                results = [];
                errorMessage = null;
              });
              return;
            }
            setDialogState(() {
              isSearching = true;
              errorMessage = null;
            });
            try {
              final users = await _repository.searchUsers(query);
              if (!context.mounted) return;
              setDialogState(() {
                results = users;
                isSearching = false;
              });
            } on ChatApiException catch (error) {
              if (!context.mounted) return;
              setDialogState(() {
                errorMessage = error.message;
                isSearching = false;
              });
            } catch (_) {
              if (!context.mounted) return;
              setDialogState(() {
                errorMessage = 'Unable to search users.';
                isSearching = false;
              });
            }
          }

          return AlertDialog(
            backgroundColor: context.chatColors.menuSurface,
            title: Text(
              'New Chat',
              style: TextStyle(color: context.chatColors.primaryText),
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: 'Search username',
                      prefixIcon: Icon(Icons.search_rounded),
                    ),
                    onChanged: search,
                  ),
                  const SizedBox(height: 14),
                  if (isSearching)
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: CircularProgressIndicator(
                        color: context.chatColors.accent,
                      ),
                    )
                  else if (errorMessage != null)
                    Text(
                      errorMessage!,
                      style: TextStyle(color: context.chatColors.primaryText),
                    )
                  else if (controller.text.trim().length < 2)
                    Text(
                      'Type at least 2 characters to search.',
                      style: TextStyle(color: context.chatColors.secondaryText),
                    )
                  else if (results.isEmpty)
                    Text(
                      'No users found.',
                      style: TextStyle(color: context.chatColors.secondaryText),
                    )
                  else
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: results.length,
                        separatorBuilder: (_, __) =>
                            Divider(color: context.chatColors.border),
                        itemBuilder: (context, index) {
                          final user = results[index];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor: context.chatColors.accentSoft,
                              child: Icon(
                                Icons.person_rounded,
                                color: context.chatColors.accent,
                              ),
                            ),
                            title: Text(user.username),
                            onTap: () => Navigator.pop(context, user),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _createGroup() async {
    try {
      final contacts = await _repository.fetchContacts();
      if (!mounted) return;
      final request = await _showCreateGroupDialog(contacts);
      if (request == null) return;
      final group = await _repository.createGroup(
        groupName: request.name,
        memberIds: request.memberIds,
      );
      if (!mounted) return;
      setState(() => _groups = [group, ..._groups]);
      context.push('/chat/${group.id}', extra: group).then((_) => _loadChats());
    } on ChatAuthExpiredException {
      if (mounted) context.go('/login');
    } on ChatApiException catch (error) {
      _showError(error.message);
    } catch (_) {
      _showError('Unable to create group.');
    }
  }

  Future<_CreateGroupRequest?> _showCreateGroupDialog(
    List<ChatParticipant> contacts,
  ) {
    final nameController = TextEditingController();
    final selected = <String>{};

    return showDialog<_CreateGroupRequest>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: context.chatColors.menuSurface,
            title: Text(
              'Create Group',
              style: TextStyle(color: context.chatColors.primaryText),
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(hintText: 'Group name'),
                  ),
                  const SizedBox(height: 14),
                  if (contacts.isEmpty)
                    Text(
                      'Start private chats first. Groups can only be created with existing contacts.',
                      style: TextStyle(color: context.chatColors.secondaryText),
                    )
                  else
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: contacts.length,
                        itemBuilder: (context, index) {
                          final contact = contacts[index];
                          final checked = selected.contains(contact.id);
                          return CheckboxListTile(
                            value: checked,
                            activeColor: context.chatColors.accent,
                            title: Text(contact.username),
                            onChanged: (value) {
                              setDialogState(() {
                                if (value == true) {
                                  selected.add(contact.id);
                                } else {
                                  selected.remove(contact.id);
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: selected.isEmpty
                    ? null
                    : () {
                        Navigator.pop(
                          context,
                          _CreateGroupRequest(
                            name: nameController.text.trim(),
                            memberIds: selected.toList(),
                          ),
                        );
                      },
                child: const Text('Create'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    final colors = context.chatColors;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: colors.incomingBubbleBorder,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.chatColors;

    return Scaffold(
      extendBody: true,
      backgroundColor: colors.background,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 86),
        child: _NewChatButton(
          onPressed: () =>
              _tabController.index == 0 ? _startPrivateChat() : _createGroup(),
        ),
      ),
      body: SafeArea(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [colors.background, colors.backgroundSecondary],
            ),
          ),
          child: Stack(
            children: [
              RefreshIndicator(
                color: colors.accent,
                onRefresh: _loadChats,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(24, 40, 24, 0),
                      sliver: SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _ChatListHeader(
                              onHome: () => context.go('/dashboard'),
                            ),
                            const SizedBox(height: 28),
                            _ChatSearchField(
                              controller: _searchController,
                              onChanged: (_) => setState(() {}),
                            ),
                            const SizedBox(height: 20),
                            _ChatSegmentedTabs(controller: _tabController),
                            const SizedBox(height: 18),
                          ],
                        ),
                      ),
                    ),
                    if (_isLoading)
                      SliverFillRemaining(
                        child: Center(
                          child: CircularProgressIndicator(
                            color: colors.accent,
                          ),
                        ),
                      )
                    else if (_errorMessage != null)
                      SliverFillRemaining(
                        child: _ChatError(
                          message: _errorMessage!,
                          onRetry: _loadChats,
                        ),
                      )
                    else
                      SliverFillRemaining(
                        hasScrollBody: true,
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _ConversationList(
                              chats: _filter(_privateChats),
                              emptyText: 'No private chats yet.',
                            ),
                            _ConversationList(
                              chats: _filter(_groups),
                              emptyText: 'No group chats yet.',
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const Align(
                alignment: Alignment.bottomCenter,
                child: _ChatBottomNavigation(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatListHeader extends StatelessWidget {
  const _ChatListHeader({required this.onHome});

  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    final colors = context.chatColors;

    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: colors.glassSurface,
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.border),
                  boxShadow: [
                    BoxShadow(
                      color: colors.shadow,
                      blurRadius: 14,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'UIdesignImages/logo.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Flexible(
                child: Text(
                  'Chats',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.primaryText,
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Home',
          onPressed: onHome,
          icon: Icon(Icons.home_outlined, color: colors.accent, size: 32),
        ),
      ],
    );
  }
}

class _ChatSearchField extends StatelessWidget {
  const _ChatSearchField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.chatColors;

    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: colors.composerSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        cursorColor: colors.cursor,
        style: TextStyle(
          color: colors.primaryText,
          fontSize: 19,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: 'Search chats',
          hintStyle: TextStyle(
            color: colors.placeholderText,
            fontSize: 19,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: colors.mutedIcon,
            size: 31,
          ),
          suffixIcon: IconButton(
            tooltip: 'Filter chats',
            onPressed: () {},
            icon: Icon(
              Icons.filter_alt_outlined,
              color: colors.accent,
              size: 28,
            ),
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          filled: false,
          contentPadding: const EdgeInsets.symmetric(vertical: 20),
        ),
      ),
    );
  }
}

class _ChatSegmentedTabs extends StatelessWidget {
  const _ChatSegmentedTabs({required this.controller});

  final TabController controller;

  @override
  Widget build(BuildContext context) {
    final colors = context.chatColors;

    return Container(
      height: 66,
      decoration: BoxDecoration(
        color: colors.composerSurface,
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: TabBar(
        controller: controller,
        dividerColor: Colors.transparent,
        indicatorColor: colors.accent,
        indicatorWeight: 3,
        indicatorPadding: const EdgeInsets.symmetric(horizontal: 46),
        labelColor: colors.accent,
        unselectedLabelColor: colors.secondaryText,
        labelStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        unselectedLabelStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        tabs: const [
          Tab(text: 'Private'),
          Tab(text: 'Groups'),
        ],
      ),
    );
  }
}

class _ConversationList extends StatelessWidget {
  const _ConversationList({required this.chats, required this.emptyText});

  final List<ChatConversation> chats;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    final colors = context.chatColors;

    if (chats.isEmpty) {
      return Center(
        child: Text(
          emptyText,
          style: TextStyle(color: colors.secondaryText, fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 150),
      itemCount: chats.length,
      itemBuilder: (context, index) {
        final chat = chats[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _ConversationCard(chat: chat),
        );
      },
    );
  }
}

class _ConversationCard extends StatelessWidget {
  const _ConversationCard({required this.chat});

  final ChatConversation chat;

  @override
  Widget build(BuildContext context) {
    final colors = context.chatColors;
    final subtitle = chat.subtitle?.isNotEmpty == true
        ? chat.subtitle!
        : chat.isGroup
        ? 'Group chat'
        : 'Start a secure conversation';

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => context.push('/chat/${chat.id}', extra: chat),
      child: Container(
        constraints: const BoxConstraints(minHeight: 92),
        padding: const EdgeInsets.fromLTRB(20, 16, 22, 16),
        decoration: BoxDecoration(
          color: colors.composerSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colors.border),
          boxShadow: [
            BoxShadow(
              color: colors.shadow,
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            _ChatAvatar(chat: chat),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    chat.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.primaryText,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.secondaryText,
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            _ConversationMeta(chat: chat),
          ],
        ),
      ),
    );
  }
}

class _ChatAvatar extends StatelessWidget {
  const _ChatAvatar({required this.chat});

  final ChatConversation chat;

  @override
  Widget build(BuildContext context) {
    final colors = context.chatColors;
    final imageUrl = chat.imageUrl;
    final label = chat.title.trim().isEmpty
        ? '?'
        : chat.title.trim().characters.first.toUpperCase();

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _avatarBackground(colors, chat.title),
      ),
      clipBehavior: Clip.antiAlias,
      child: imageUrl == null || imageUrl.isEmpty
          ? Center(
              child: chat.isGroup
                  ? Icon(Icons.groups_rounded, color: colors.accent, size: 30)
                  : Text(
                      label,
                      style: TextStyle(
                        color: _avatarForeground(colors, chat.title),
                        fontSize: 27,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
            )
          : Image.network(imageUrl, fit: BoxFit.cover),
    );
  }
}

class _ConversationMeta extends StatelessWidget {
  const _ConversationMeta({required this.chat});

  final ChatConversation chat;

  @override
  Widget build(BuildContext context) {
    final colors = context.chatColors;
    final muted =
        chat.memberCount != null && chat.unreadCount == 0 && chat.isGroup;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          _timeLabel(chat.lastMessageTime),
          style: TextStyle(
            color: colors.secondaryText,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        if (chat.unreadCount > 0)
          Container(
            constraints: const BoxConstraints(minWidth: 27, minHeight: 27),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.accent,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: colors.outgoingBubbleBorder),
            ),
            child: Text(
              chat.unreadCount > 99 ? '99+' : '${chat.unreadCount}',
              style: TextStyle(
                color: colors.onAccentText,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
          )
        else if (muted)
          Icon(
            Icons.notifications_off_outlined,
            color: colors.mutedIcon,
            size: 24,
          )
        else
          const SizedBox(height: 27),
      ],
    );
  }
}

class _NewChatButton extends StatelessWidget {
  const _NewChatButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.chatColors;

    return SizedBox.square(
      dimension: 72,
      child: FloatingActionButton(
        tooltip: 'New chat',
        elevation: 10,
        backgroundColor: colors.accent,
        foregroundColor: colors.onAccentText,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        onPressed: onPressed,
        child: const Icon(Icons.add_rounded, size: 36),
      ),
    );
  }
}

class _ChatBottomNavigation extends StatelessWidget {
  const _ChatBottomNavigation();

  @override
  Widget build(BuildContext context) {
    final colors = context.chatColors;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        child: Container(
          height: 76,
          decoration: BoxDecoration(
            color: colors.composerSurface,
            borderRadius: BorderRadius.circular(36),
            border: Border.all(color: colors.border),
            boxShadow: [
              BoxShadow(
                color: colors.shadow,
                blurRadius: 24,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: const [
              _ChatNavItem(
                icon: Icons.chat_bubble_rounded,
                label: 'Chats',
                selected: true,
              ),
              _ChatNavItem(
                icon: Icons.person_outline_rounded,
                label: 'Contacts',
              ),
              _ChatNavItem(icon: Icons.call_outlined, label: 'Calls'),
              _ChatNavItem(icon: Icons.settings_outlined, label: 'Settings'),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatNavItem extends StatelessWidget {
  const _ChatNavItem({
    required this.icon,
    required this.label,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = context.chatColors;
    final foreground = selected ? colors.accent : colors.secondaryText;

    return SizedBox(
      width: 72,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: foreground, size: 30),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: foreground,
              fontSize: 13,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatError extends StatelessWidget {
  const _ChatError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.chatColors;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.primaryText),
            ),
            const SizedBox(height: 14),
            OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

Color _avatarBackground(ChatThemeColors colors, String seed) {
  final base = _avatarForeground(colors, seed);
  return base.withValues(
    alpha:
        ThemeData.estimateBrightnessForColor(colors.background) ==
            Brightness.dark
        ? 0.34
        : 0.16,
  );
}

Color _avatarForeground(ChatThemeColors colors, String seed) {
  final choices = <Color>[
    colors.accent,
    colors.online,
    colors.readReceipt,
    colors.secondaryText,
    colors.cursor,
  ];
  final index =
      seed.codeUnits.fold<int>(0, (sum, code) => sum + code) % choices.length;
  return choices[index];
}

class _CreateGroupRequest {
  const _CreateGroupRequest({required this.name, required this.memberIds});

  final String name;
  final List<String> memberIds;
}

String _timeLabel(DateTime? time) {
  if (time == null) return '';
  final now = DateTime.now();
  if (now.difference(time).inDays == 0) {
    final hour = time.hour == 0
        ? 12
        : time.hour > 12
        ? time.hour - 12
        : time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final suffix = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $suffix';
  }
  if (now.difference(time).inDays == 1) return 'Yesterday';
  return '${time.day}/${time.month}/${time.year}';
}
