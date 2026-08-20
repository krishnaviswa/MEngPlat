import 'package:flutter/material.dart';
import 'package:merchanthub_api/merchanthub_api.dart';

const _maxBullets = 3;
const _bulletMaxChars = 72;

/// Compact merchant AI insights: disclaimer plus a few truncated bullets.
/// Suggested owner replies belong on Reply / Draft with AI, not here.
class AiInsightsPanel extends StatelessWidget {
  const AiInsightsPanel({required this.insights, this.topics, super.key});

  final MerchantInsightsResponse insights;
  final TopicClusterResponse? topics;

  @override
  Widget build(BuildContext context) {
    final bullets = _compactBullets(insights);
    final summary = insights.merchantSummary?.trim();

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
          if (summary != null && summary.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(_truncate(summary), style: Theme.of(context).textTheme.bodyMedium),
          ],
          if (bullets.isNotEmpty) ...[
            const SizedBox(height: 8),
            for (final item in bullets) Text('• $item'),
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
              for (final topic in (topics!.topics ?? const <TopicItem>[]).take(_maxBullets))
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

List<String> _compactBullets(MerchantInsightsResponse insights) {
  final out = <String>[];
  for (final item in insights.frequentlyMentionedPositives) {
    if (out.length >= _maxBullets) break;
    final truncated = _truncate(item);
    if (truncated.isNotEmpty) out.add(truncated);
  }
  for (final item in insights.frequentlyMentionedComplaints) {
    if (out.length >= _maxBullets) break;
    final truncated = _truncate(item);
    if (truncated.isNotEmpty) out.add(truncated);
  }
  return out;
}

String _truncate(String value) {
  final trimmed = value.trim();
  if (trimmed.length <= _bulletMaxChars) return trimmed;
  return '${trimmed.substring(0, _bulletMaxChars - 1).trimRight()}…';
}
