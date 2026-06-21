import 'package:flutter/material.dart';

class EmailSecurityIllustration extends StatelessWidget {
  const EmailSecurityIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Secure email verification illustration',
      image: true,
      child: AspectRatio(
        aspectRatio: 1.9,
        child: ClipRect(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              return Stack(
                fit: StackFit.expand,
                children: [
                  Positioned(
                    top: -width * 0.61,
                    left: 0,
                    width: width,
                    child: Image.asset(
                      'UIdesignImages/EmailEntryPage.png',
                      fit: BoxFit.fitWidth,
                      alignment: Alignment.topCenter,
                    ),
                  ),
                  const Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    height: 18,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFF03112D), Colors.transparent],
                        ),
                      ),
                    ),
                  ),
                  const Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: 18,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Color(0xFF02102A)],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
