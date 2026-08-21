import 'package:flutter/material.dart';
import 'package:merchanthub_api/merchanthub_api.dart';

import '../../core/config/app_config.dart';
import '../businesses/photo_gallery.dart';
import 'rating_stars.dart';

const _truncateThreshold = 280;

/// Single review list item: reviewer name, star rating, title/body, an AI
/// sentiment badge (clearly labeled as AI, never a verified fact -- S-023
/// AC2), photo strip, like/report (S-030), optional merchant reply, and
/// optional reply composer (S-031 / M-53). Mirrors `frontend/src/components/ReviewCard.tsx`.
class ReviewCard extends StatefulWidget {
  const ReviewCard({
    required this.review,
    this.showActions = true,
    this.canReply = false,
    this.reported = false,
    this.onLike,
    this.onReport,
    this.onReply,
    this.onRequireLogin,
    super.key,
  });

  final ReviewResponse review;
  final bool showActions;
  final bool canReply;
  final bool reported;
  final VoidCallback? onLike;
  final Future<void> Function(String reason)? onReport;
  final Future<void> Function(String body)? onReply;
  final VoidCallback? onRequireLogin;

  static String _resolveUrl(String url) => url.startsWith('http') ? url : '${AppConfig.apiBaseUrl}$url';

  @override
  State<ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends State<ReviewCard> {
  bool _reporting = false;
  bool _replying = false;
  bool _submittingReply = false;
  bool _submittingReport = false;
  bool _expanded = false;
  String? _actionError;
  final _reportController = TextEditingController();
  final _replyController = TextEditingController();

  @override
  void dispose() {
    _reportController.dispose();
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    final reason = _reportController.text.trim();
    if (reason.length < 10 || widget.onReport == null) return;
    setState(() {
      _submittingReport = true;
      _actionError = null;
    });
    try {
      await widget.onReport!(reason);
      if (!mounted) return;
      setState(() {
        _reporting = false;
        _reportController.clear();
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _actionError = error.toString());
    } finally {
      if (mounted) setState(() => _submittingReport = false);
    }
  }

  Future<void> _submitReply() async {
    final body = _replyController.text.trim();
    if (body.length < 5 || widget.onReply == null) return;
    setState(() {
      _submittingReply = true;
      _actionError = null;
    });
    try {
      await widget.onReply!(body);
      if (!mounted) return;
      setState(() {
        _replying = false;
        _replyController.clear();
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _actionError = error.toString());
    } finally {
      if (mounted) setState(() => _submittingReply = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.reported) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Text('Reported — pending moderation.', key: Key('reviewReportedPlaceholder')),
      );
    }

    final review = widget.review;
    final sentiment = review.aiAnalysis?.sentiment;
    final photoUrls = review.photoUrls?.toList() ?? const <String>[];
    final reply = review.reply;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review.author?.fullName ?? 'Customer', style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 4),
                    RatingStars(rating: review.rating),
                  ],
                ),
              ),
              if (sentiment != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _sentimentColor(sentiment).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'AI: ${sentiment.name}',
                    style: TextStyle(fontSize: 12, color: _sentimentColor(sentiment)),
                  ),
                ),
            ],
          ),
          if (review.title != null) ...[
            const SizedBox(height: 8),
            Text(review.title!, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          ],
          const SizedBox(height: 4),
          Text(
            review.body,
            maxLines: _expanded ? null : 3,
            overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
          ),
          if (review.body.length > _truncateThreshold)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: TextButton(
                key: const Key('reviewReadMoreToggle'),
                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 32)),
                onPressed: () => setState(() => _expanded = !_expanded),
                child: Text(_expanded ? 'Read less' : 'Read more'),
              ),
            ),
          if (review.aiAnalysis?.summary != null) ...[
            const SizedBox(height: 8),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'AI summary (suggestion): ',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(
                    text: review.aiAnalysis!.summary!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
          if (photoUrls.isNotEmpty) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 64,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: photoUrls.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final resolvedUrls = photoUrls.map(ReviewCard._resolveUrl).toList();
                  return GestureDetector(
                    key: Key('reviewPhotoThumb_$index'),
                    onTap: () => PhotoGallery.openLightbox(context, urls: resolvedUrls, initialIndex: index),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        resolvedUrls[index],
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                        cacheWidth: (64 * MediaQuery.devicePixelRatioOf(context)).round().clamp(1, 4096),
                        cacheHeight: (64 * MediaQuery.devicePixelRatioOf(context)).round().clamp(1, 4096),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
          if (widget.showActions) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                TextButton.icon(
                  key: const Key('reviewLikeButton'),
                  onPressed: widget.onLike,
                  icon: const Icon(Icons.thumb_up_outlined, size: 18),
                  label: Text('${review.likeCount}'),
                ),
                if (!_reporting)
                  TextButton(
                    key: const Key('reviewReportButton'),
                    onPressed: () {
                      if (widget.onReport == null) {
                        widget.onRequireLogin?.call();
                        return;
                      }
                      setState(() => _reporting = true);
                    },
                    child: const Text('Report'),
                  ),
              ],
            ),
          ],
          if (_reporting) ...[
            const SizedBox(height: 8),
            TextField(
              key: const Key('reviewReportReason'),
              controller: _reportController,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Why are you reporting this review? (min 10 characters)',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                FilledButton(
                  key: const Key('reviewReportSubmit'),
                  onPressed: _reportController.text.trim().length < 10 || _submittingReport ? null : _submitReport,
                  child: Text(_submittingReport ? 'Submitting...' : 'Submit report'),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => setState(() {
                    _reporting = false;
                    _reportController.clear();
                  }),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ],
          if (reply != null) ...[
            const SizedBox(height: 8),
            Container(
              key: const Key('merchantReplyBlock'),
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border(left: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)),
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Response from the business', style: Theme.of(context).textTheme.labelSmall),
                  const SizedBox(height: 4),
                  Text(reply.body),
                ],
              ),
            ),
          ],
          if (widget.canReply && reply == null && !_replying)
            TextButton(
              key: const Key('reviewReplyButton'),
              onPressed: () => setState(() => _replying = true),
              child: const Text('Reply as business'),
            ),
          if (widget.canReply && reply == null && _replying) ...[
            const SizedBox(height: 8),
            TextField(
              key: const Key('reviewReplyBody'),
              controller: _replyController,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Write a response to this review',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 4),
            Text(
              'AI draft is a suggestion — edit before sending. It is not posted automatically.',
              key: const Key('aiDraftDisclaimer'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (review.aiAnalysis?.suggestedResponse != null &&
                    review.aiAnalysis!.suggestedResponse!.trim().isNotEmpty)
                  OutlinedButton(
                    key: const Key('draftWithAiButton'),
                    onPressed: () {
                      _replyController.text = review.aiAnalysis!.suggestedResponse!;
                      setState(() {});
                    },
                    child: const Text('Draft with AI'),
                  )
                else
                  Text('No draft available', key: const Key('noAiDraftLabel'), style: Theme.of(context).textTheme.bodySmall),
                FilledButton(
                  key: const Key('reviewReplySubmit'),
                  onPressed: _replyController.text.trim().length < 5 || _submittingReply ? null : _submitReply,
                  child: Text(_submittingReply ? 'Posting...' : 'Post reply'),
                ),
                TextButton(
                  onPressed: () => setState(() {
                    _replying = false;
                    _replyController.clear();
                  }),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ],
          if (_actionError != null) ...[
            const SizedBox(height: 8),
            Text(_actionError!, key: const Key('reviewActionError'), style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
        ],
      ),
    );
  }

  Color _sentimentColor(Sentiment sentiment) {
    if (sentiment == Sentiment.positive) return Colors.green;
    if (sentiment == Sentiment.negative) return Colors.red;
    return Colors.grey;
  }
}
