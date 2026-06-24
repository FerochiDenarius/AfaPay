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
    final isLight = Theme.of(context).brightness == Brightness.light;
    return NavigationBarTheme(
      data: NavigationBarThemeData(
        backgroundColor: isLight ? Colors.white : null,
        indicatorColor: isLight ? const Color(0xFFFFF3D5) : null,
        elevation: isLight ? 12 : null,
        shadowColor: isLight ? const Color(0x1A000000) : null,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected
                ? const Color(0xFFF5B81F)
                : (isLight ? const Color(0xFF7E7F83) : null),
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            color: selected
                ? const Color(0xFFF5B81F)
                : (isLight ? const Color(0xFF7E7F83) : null),
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 13,
          );
        }),
      ),
      child: NavigationBar(
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
      ),
    );
  }
}

const _routes = ['/dashboard', '/chats', '/wallet', '/contacts', '/profile'];
