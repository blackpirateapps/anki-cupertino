import 'package:flutter/cupertino.dart';

class GlassCard extends StatelessWidget {
  const GlassCard({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFF1B1E25),
            Color(0xFF16181E),
          ],
        ),
        border: Border.all(color: const Color(0xFF2B2F38)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            blurRadius: 24,
            offset: Offset(0, 16),
            color: Color(0x33000000),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: child,
      ),
    );
  }
}

