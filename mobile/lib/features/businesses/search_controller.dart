import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:merchanthub_api/merchanthub_api.dart';

import 'business_list_provider.dart';
import 'search_query.dart';

class SearchResults {
  const SearchResults({
    required this.query,
    required this.items,
    required this.page,
    required this.hasMore,
    this.isLoadingMore = false,
  });

  final SearchQuery query;
  final List<BusinessResponse> items;
  final int page;
  final bool hasMore;
  final bool isLoadingMore;

  SearchResults copyWith({
    SearchQuery? query,
    List<BusinessResponse>? items,
    int? page,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return SearchResults(
      query: query ?? this.query,
      items: items ?? this.items,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

class SearchController extends AutoDisposeAsyncNotifier<SearchResults> {
  static const _debounce = Duration(milliseconds: 400);

  Timer? _debounceTimer;

  @override
  Future<SearchResults> build() async {
    ref.onDispose(() => _debounceTimer?.cancel());
    return _fetch(const SearchQuery());
  }

  Future<SearchResults> _fetch(SearchQuery query, {int page = 1}) async {
    final items = await ref.read(businessRepositoryProvider).searchBusinesses(query: query, page: page);
    return SearchResults(
      query: query,
      items: items,
      page: page,
      hasMore: items.length >= SearchQuery.pageSize,
    );
  }

  Future<void> applyQuery(SearchQuery query) async {
    _debounceTimer?.cancel();
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch(query));
  }

  /// Debounced `q` updates (AC1/AC2). Other filters go through [applyQuery].
  void setQueryText(String raw) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounce, () {
      final q = raw.trim().isEmpty ? null : raw.trim();
      final current = state.valueOrNull?.query ?? const SearchQuery();
      if (current.q == q) return;
      applyQuery(current.copyWith(q: q, clearQuery: q == null));
    });
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || current.isLoadingMore || state.isLoading) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));
    try {
      final nextPage = current.page + 1;
      final more = await ref.read(businessRepositoryProvider).searchBusinesses(
            query: current.query,
            page: nextPage,
          );
      state = AsyncData(
        SearchResults(
          query: current.query,
          items: [...current.items, ...more],
          page: nextPage,
          hasMore: more.length >= SearchQuery.pageSize,
        ),
      );
    } catch (_) {
      state = AsyncData(current.copyWith(isLoadingMore: false));
    }
  }

  Future<void> reload() async {
    final query = state.valueOrNull?.query ?? const SearchQuery();
    state = await AsyncValue.guard(() => _fetch(query));
  }
}

final searchControllerProvider = AsyncNotifierProvider.autoDispose<SearchController, SearchResults>(
  SearchController.new,
);
