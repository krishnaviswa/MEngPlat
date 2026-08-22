import 'package:flutter/material.dart';
import 'package:merchanthub_mobile/ui/friendly_error.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:merchanthub_api/merchanthub_api.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/app_config.dart';
import '../auth/auth_provider.dart';
import '../businesses/business_list_provider.dart';
import 'gamified/celebration_step.dart';
import 'gamified/gamified_collect_flow.dart';
import 'rating_stars.dart';
import 'review_providers.dart';

/// Public, ungated review-collection landing screen for a QR/link scan --
/// mobile parity for M-71 (S-059 / S-118), a route-shaped sibling of web's
/// `/collect/[businessId]` (S-040). Reachable via `context.push` from the
/// merchant's "Preview in app" sheet, or a cold HTTPS `/collect/` App Link
/// (S-118). Path param may be a listing slug or UUID.
///
/// Not a reuse of [ReviewFormSheet], which is a bottom sheet opened from an
/// already-authenticated, already-loaded business detail screen -- the wrong
/// shape for a cold-launch-capable, potentially-unauthenticated destination.
/// Reuses the same underlying providers/repository/validation, not the sheet
/// widget itself.
class CollectReviewScreen extends ConsumerStatefulWidget {
  const CollectReviewScreen({required this.slug, super.key});

  final String slug;

  @override
  ConsumerState<CollectReviewScreen> createState() => _CollectReviewScreenState();
}

class _CollectReviewScreenState extends ConsumerState<CollectReviewScreen> {
  final _bodyController = TextEditingController();
  int _rating = 0;
  bool _submitting = false;
  bool _submitted = false;
  bool _celebrated = false;
  String? _error;

  @override
  void dispose() {
    _bodyController.dispose();
    super.dispose();
  }

  bool get _isValid => _rating >= 1 && _bodyController.text.trim().isNotEmpty;

  Future<void> _submit(BusinessResponse business) async {
    final isLoggedIn = ref.read(authControllerProvider).valueOrNull != null;
    if (!isLoggedIn) {
      context.push('/login?next=${Uri.encodeComponent('/collect/${widget.slug}')}');
      return;
    }
    if (!_isValid || _submitting) return;

    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref.read(reviewsControllerProvider(business.id).notifier).createReview(
            rating: _rating,
            body: _bodyController.text.trim(),
          );
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _submitted = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = friendlyMessage(e);
      });
    }
  }

  void _suggestGoogleReview(BusinessResponse business) {
    final query = Uri.encodeComponent('${business.name} ${business.city}');
    launchUrl(
      Uri.parse('https://www.google.com/maps/search/?api=1&query=$query'),
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  Widget build(BuildContext context) {
    final businessAsync = ref.watch(collectBusinessProvider(widget.slug));

    return Scaffold(
      key: const Key('collectReviewScreen'),
      appBar: AppBar(title: const Text('Leave a review')),
      body: businessAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _EmptyState(message: '$error'),
        data: (business) {
          if (business.status != BusinessStatus.approved) {
            return const _EmptyState(
              key: Key('collectReviewNotFound'),
              message: 'This review link is no longer available.',
            );
          }
          if (_submitted && AppConfig.gamifiedReview && !_celebrated) {
            return GamifiedCelebrationStep(onContinue: () => setState(() => _celebrated = true));
          }
          if (_submitted) return _SuccessState(onSuggestGoogleReview: () => _suggestGoogleReview(business));

          if (AppConfig.gamifiedReview) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(business.name, style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 16),
                  GamifiedCollectFlow(
                    rating: _rating,
                    onRatingSelected: (value) => setState(() => _rating = value),
                    bodyController: _bodyController,
                    error: _error,
                    submitting: _submitting,
                    onSubmit: () => _submit(business),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(business.name, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 16),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  ),
                Text('Rating', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 4),
                RatingStars(rating: _rating, size: 36, onChanged: (value) => setState(() => _rating = value)),
                const SizedBox(height: 16),
                TextField(
                  key: const Key('collectReviewBodyField'),
                  controller: _bodyController,
                  minLines: 4,
                  maxLines: 8,
                  decoration: const InputDecoration(labelText: 'Share details of your experience (a smiley is enough)'),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  key: const Key('collectReviewSubmitButton'),
                  onPressed: _submitting ? null : () => _submit(business),
                  child: _submitting ? const Text('Posting...') : const Text('Post review'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SuccessState extends StatelessWidget {
  const _SuccessState({required this.onSuggestGoogleReview});

  final VoidCallback onSuggestGoogleReview;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Thanks for your review!', key: Key('collectReviewSuccess')),
            const SizedBox(height: 16),
            OutlinedButton(
              key: const Key('suggestGoogleReviewButton'),
              onPressed: onSuggestGoogleReview,
              child: const Text('Also leave a Google review (optional)'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(message, textAlign: TextAlign.center),
      ),
    );
  }
}
