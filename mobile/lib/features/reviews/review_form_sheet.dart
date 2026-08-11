import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'review_providers.dart';
import 'rating_stars.dart';

/// Same per-review photo cap as the web frontend (`ReviewForm.tsx`'s
/// `MAX_PHOTOS`).
const _maxPhotos = 5;

/// Bottom sheet for submitting a review: rating (required), title
/// (optional), body (required, min 10 chars), optional photo attach.
/// Mirrors `frontend/src/components/ReviewForm.tsx`. Not a route -- transient
/// UI with no back-stack entry, per the Architect spec.
class ReviewFormSheet extends ConsumerStatefulWidget {
  const ReviewFormSheet({required this.businessId, super.key});

  final String businessId;

  static Future<void> show(BuildContext context, {required String businessId}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => ReviewFormSheet(businessId: businessId),
    );
  }

  @override
  ConsumerState<ReviewFormSheet> createState() => _ReviewFormSheetState();
}

class _ReviewFormSheetState extends ConsumerState<ReviewFormSheet> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _picker = ImagePicker();
  final List<XFile> _photos = [];

  int _rating = 0;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  bool get _isValid => _rating >= 1 && _bodyController.text.trim().length >= 10;

  Future<void> _pickFromGallery() async {
    final remaining = _maxPhotos - _photos.length;
    if (remaining <= 0) return;
    final picked = await _picker.pickMultiImage(limit: remaining);
    if (picked.isEmpty) return;
    setState(() => _photos.addAll(picked.take(remaining)));
  }

  Future<void> _pickFromCamera() async {
    if (_photos.length >= _maxPhotos) return;
    final photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo == null) return;
    setState(() => _photos.add(photo));
  }

  /// Creates the review, then best-effort uploads any attached photos. A
  /// failed photo upload never rolls back the already-posted review -- it
  /// only adds to the non-blocking warning count shown afterwards (AC9). A
  /// failure creating the review itself keeps the entered fields so the user
  /// can retry without retyping (AC11).
  Future<void> _submit() async {
    if (!_isValid || _loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    final controller = ref.read(reviewsControllerProvider(widget.businessId).notifier);
    final title = _titleController.text.trim();

    try {
      final review = await controller.createReview(
        rating: _rating,
        title: title.isEmpty ? null : title,
        body: _bodyController.text.trim(),
      );

      var failedPhotoCount = 0;
      for (final photo in _photos) {
        try {
          await controller.uploadPhoto(reviewId: review.id, filePath: photo.path);
        } catch (_) {
          failedPhotoCount++;
        }
      }

      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            failedPhotoCount > 0
                ? 'Review posted, but $failedPhotoCount photo${failedPhotoCount > 1 ? 's' : ''} failed to upload.'
                : 'Review posted',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Write a review', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ),
            Text('Rating', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 4),
            RatingStars(rating: _rating, size: 32, onChanged: (value) => setState(() => _rating = value)),
            const SizedBox(height: 16),
            TextField(
              key: const Key('reviewTitleField'),
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title (optional)'),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('reviewBodyField'),
              controller: _bodyController,
              minLines: 4,
              maxLines: 8,
              decoration: const InputDecoration(labelText: 'Share details of your experience (min 10 characters)'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            Text('Photos (optional, up to $_maxPhotos)', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final photo in _photos)
                  SizedBox(
                    width: 56,
                    height: 56,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          // XFile.readAsBytes works on mobile and Flutter web
                          // (dart:io Image.file does not) -- matches the project's
                          // documented web-first mobile Dev loop.
                          child: FutureBuilder<Uint8List>(
                            future: photo.readAsBytes(),
                            builder: (context, snapshot) {
                              final bytes = snapshot.data;
                              if (bytes == null) {
                                return const SizedBox(
                                  width: 56,
                                  height: 56,
                                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                );
                              }
                              return Image.memory(bytes, width: 56, height: 56, fit: BoxFit.cover);
                            },
                          ),
                        ),
                        Positioned(
                          top: -10,
                          right: -10,
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: const Icon(Icons.cancel, size: 18),
                            onPressed: () => setState(() => _photos.remove(photo)),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (_photos.length < _maxPhotos)
                  OutlinedButton.icon(
                    onPressed: _loading ? null : _pickFromGallery,
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Gallery'),
                  ),
                if (_photos.length < _maxPhotos)
                  OutlinedButton.icon(
                    onPressed: _loading ? null : _pickFromCamera,
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('Camera'),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            FilledButton(
              key: const Key('submitReviewButton'),
              onPressed: (_loading || !_isValid) ? null : _submit,
              child: _loading
                  ? const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        ),
                        SizedBox(width: 8),
                        Text('Posting...'),
                      ],
                    )
                  : const Text('Post review'),
            ),
          ],
        ),
      ),
    );
  }
}
