import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class ChatHeader extends StatelessWidget {
  const ChatHeader({
    super.key,
    required this.username,
    required this.isOnline,
    required this.onBack,
    required this.onCall,
    required this.onVideoCall,
    required this.onMore,
    this.avatarUrl,
  });

  final String username;
  final bool isOnline;
  final VoidCallback onBack;
  final VoidCallback onCall;
  final VoidCallback onVideoCall;
  final VoidCallback onMore;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final colors = context.chatColors;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 520;
        final horizontalPadding = compact ? 12.0 : 24.0;
        final backSize = compact ? 44.0 : 72.0;
        final avatarSize = compact ? 50.0 : 74.0;
        final actionSize = compact ? 38.0 : 58.0;

        return Container(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            compact ? 10 : 12,
            horizontalPadding,
            compact ? 16 : 22,
          ),
          decoration: BoxDecoration(
            color: colors.headerSurface,
            border: Border(bottom: BorderSide(color: colors.softBorder)),
            boxShadow: [
              BoxShadow(
                color: colors.shadow,
                blurRadius: 22,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Row(
            children: [
              _HeaderIconButton(
                tooltip: 'Back',
                icon: Icons.arrow_back_rounded,
                dimension: backSize,
                iconSize: compact ? 30 : 36,
                onPressed: onBack,
              ),
              SizedBox(width: compact ? 8 : 16),
              _Avatar(avatarUrl: avatarUrl, dimension: avatarSize),
              SizedBox(width: compact ? 10 : 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      username,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.primaryText,
                        fontSize: compact ? 22 : 30,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: compact ? 10 : 12,
                          height: compact ? 10 : 12,
                          decoration: BoxDecoration(
                            color: isOnline
                                ? colors.online
                                : colors.secondaryText,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            isOnline ? 'Online' : 'Offline',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colors.secondaryText,
                              fontSize: compact ? 14 : 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: compact ? 8 : 14),
              _HeaderActionGroup(
                actionSize: actionSize,
                iconSize: compact ? 21 : 28,
                onCall: onCall,
                onVideoCall: onVideoCall,
                onMore: onMore,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.dimension, this.avatarUrl});

  final double dimension;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final colors = context.chatColors;

    return Container(
      width: dimension,
      height: dimension,
      decoration: BoxDecoration(
        color: colors.accentSoft,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: avatarUrl == null
          ? Icon(
              Icons.person_rounded,
              color: colors.accent,
              size: dimension * 0.57,
            )
          : Image.network(avatarUrl!, fit: BoxFit.cover),
    );
  }
}

class _HeaderActionGroup extends StatelessWidget {
  const _HeaderActionGroup({
    required this.actionSize,
    required this.iconSize,
    required this.onCall,
    required this.onVideoCall,
    required this.onMore,
  });

  final double actionSize;
  final double iconSize;
  final VoidCallback onCall;
  final VoidCallback onVideoCall;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    final colors = context.chatColors;

    return Container(
      decoration: BoxDecoration(
        color: colors.glassSurface,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: colors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _GroupedHeaderButton(
            tooltip: 'Call',
            icon: Icons.call_outlined,
            dimension: actionSize,
            iconSize: iconSize,
            onPressed: onCall,
          ),
          _DividerLine(height: actionSize * 0.86),
          _GroupedHeaderButton(
            tooltip: 'Video call',
            icon: Icons.videocam_outlined,
            dimension: actionSize,
            iconSize: iconSize,
            onPressed: onVideoCall,
          ),
          _DividerLine(height: actionSize * 0.86),
          _GroupedHeaderButton(
            tooltip: 'More',
            icon: Icons.more_vert_rounded,
            dimension: actionSize,
            iconSize: iconSize,
            onPressed: onMore,
          ),
        ],
      ),
    );
  }
}

class _DividerLine extends StatelessWidget {
  const _DividerLine({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: height,
      color: context.chatColors.border,
    );
  }
}

class _GroupedHeaderButton extends StatelessWidget {
  const _GroupedHeaderButton({
    required this.tooltip,
    required this.icon,
    required this.dimension,
    required this.iconSize,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final double dimension;
  final double iconSize;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.chatColors;

    return SizedBox.square(
      dimension: dimension,
      child: IconButton(
        tooltip: tooltip,
        color: colors.icon,
        onPressed: onPressed,
        icon: Icon(icon, size: iconSize),
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.tooltip,
    required this.icon,
    required this.dimension,
    required this.iconSize,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final double dimension;
  final double iconSize;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.chatColors;

    return SizedBox.square(
      dimension: dimension,
      child: IconButton(
        tooltip: tooltip,
        style: IconButton.styleFrom(
          backgroundColor: colors.glassSurface,
          foregroundColor: colors.icon,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: colors.border),
          ),
        ),
        onPressed: onPressed,
        icon: Icon(icon, size: iconSize),
      ),
    );
  }
}
