import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

const _gold = Color(0xFFF5B81F);
const _navy = Color(0xFF020712);
const _panel = Color(0xFF07101C);
const _muted = Color(0xFFA9ABB2);

class CallLandingScreen extends StatelessWidget {
  const CallLandingScreen({super.key, required this.isVideo});

  final bool isVideo;

  @override
  Widget build(BuildContext context) {
    final title = isVideo ? 'Video Call' : 'Voice Call';
    final icon = isVideo ? Icons.videocam_outlined : Icons.call_outlined;

    return Scaffold(
      backgroundColor: _navy,
      appBar: AppBar(backgroundColor: _navy, title: Text(title)),
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _panel,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF22334A)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: _gold, size: 64),
              const SizedBox(height: 18),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Call setup needs a live call provider token endpoint before real calls can start.',
                textAlign: TextAlign.center,
                style: TextStyle(color: _muted, height: 1.35),
              ),
              const SizedBox(height: 22),
              FilledButton(
                onPressed: () => context.go('/chats'),
                child: const Text('Back to Chats'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
