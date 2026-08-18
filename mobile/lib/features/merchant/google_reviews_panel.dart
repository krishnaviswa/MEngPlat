import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:merchanthub_api/merchanthub_api.dart';

import 'merchant_providers.dart';

/// Link / sync Google review samples (M-80). Candidates are a list, not a map.
class GoogleReviewsPanel extends ConsumerStatefulWidget {
  const GoogleReviewsPanel({required this.business, super.key});

  final BusinessResponse business;

  @override
  ConsumerState<GoogleReviewsPanel> createState() => _GoogleReviewsPanelState();
}

class _GoogleReviewsPanelState extends ConsumerState<GoogleReviewsPanel> {
  GoogleReviewsStatusResponse? _status;
  String? _error;
  bool _loading = true;
  bool _showPicker = false;
  bool _searching = false;
  bool _syncing = false;
  late final TextEditingController _queryController;
  List<GooglePlaceCandidateResponse> _candidates = [];
  String? _selectedPlaceId;
  bool _searched = false;

  @override
  void initState() {
    super.initState();
    _queryController = TextEditingController(text: widget.business.name);
    _load();
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant GoogleReviewsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.business.id != widget.business.id) {
      _queryController.text = widget.business.name;
      _showPicker = false;
      _candidates = [];
      _selectedPlaceId = null;
      _searched = false;
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final status = await ref.read(dashboardRepositoryProvider).googleReviewsStatus(widget.business.id);
      if (!mounted) return;
      setState(() {
        _status = status;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  Future<void> _search() async {
    final query = _queryController.text.trim();
    if (query.length < 2) return;
    setState(() {
      _searching = true;
      _error = null;
    });
    try {
      final result = await ref.read(dashboardRepositoryProvider).searchGooglePlaces(
        businessId: widget.business.id,
        query: query,
      );
      if (!mounted) return;
      setState(() {
        _candidates = result.candidates.toList();
        _selectedPlaceId = null;
        _searched = true;
        _searching = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _searching = false;
      });
    }
  }

  Future<void> _link() async {
    final placeId = _selectedPlaceId;
    if (placeId == null) return;
      GooglePlaceCandidateResponse? selected;
      for (final candidate in _candidates) {
        if (candidate.placeId == placeId) selected = candidate;
      }
    try {
      await ref.read(dashboardRepositoryProvider).linkGooglePlace(
        businessId: widget.business.id,
        placeId: placeId,
        name: selected?.name,
        address: selected?.address,
      );
      if (!mounted) return;
      setState(() => _showPicker = false);
      await _load();
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    }
  }

  Future<void> _sync() async {
    setState(() {
      _syncing = true;
      _error = null;
    });
    try {
      await ref.read(dashboardRepositoryProvider).syncGoogleReviews(widget.business.id);
      await _load();
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('googleReviewsPanel'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Google reviews', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          'Up to 5 Google samples on your public profile — not a full history, and not mixed into your MerchantHub rating.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        if (_loading)
          const Center(child: CircularProgressIndicator())
        else if (_error != null) ...[
          Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          OutlinedButton(onPressed: _load, child: const Text('Retry')),
        ] else if (_status?.linked != true) ...[
          if (!_showPicker)
            OutlinedButton(
              key: const Key('linkGoogleProfileButton'),
              onPressed: () => setState(() => _showPicker = true),
              child: const Text('Link Google Business Profile'),
            )
          else ...[
            TextField(
              key: const Key('googlePlacesQuery'),
              controller: _queryController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Search for your business on Google',
              ),
            ),
            const SizedBox(height: 8),
            FilledButton(
              key: const Key('googlePlacesSearchButton'),
              onPressed: _searching ? null : _search,
              child: Text(_searching ? 'Searching...' : 'Search'),
            ),
            if (_searched && _candidates.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('No matches. Try a different search term.'),
              ),
            for (final candidate in _candidates)
              ListTile(
                key: Key('googleCandidate-${candidate.placeId}'),
                selected: _selectedPlaceId == candidate.placeId,
                title: Text(candidate.name),
                subtitle: Text(candidate.address),
                onTap: () => setState(() => _selectedPlaceId = candidate.placeId),
              ),
            if (_candidates.isNotEmpty)
              FilledButton(
                key: const Key('linkGooglePlaceButton'),
                onPressed: _selectedPlaceId == null ? null : _link,
                child: const Text('Link this business'),
              ),
          ],
        ] else ...[
          Text(
            (_status!.reviewCount > 0)
                ? '${_status!.reviewCount} review${_status!.reviewCount == 1 ? '' : 's'} synced'
                : 'Linked — not yet synced',
            key: const Key('googleReviewsStatus'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            key: const Key('syncGoogleReviewsButton'),
            onPressed: _syncing ? null : _sync,
            child: Text(_syncing ? 'Syncing...' : 'Sync now'),
          ),
        ],
      ],
    );
  }
}
