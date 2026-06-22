import 'package:flutter/material.dart';

class AfaBottomNavigation extends StatelessWidget {
  const AfaBottomNavigation({
    super.key,
    required this.currentRoute,
    required this.onSelected,
  });

  final String currentRoute;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final index = _routes.indexOf(currentRoute);
    return NavigationBar(
      selectedIndex: index < 0 ? 0 : index,
      onDestinationSelected: (selectedIndex) {
        onSelected(_routes[selectedIndex]);
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.receipt_long_outlined),
          selectedIcon: Icon(Icons.receipt_long_rounded),
          label: 'Activity',
        ),
        NavigationDestination(
          icon: Icon(Icons.qr_code_2_outlined),
          selectedIcon: Icon(Icons.qr_code_2_rounded),
          label: 'Pay',
        ),
        NavigationDestination(
          icon: Icon(Icons.contacts_outlined),
          selectedIcon: Icon(Icons.contacts_rounded),
          label: 'Contacts',
        ),
        NavigationDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings_rounded),
          label: 'Settings',
        ),
      ],
    );
  }
}

const _routes = ['/dashboard', '/activity', '/pay', '/contacts', '/settings'];
