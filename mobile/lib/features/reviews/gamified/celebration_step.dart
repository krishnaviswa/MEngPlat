import 'dart:async';

import 'package:flutter/material.dart';

/// Brief celebratory acknowledgment after a successful submit, then hands off
/// to the existing `_SuccessState` screen.
class GamifiedCelebrationStep extends StatefulWidget {
  const GamifiedCelebrationStep({required this.onContinue, super.key});

  final VoidCallback onContinue;

  @override
  State<GamifiedCelebrationStep> createState() => _GamifiedCelebrationStepState();
}

class _GamifiedCelebrationStepState extends State<GamifiedCelebrationStep> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 1400), widget.onContinue);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      key: const Key('collectReviewCelebration'),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.6, end: 1.0),
              duration: const Duration(milliseconds: 500),
              curve: Curves.elasticOut,
              builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
              child: const CircleAvatar(
                radius: 32,
                backgroundColor: Color(0xFFDCFCE7),
                child: Icon(Icons.check, color: Color(0xFF16A34A), size: 32),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Review submitted!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 4),
            const Text('Thanks for taking the time — nice job.'),
            const SizedBox(height: 16),
            TextButton(key: const Key('collectReviewCelebrationContinue'), onPressed: widget.onContinue, child: const Text('Continue →')),
          ],
        ),
      ),
    );
  }
}
