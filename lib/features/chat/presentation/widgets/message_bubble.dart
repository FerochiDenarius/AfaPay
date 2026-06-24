import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.text,
    required this.time,
    required this.isOutgoing,
    this.showReadReceipt = false,
  });

  final String text;
  final String time;
  final bool isOutgoing;
  final bool showReadReceipt;

  @override
  Widget build(BuildContext context) {
    final colors = context.chatColors;
    final maxWidth = MediaQuery.sizeOf(context).width * 0.7;

    return Align(
      alignment: isOutgoing ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth.clamp(188, 460)),
        margin: EdgeInsets.only(
          top: 6,
          bottom: 6,
          left: isOutgoing ? 46 : 0,
          right: isOutgoing ? 0 : 46,
        ),
        padding: const EdgeInsets.fromLTRB(18, 11, 16, 11),
        decoration: BoxDecoration(
          color: isOutgoing ? colors.outgoingBubble : colors.incomingBubble,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(
            color: isOutgoing
                ? colors.outgoingBubbleBorder
                : colors.incomingBubbleBorder,
          ),
          boxShadow: [
            BoxShadow(
              color: colors.shadow,
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: TextStyle(
                color: isOutgoing ? colors.onAccentText : colors.primaryText,
                fontSize: 16,
                height: 1.22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  time,
                  style: TextStyle(
                    color: isOutgoing
                        ? colors.onAccentText.withValues(alpha: 0.7)
                        : colors.secondaryText,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (showReadReceipt) ...[
                  const SizedBox(width: 8),
                  Icon(
                    Icons.done_all_rounded,
                    size: 20,
                    color: colors.readReceipt,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
