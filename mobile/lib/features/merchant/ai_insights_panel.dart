import 'package:flutter/material.dart';
import 'package:merchanthub_api/merchanthub_api.dart';

/// Merchant AI insights with a required suggestion-only disclaimer (M-52).
class AiInsightsPanel extends StatelessWidget {
  const AiInsightsPanel({required this.insights, super.key});

  final MerchantInsightsResponse insights;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('aiInsightsPanel'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('AI Insights', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Suggestions only — not definitive judgments. Verify in person before acting.',
            key: const Key('aiInsightsDisclaimer'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (insights.merchantSummary != null && insights.merchantSummary!.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('Overall Summary', style: Theme.of(context).textTheme.titleSmall),
            Text(insights.merchantSummary!),
          ],
          const SizedBox(height: 12),
          Text('Frequently Mentioned Positives', style: Theme.of(context).textTheme.titleSmall),
          ...insights.frequentlyMentionedPositives.map((item) => Text('• $item')),
          const SizedBox(height: 8),
          Text('Frequently Mentioned Complaints', style: Theme.of(context).textTheme.titleSmall),
          ...insights.frequentlyMentionedComplaints.map((item) => Text('• $item')),
          if (insights.suggestedResponses.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Suggested Owner Responses', style: Theme.of(context).textTheme.titleSmall),
            ...insights.suggestedResponses.map(
              (item) => Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('“$item”', style: const TextStyle(fontStyle: FontStyle.italic)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
