import 'package:flutter/material.dart';
import 'package:merchanthub_api/merchanthub_api.dart';

/// Merchant AI insights with a required suggestion-only disclaimer (M-52).
class AiInsightsPanel extends StatelessWidget {
  const AiInsightsPanel({required this.insights, this.topics, super.key});

  final MerchantInsightsResponse insights;
  final TopicClusterResponse? topics;

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
          if (topics != null &&
              (topics!.insufficientData == true ||
                  topics!.unavailable == true ||
                  (topics!.topics?.isNotEmpty ?? false))) ...[
            const SizedBox(height: 12),
            Text('Common Themes', key: const Key('commonThemesHeading'), style: Theme.of(context).textTheme.titleSmall),
            if (topics!.insufficientData == true)
              const Text('Not enough reviews yet to identify common themes.')
            else if (topics!.unavailable == true)
              const Text('Common themes are temporarily unavailable.')
            else
              for (final topic in topics!.topics ?? const <TopicItem>[])
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '${topics!.degraded == true ? 'Mock/degraded data. ' : ''}${topic.label} — ${topic.count} mentions · ${topic.sentiment.name} (suggestion)',
                  ),
                ),
          ],
        ],
      ),
    );
  }
}
