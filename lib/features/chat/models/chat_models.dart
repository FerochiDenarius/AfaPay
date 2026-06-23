class ChatParticipant {
  const ChatParticipant({
    required this.id,
    required this.username,
    this.profileImage,
    this.isOnline = false,
  });

  final String id;
  final String username;
  final String? profileImage;
  final bool isOnline;

  factory ChatParticipant.fromJson(Map<String, dynamic> json) {
    return ChatParticipant(
      id: _string(json['_id'] ?? json['id'] ?? json['contactId']),
      username: _string(json['username']).isEmpty
          ? 'AFA User'
          : _string(json['username']),
      profileImage: _nullableString(
        json['profileImage'] ?? json['profilePicture'] ?? json['avatar'],
      ),
      isOnline: json['isOnline'] == true || json['online'] == true,
    );
  }
}

class ChatConversation {
  const ChatConversation({
    required this.id,
    required this.title,
    required this.isGroup,
    this.subtitle,
    this.imageUrl,
    this.unreadCount = 0,
    this.lastMessageTime,
    this.participant,
    this.memberCount,
  });

  final String id;
  final String title;
  final bool isGroup;
  final String? subtitle;
  final String? imageUrl;
  final int unreadCount;
  final DateTime? lastMessageTime;
  final ChatParticipant? participant;
  final int? memberCount;

  factory ChatConversation.privateFromJson(Map<String, dynamic> json) {
    final participants = json['participants'];
    final participantJson = participants is List && participants.isNotEmpty
        ? participants.first
        : json['participant'];
    final participant = participantJson is Map<String, dynamic>
        ? ChatParticipant.fromJson(participantJson)
        : null;
    final lastMessage = json['lastMessage'];
    final lastText = lastMessage is Map<String, dynamic>
        ? _messagePreview(lastMessage)
        : null;

    return ChatConversation(
      id: _string(json['_id'] ?? json['roomId'] ?? json['id']),
      title: participant?.username ?? 'Private Chat',
      isGroup: false,
      subtitle: lastText ?? 'Start a secure conversation',
      imageUrl: participant?.profileImage,
      unreadCount: _int(json['unreadCount']),
      lastMessageTime: _date(json['lastMessageTime']),
      participant: participant,
    );
  }

  factory ChatConversation.groupFromJson(Map<String, dynamic> json) {
    final lastMessage = json['lastMessage'];
    final lastText = lastMessage is Map<String, dynamic>
        ? _messagePreview(lastMessage)
        : null;
    final count = _int(json['memberCount']);

    return ChatConversation(
      id: _string(json['_id'] ?? json['roomId'] ?? json['id']),
      title: _string(json['groupName']).isEmpty
          ? 'Group Chat'
          : _string(json['groupName']),
      isGroup: true,
      subtitle: lastText ?? (count > 0 ? '$count members' : 'Group chat'),
      imageUrl: _nullableString(json['groupImage']),
      unreadCount: _int(json['unreadCount']),
      lastMessageTime: _date(json['lastMessageTime']),
      memberCount: count == 0 ? null : count,
    );
  }
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.roomId,
    required this.senderId,
    this.senderName,
    this.text,
    this.repliedTo,
    this.createdAt,
  });

  final String id;
  final String roomId;
  final String senderId;
  final String? senderName;
  final String? text;
  final ChatMessage? repliedTo;
  final DateTime? createdAt;

  bool isMine(String? currentUserId) =>
      currentUserId != null && senderId == currentUserId;

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final sender = json['sender'];
    final repliedTo = json['repliedTo'];
    return ChatMessage(
      id: _string(json['_id'] ?? json['id']),
      roomId: _string(json['roomId'] ?? json['conversationId']),
      senderId: _string(json['senderId']),
      senderName: sender is Map<String, dynamic>
          ? _nullableString(sender['username'])
          : null,
      text: _nullableString(json['text']),
      repliedTo: repliedTo is Map<String, dynamic>
          ? ChatMessage.fromJson(repliedTo)
          : null,
      createdAt: _date(json['createdAt'] ?? json['timestamp']),
    );
  }
}

String _messagePreview(Map<String, dynamic> json) {
  final text = _nullableString(json['text']);
  if (text != null && text.isNotEmpty) return text;
  if (_nullableString(json['imageUrl']) != null) return 'Photo';
  if (_nullableString(json['audioUrl']) != null) return 'Voice message';
  if (_nullableString(json['videoUrl']) != null) return 'Video';
  if (_nullableString(json['fileUrl']) != null) return 'File';
  return 'New message';
}

String _string(Object? value) => value?.toString() ?? '';

String? _nullableString(Object? value) {
  final string = value?.toString().trim();
  return string == null || string.isEmpty ? null : string;
}

int _int(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

DateTime? _date(Object? value) {
  final string = value?.toString();
  if (string == null || string.isEmpty) return null;
  return DateTime.tryParse(string)?.toLocal();
}
