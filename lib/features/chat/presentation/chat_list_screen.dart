import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/chat_models.dart';
import '../repositories/chat_repository.dart';

const _gold = Color(0xFFF5B81F);
const _navy = Color(0xFF020712);
const _panel = Color(0xFF07101C);
const _muted = Color(0xFFA9ABB2);

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
            backgroundColor: _panel,
            title: const Text('New Chat'),
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
                    const Padding(
                      padding: EdgeInsets.all(14),
                      child: CircularProgressIndicator(color: _gold),
                    )
                  else if (errorMessage != null)
                    Text(
                      errorMessage!,
                      style: const TextStyle(color: Color(0xFFFF7373)),
                    )
                  else if (controller.text.trim().length < 2)
                    const Text(
                      'Type at least 2 characters to search.',
                      style: TextStyle(color: _muted),
                    )
                  else if (results.isEmpty)
                    const Text(
                      'No users found.',
                      style: TextStyle(color: _muted),
                    )
                  else
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: results.length,
                        separatorBuilder: (_, __) =>
                            const Divider(color: Color(0xFF162337)),
                        itemBuilder: (context, index) {
                          final user = results[index];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const CircleAvatar(
                              backgroundColor: Color(0x332B2102),
                              child: Icon(Icons.person_rounded, color: _gold),
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
            backgroundColor: _panel,
            title: const Text('Create Group'),
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
                    const Text(
                      'Start private chats first. Groups can only be created with existing contacts.',
                      style: TextStyle(color: _muted),
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
                            activeColor: _gold,
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF8A1C24),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _navy,
      floatingActionButton: FloatingActionButton(
        backgroundColor: _gold,
        foregroundColor: Colors.black,
        onPressed: () =>
            _tabController.index == 0 ? _startPrivateChat() : _createGroup(),
        child: const Icon(Icons.add_rounded),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: _gold,
          onRefresh: _loadChats,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Chats',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => context.go('/dashboard'),
                            icon: const Icon(Icons.home_outlined),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _searchController,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          hintText: 'Search chats',
                          prefixIcon: Icon(Icons.search_rounded),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TabBar(
                        controller: _tabController,
                        indicatorColor: _gold,
                        labelColor: _gold,
                        tabs: const [
                          Tab(text: 'Private'),
                          Tab(text: 'Groups'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (_isLoading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator(color: _gold)),
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
    if (chats.isEmpty) {
      return Center(
        child: Text(emptyText, style: const TextStyle(color: _muted)),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 96),
      itemCount: chats.length,
      separatorBuilder: (_, __) => const Divider(color: Color(0xFF162337)),
      itemBuilder: (context, index) {
        final chat = chats[index];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: _ChatAvatar(chat: chat),
          title: Text(
            chat.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          subtitle: Text(
            chat.subtitle ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: _muted),
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _timeLabel(chat.lastMessageTime),
                style: const TextStyle(color: _muted, fontSize: 12),
              ),
              if (chat.unreadCount > 0) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: _gold,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    chat.unreadCount > 99 ? '99+' : '${chat.unreadCount}',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ],
          ),
          onTap: () => context.push('/chat/${chat.id}', extra: chat),
        );
      },
    );
  }
}

class _ChatAvatar extends StatelessWidget {
  const _ChatAvatar({required this.chat});

  final ChatConversation chat;

  @override
  Widget build(BuildContext context) {
    final imageUrl = chat.imageUrl;
    return CircleAvatar(
      radius: 25,
      backgroundColor: _gold.withValues(alpha: 0.18),
      backgroundImage: imageUrl == null ? null : NetworkImage(imageUrl),
      child: imageUrl == null
          ? Icon(
              chat.isGroup ? Icons.groups_rounded : Icons.person_rounded,
              color: _gold,
            )
          : null,
    );
  }
}

class _ChatError extends StatelessWidget {
  const _ChatError({required this.message, required this.onRetry});

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
