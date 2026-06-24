import 'package:flutter/material.dart';

@immutable
class ChatThemeColors extends ThemeExtension<ChatThemeColors> {
  const ChatThemeColors({
    required this.accent,
    required this.accentSoft,
    required this.background,
    required this.backgroundSecondary,
    required this.headerSurface,
    required this.glassSurface,
    required this.strongGlassSurface,
    required this.composerSurface,
    required this.composerButtonSurface,
    required this.menuSurface,
    required this.outgoingBubble,
    required this.outgoingBubbleBorder,
    required this.incomingBubble,
    required this.incomingBubbleBorder,
    required this.border,
    required this.softBorder,
    required this.primaryText,
    required this.secondaryText,
    required this.placeholderText,
    required this.onAccentText,
    required this.icon,
    required this.mutedIcon,
    required this.online,
    required this.readReceipt,
    required this.cursor,
    required this.shadow,
  });

  final Color accent;
  final Color accentSoft;
  final Color background;
  final Color backgroundSecondary;
  final Color headerSurface;
  final Color glassSurface;
  final Color strongGlassSurface;
  final Color composerSurface;
  final Color composerButtonSurface;
  final Color menuSurface;
  final Color outgoingBubble;
  final Color outgoingBubbleBorder;
  final Color incomingBubble;
  final Color incomingBubbleBorder;
  final Color border;
  final Color softBorder;
  final Color primaryText;
  final Color secondaryText;
  final Color placeholderText;
  final Color onAccentText;
  final Color icon;
  final Color mutedIcon;
  final Color online;
  final Color readReceipt;
  final Color cursor;
  final Color shadow;

  static const dark = ChatThemeColors(
    accent: Color(0xFFFFBF1F),
    accentSoft: Color(0xFF5A4213),
    background: Color(0xFF020A15),
    backgroundSecondary: Color(0xFF061322),
    headerSurface: Color(0x330E1A2B),
    glassSurface: Color(0x66152235),
    strongGlassSurface: Color(0xCC101A29),
    composerSurface: Color(0xB51B2535),
    composerButtonSurface: Color(0xFF263446),
    menuSurface: Color(0xF01D2532),
    outgoingBubble: Color(0xFFFFC329),
    outgoingBubbleBorder: Color(0xFFFFD05A),
    incomingBubble: Color(0xAA172437),
    incomingBubbleBorder: Color(0xFF26384F),
    border: Color(0xFF26364C),
    softBorder: Color(0x8A33445B),
    primaryText: Color(0xFFF7F8FC),
    secondaryText: Color(0xFFC7CDD9),
    placeholderText: Color(0xFFA5ACB8),
    onAccentText: Color(0xFF05070B),
    icon: Color(0xFFE7EAF0),
    mutedIcon: Color(0xFFC6CCD6),
    online: Color(0xFF20C76A),
    readReceipt: Color(0xFF111820),
    cursor: Color(0xFFFFC329),
    shadow: Color(0x99000000),
  );

  static const light = ChatThemeColors(
    accent: Color(0xFFFFC845),
    accentSoft: Color(0xFFFFE7A8),
    background: Color(0xFFF5F7FA),
    backgroundSecondary: Color(0xFFFDFEFF),
    headerSurface: Color(0xEAF8FAFD),
    glassSurface: Color(0xF2FFFFFF),
    strongGlassSurface: Color(0xFFFFFFFF),
    composerSurface: Color(0xFAFFFFFF),
    composerButtonSurface: Color(0xFFF6F8FB),
    menuSurface: Color(0xFFFFFFFF),
    outgoingBubble: Color(0xFFFFF5CF),
    outgoingBubbleBorder: Color(0xFFF4C653),
    incomingBubble: Color(0xFFF8FAFD),
    incomingBubbleBorder: Color(0xFFD4DAE3),
    border: Color(0xFFD3DAE4),
    softBorder: Color(0xFFE3E8EF),
    primaryText: Color(0xFF080D18),
    secondaryText: Color(0xFF5D6675),
    placeholderText: Color(0xFF8B93A1),
    onAccentText: Color(0xFF05070B),
    icon: Color(0xFF080D18),
    mutedIcon: Color(0xFF4C5665),
    online: Color(0xFF1FC66E),
    readReceipt: Color(0xFF1479E8),
    cursor: Color(0xFF101827),
    shadow: Color(0x1F0F172A),
  );

