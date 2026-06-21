import 'package:flutter/material.dart';

class OnboardingCompleteScreen extends StatelessWidget {
  const OnboardingCompleteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.verified_rounded, color: Color(0xFFF5B81F), size: 82),
              SizedBox(height: 24),
              Text(
                'Email Verified',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 10),
              Text(
                'Required verification is complete. Optional OCR can be '
                'added or skipped in the next onboarding stage.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFFA9ABB2), fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
