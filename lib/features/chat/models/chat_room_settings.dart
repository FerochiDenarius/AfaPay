import 'package:flutter/material.dart';

const chatGold = Color(0xFFF5B81F);
const chatNavy = Color(0xFF020712);
const chatPanel = Color(0xFF07101C);
const chatMuted = Color(0xFFA9ABB2);

const _unset = Object();

enum ChatThemeOption {
  gold('Afa Gold', Color(0xFFF5B81F)),
  emerald('Emerald', Color(0xFF36D399)),
  sky('Sky', Color(0xFF38BDF8)),
  rose('Rose', Color(0xFFFB7185));

  const ChatThemeOption(this.label, this.accent);

  final String label;
  final Color accent;
}

enum ChatWallpaperOption {
  midnight('Midnight'),
  graphite('Graphite'),
  aurora('Aurora'),
  clean('Clean');

  const ChatWallpaperOption(this.label);

  final String label;
}

class ChatRoomSettings {
  const ChatRoomSettings({
    required this.theme,
    required this.wallpaper,
    required this.muted,
    required this.disappearingSeconds,
    required this.clearedBefore,
  });

  static const defaults = ChatRoomSettings(
    theme: ChatThemeOption.gold,
    wallpaper: ChatWallpaperOption.midnight,
    muted: false,
    disappearingSeconds: null,
    clearedBefore: null,
  );

  final ChatThemeOption theme;
  final ChatWallpaperOption wallpaper;
  final bool muted;
  final int? disappearingSeconds;
  final DateTime? clearedBefore;

  ChatRoomSettings copyWith({
    ChatThemeOption? theme,
    ChatWallpaperOption? wallpaper,
    bool? muted,
    Object? disappearingSeconds = _unset,
    Object? clearedBefore = _unset,
  }) {
    return ChatRoomSettings(
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

  factory ChatRoomSettings.fromJson(Map<String, dynamic> json) {
    return ChatRoomSettings(
      theme: _enumByName(
        ChatThemeOption.values,
        json['theme'],
        ChatThemeOption.gold,
      ),
      wallpaper: _enumByName(
        ChatWallpaperOption.values,
        json['wallpaper'],
        ChatWallpaperOption.midnight,
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
