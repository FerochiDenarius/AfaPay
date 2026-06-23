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
          icon: Icon(Icons.chat_bubble_outline_rounded),
          selectedIcon: Icon(Icons.chat_bubble_rounded),
          label: 'Chats',
        ),
        NavigationDestination(
          icon: Icon(Icons.account_balance_wallet_outlined),
          selectedIcon: Icon(Icons.account_balance_wallet_rounded),
          label: 'Wallet',
        ),
        NavigationDestination(
          icon: Icon(Icons.contacts_outlined),
          selectedIcon: Icon(Icons.contacts_rounded),
          label: 'Contacts',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline_rounded),
          selectedIcon: Icon(Icons.person_rounded),
          label: 'Profile',
        ),
      ],
    );
  }
}

const _routes = ['/dashboard', '/chats', '/wallet', '/contacts', '/profile'];
