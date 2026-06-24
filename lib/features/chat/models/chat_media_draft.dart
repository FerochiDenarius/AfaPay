import 'chat_models.dart';

class ChatMediaDraft {
  const ChatMediaDraft({
    required this.type,
    required this.caption,
    this.filePath,
    this.assetPath,
    this.name,
    this.mimeType,
  });

  final ChatMediaType type;
  final String caption;
  final String? filePath;
  final String? assetPath;
  final String? name;
  final String? mimeType;

  bool get isDeviceFile => filePath != null && filePath!.isNotEmpty;

  ChatMediaDraft copyWith({
    ChatMediaType? type,
    String? caption,
    String? filePath,
    String? assetPath,
    String? name,
    String? mimeType,
  }) {
    return ChatMediaDraft(
      type: type ?? this.type,
      caption: caption ?? this.caption,
      filePath: filePath ?? this.filePath,
      assetPath: assetPath ?? this.assetPath,
      name: name ?? this.name,
      mimeType: mimeType ?? this.mimeType,
    );
  }
}