  @override
  ChatThemeColors copyWith({
    Color? accent,
    Color? accentSoft,
    Color? background,
    Color? backgroundSecondary,
    Color? headerSurface,
    Color? glassSurface,
    Color? strongGlassSurface,
    Color? composerSurface,
    Color? composerButtonSurface,
    Color? menuSurface,
    Color? outgoingBubble,
    Color? outgoingBubbleBorder,
    Color? incomingBubble,
    Color? incomingBubbleBorder,
    Color? border,
    Color? softBorder,
    Color? primaryText,
    Color? secondaryText,
    Color? placeholderText,
    Color? onAccentText,
    Color? icon,
    Color? mutedIcon,
    Color? online,
    Color? readReceipt,
    Color? cursor,
    Color? shadow,
  }) {
    return ChatThemeColors(
      accent: accent ?? this.accent,
      accentSoft: accentSoft ?? this.accentSoft,
      background: background ?? this.background,
      backgroundSecondary: backgroundSecondary ?? this.backgroundSecondary,
      headerSurface: headerSurface ?? this.headerSurface,
      glassSurface: glassSurface ?? this.glassSurface,
      strongGlassSurface: strongGlassSurface ?? this.strongGlassSurface,
      composerSurface: composerSurface ?? this.composerSurface,
      composerButtonSurface:
          composerButtonSurface ?? this.composerButtonSurface,
      menuSurface: menuSurface ?? this.menuSurface,
      outgoingBubble: outgoingBubble ?? this.outgoingBubble,
      outgoingBubbleBorder: outgoingBubbleBorder ?? this.outgoingBubbleBorder,
      incomingBubble: incomingBubble ?? this.incomingBubble,
      incomingBubbleBorder: incomingBubbleBorder ?? this.incomingBubbleBorder,
      border: border ?? this.border,
      softBorder: softBorder ?? this.softBorder,
      primaryText: primaryText ?? this.primaryText,
      secondaryText: secondaryText ?? this.secondaryText,
      placeholderText: placeholderText ?? this.placeholderText,
      onAccentText: onAccentText ?? this.onAccentText,
      icon: icon ?? this.icon,
      mutedIcon: mutedIcon ?? this.mutedIcon,
      online: online ?? this.online,
      readReceipt: readReceipt ?? this.readReceipt,
      cursor: cursor ?? this.cursor,
      shadow: shadow ?? this.shadow,
    );
  }

  @override
  ChatThemeColors lerp(ThemeExtension<ChatThemeColors>? other, double t) {
    if (other is! ChatThemeColors) return this;
    return ChatThemeColors(
      accent: Color.lerp(accent, other.accent, t)!,
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t)!,
      background: Color.lerp(background, other.background, t)!,
      backgroundSecondary: Color.lerp(
        backgroundSecondary,
        other.backgroundSecondary,
        t,
      )!,
      headerSurface: Color.lerp(headerSurface, other.headerSurface, t)!,
      glassSurface: Color.lerp(glassSurface, other.glassSurface, t)!,
      strongGlassSurface: Color.lerp(
        strongGlassSurface,
        other.strongGlassSurface,
        t,
      )!,
      composerSurface: Color.lerp(composerSurface, other.composerSurface, t)!,
      composerButtonSurface: Color.lerp(
        composerButtonSurface,
        other.composerButtonSurface,
        t,
      )!,
      menuSurface: Color.lerp(menuSurface, other.menuSurface, t)!,
      outgoingBubble: Color.lerp(outgoingBubble, other.outgoingBubble, t)!,
      outgoingBubbleBorder: Color.lerp(
        outgoingBubbleBorder,
        other.outgoingBubbleBorder,
        t,
      )!,
      incomingBubble: Color.lerp(incomingBubble, other.incomingBubble, t)!,
      incomingBubbleBorder: Color.lerp(
        incomingBubbleBorder,
        other.incomingBubbleBorder,
        t,
      )!,
      border: Color.lerp(border, other.border, t)!,
      softBorder: Color.lerp(softBorder, other.softBorder, t)!,
      primaryText: Color.lerp(primaryText, other.primaryText, t)!,
      secondaryText: Color.lerp(secondaryText, other.secondaryText, t)!,
      placeholderText: Color.lerp(placeholderText, other.placeholderText, t)!,
      onAccentText: Color.lerp(onAccentText, other.onAccentText, t)!,
      icon: Color.lerp(icon, other.icon, t)!,
      mutedIcon: Color.lerp(mutedIcon, other.mutedIcon, t)!,
      online: Color.lerp(online, other.online, t)!,
      readReceipt: Color.lerp(readReceipt, other.readReceipt, t)!,
      cursor: Color.lerp(cursor, other.cursor, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
    );
  }
}

extension ChatThemeLookup on BuildContext {
  ChatThemeColors get chatColors =>
      Theme.of(this).extension<ChatThemeColors>()!;
}

ThemeData buildAfaPayTheme(Brightness brightness) {
  final chatColors = brightness == Brightness.dark
      ? ChatThemeColors.dark
      : ChatThemeColors.light;
  final scheme = ColorScheme.fromSeed(
    seedColor: chatColors.accent,
    brightness: brightness,
  );

  return ThemeData(
    brightness: brightness,
    fontFamily: 'Roboto',
    scaffoldBackgroundColor: chatColors.background,
    colorScheme: scheme,
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: chatColors.cursor,
      selectionColor: chatColors.accentSoft,
      selectionHandleColor: chatColors.accent,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: chatColors.composerSurface,
      hintStyle: TextStyle(color: chatColors.placeholderText),
      prefixIconColor: chatColors.mutedIcon,
      suffixIconColor: chatColors.mutedIcon,
      contentPadding: const EdgeInsets.symmetric(vertical: 20),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: chatColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: chatColors.accent),
      ),
    ),
    extensions: <ThemeExtension<dynamic>>[chatColors],
    useMaterial3: true,
  );
}
