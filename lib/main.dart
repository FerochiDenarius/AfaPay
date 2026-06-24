import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

void main() {
  runApp(const ProviderScope(child: AfaPayApp()));
}

class AfaPayApp extends StatelessWidget {
  const AfaPayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'AfaPay',
      debugShowCheckedModeBanner: false,
      theme: buildAfaPayTheme(Brightness.light),
      darkTheme: buildAfaPayTheme(Brightness.dark),
      themeMode: ThemeMode.system,
      routerConfig: appRouter,
    );
  }
}
