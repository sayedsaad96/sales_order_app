import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'dart:math';

/// A reusable overlay for showing sadness/loss (e.g. return orders).
/// Call [LossOverlay.show(context)] to simulate rain or teardrops.
class LossOverlay {
  static void show(BuildContext context) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    final controller = ConfettiController(duration: const Duration(seconds: 3));

    // Custom path to draw a teardrop shape
    Path drawTearDrop(Size size) {
      final path = Path();
      path.moveTo(size.width / 2, 0);
      path.quadraticBezierTo(size.width, size.height * 0.6, size.width / 2, size.height);
      path.quadraticBezierTo(0, size.height * 0.6, size.width / 2, 0);
      path.close();
      return path;
    }

    entry = OverlayEntry(
      builder: (context) => Positioned.fill(
        child: IgnorePointer(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: controller,
              blastDirectionality: BlastDirectionality.directional,
              blastDirection: pi / 2, // Straight down
              shouldLoop: false,
              numberOfParticles: 40,
              maxBlastForce: 15,
              minBlastForce: 5,
              emissionFrequency: 0.1,
              gravity: 0.3, // Faster fall like rain
              createParticlePath: drawTearDrop,
              colors: const [
                Colors.blueGrey,
                Colors.grey,
                Colors.lightBlueAccent,
                Color(0xFF546E7A),
                Color(0xFF78909C),
              ],
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);
    controller.play();

    // Auto-remove after the animation completes
    Future.delayed(const Duration(seconds: 5), () {
      entry.remove();
      controller.dispose();
    });
  }
}
