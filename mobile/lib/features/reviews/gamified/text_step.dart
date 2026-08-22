import 'package:flutter/material.dart';

class GamifiedTextStep extends StatelessWidget {
  const GamifiedTextStep({
    required this.controller,
    required this.error,
    required this.submitting,
    required this.onBack,
    required this.onSubmit,
    super.key,
  });

  final TextEditingController controller;
  final String? error;
  final bool submitting;
  final VoidCallback onBack;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Write your review', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        TextField(
          key: const Key('collectReviewBodyField'),
          controller: controller,
          minLines: 4,
          maxLines: 8,
          decoration: const InputDecoration(labelText: 'Share details of your experience (a smiley is enough)'),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(onPressed: onBack, child: const Text('← Back')),
            FilledButton(
              key: const Key('collectReviewSubmitButton'),
              onPressed: submitting ? null : onSubmit,
              child: Text(submitting ? 'Posting...' : 'Post review'),
            ),
          ],
        ),
      ],
    );
  }
}
