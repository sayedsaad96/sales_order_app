import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

/// A reusable confetti celebration overlay.
/// Call [ConfettiOverlay.show(context)] to blast confetti from the top center.
class ConfettiOverlay {
  static void show(BuildContext context) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    final controller = ConfettiController(duration: const Duration(seconds: 2));

    entry = OverlayEntry(
      builder: (context) => Positioned.fill(
        child: IgnorePointer(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: controller,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              numberOfParticles: 50,
              maxBlastForce: 30,
              minBlastForce: 10,
              emissionFrequency: 0.05,
              gravity: 0.15,
              colors: const [
                Colors.green,
                Colors.blue,
                Colors.pink,
                Colors.orange,
                Colors.purple,
                Colors.yellow,
                Colors.red,
                Colors.tealAccent,
              ],
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);
    controller.play();

    // Auto-remove after the animation completes
    Future.delayed(const Duration(seconds: 4), () {
      entry.remove();
      controller.dispose();
    });
  }
}
