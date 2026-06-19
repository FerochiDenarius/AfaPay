import 'package:flutter/material.dart';

import 'screens/registration_screen.dart';

void main() {
  runApp(const AfaPayApp());
}

class AfaPayApp extends StatelessWidget {
  const AfaPayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AfaPay',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF020712),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFF3A900),
          brightness: Brightness.dark,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF0B111D).withValues(alpha: 0.82),
          hintStyle: const TextStyle(color: Color(0xFF92959E)),
          prefixIconColor: const Color(0xFF92959E),
          suffixIconColor: const Color(0xFF92959E),
          contentPadding: const EdgeInsets.symmetric(vertical: 20),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF303541)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFF2A900)),
          ),
        ),
        useMaterial3: true,
      ),
      home: const RegistrationScreen(),
    );
  }
}
