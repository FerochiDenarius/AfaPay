import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class AttachmentMenuPopup extends StatelessWidget {
  const AttachmentMenuPopup({
    super.key,
    required this.onDocument,
    required this.onGallery,
    required this.onContact,
    required this.onLocation,
    required this.onPoll,
    required this.onEvent,
  });

  final VoidCallback onDocument;
  final VoidCallback onGallery;
  final VoidCallback onContact;
  final VoidCallback onLocation;
  final VoidCallback onPoll;
  final VoidCallback onEvent;

  @override
  Widget build(BuildContext context) {
    final colors = context.chatColors;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomLeft,
      children: [
        Container(
          width: 244,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colors.menuSurface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: colors.border),
            boxShadow: [
              BoxShadow(
                color: colors.shadow,
                blurRadius: 24,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _AttachmentMenuItem(
                label: 'Document',
                icon: Icons.description_outlined,
                onTap: onDocument,
              ),
              _AttachmentMenuItem(
                label: 'Gallery',
                icon: Icons.photo_library_outlined,
                onTap: onGallery,
              ),
              _AttachmentMenuItem(
                label: 'Contact',
                icon: Icons.person_add_alt_1_outlined,
                onTap: onContact,
              ),
              _AttachmentMenuItem(
                label: 'Location',
                icon: Icons.location_on_outlined,
                onTap: onLocation,
              ),
              _AttachmentMenuItem(
                label: 'Poll',
                icon: Icons.poll_outlined,
                onTap: onPoll,
              ),
              _AttachmentMenuItem(
                label: 'Event',
                icon: Icons.event_outlined,
                onTap: onEvent,
              ),
            ],
          ),
        ),
        Positioned(
          left: 28,
          bottom: -12,
          child: Transform.rotate(
            angle: 0.785398,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: colors.menuSurface,
                border: Border(
                  right: BorderSide(color: colors.border),
                  bottom: BorderSide(color: colors.border),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AttachmentMenuItem extends StatelessWidget {
  const _AttachmentMenuItem({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.chatColors;

    return SizedBox(
      width: 68,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: colors.composerButtonSurface,
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.softBorder),
                ),
                child: Icon(icon, color: colors.icon, size: 21),
              ),
              const SizedBox(height: 7),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.primaryText,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
