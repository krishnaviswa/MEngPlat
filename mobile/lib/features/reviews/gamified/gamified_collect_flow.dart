import 'package:flutter/material.dart';

import 'star_step.dart';
import 'text_step.dart';

enum _GamifiedScreen { stars, text }

/// Tap-through, one-question-at-a-time presentation of stars -> text (S-119).
/// No chip step on mobile v1 -- today's mobile form has no chip/"what stood
/// out" step and no `DraftEngine`-equivalent starter-text generator; that
/// parity gap is intentional and logged in README §12.
///
/// All rating/body/submit state stays owned by the parent screen -- this
/// widget is presentation/interaction only, using only Flutter's built-in
/// `AnimatedSwitcher` (no new pubspec dependency).
class GamifiedCollectFlow extends StatefulWidget {
  const GamifiedCollectFlow({
    required this.rating,
    required this.onRatingSelected,
    required this.bodyController,
    required this.error,
    required this.submitting,
    required this.onSubmit,
    super.key,
  });

  final int rating;
  final ValueChanged<int> onRatingSelected;
  final TextEditingController bodyController;
  final String? error;
  final bool submitting;
  final VoidCallback onSubmit;

  @override
  State<GamifiedCollectFlow> createState() => _GamifiedCollectFlowState();
}

class _GamifiedCollectFlowState extends State<GamifiedCollectFlow> {
  _GamifiedScreen _screen = _GamifiedScreen.stars;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      switchInCurve: Curves.elasticOut,
      transitionBuilder: (child, animation) =>
          ScaleTransition(scale: animation, child: FadeTransition(opacity: animation, child: child)),
      child: _screen == _GamifiedScreen.stars
          ? GamifiedStarStep(
              key: const ValueKey('gamifiedStarStep'),
              rating: widget.rating,
              onSelect: (value) {
                widget.onRatingSelected(value);
                setState(() => _screen = _GamifiedScreen.text);
              },
            )
          : GamifiedTextStep(
              key: const ValueKey('gamifiedTextStep'),
              controller: widget.bodyController,
              error: widget.error,
              submitting: widget.submitting,
              onBack: () => setState(() => _screen = _GamifiedScreen.stars),
              onSubmit: widget.onSubmit,
            ),
    );
  }
}
