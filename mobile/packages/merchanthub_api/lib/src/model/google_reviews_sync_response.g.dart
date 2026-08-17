// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'google_reviews_sync_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$GoogleReviewsSyncResponse extends GoogleReviewsSyncResponse {
  @override
  final int syncedCount;
  @override
  final DateTime lastSyncedAt;
  @override
  final bool debounced;

  factory _$GoogleReviewsSyncResponse(
          [void Function(GoogleReviewsSyncResponseBuilder)? updates]) =>
      (GoogleReviewsSyncResponseBuilder()..update(updates))._build();

  _$GoogleReviewsSyncResponse._(
      {required this.syncedCount,
      required this.lastSyncedAt,
      required this.debounced})
      : super._();
  @override
  GoogleReviewsSyncResponse rebuild(
          void Function(GoogleReviewsSyncResponseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  GoogleReviewsSyncResponseBuilder toBuilder() =>
      GoogleReviewsSyncResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is GoogleReviewsSyncResponse &&
        syncedCount == other.syncedCount &&
        lastSyncedAt == other.lastSyncedAt &&
        debounced == other.debounced;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, syncedCount.hashCode);
    _$hash = $jc(_$hash, lastSyncedAt.hashCode);
    _$hash = $jc(_$hash, debounced.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'GoogleReviewsSyncResponse')
          ..add('syncedCount', syncedCount)
          ..add('lastSyncedAt', lastSyncedAt)
          ..add('debounced', debounced))
        .toString();
  }
}

class GoogleReviewsSyncResponseBuilder
    implements
        Builder<GoogleReviewsSyncResponse, GoogleReviewsSyncResponseBuilder> {
  _$GoogleReviewsSyncResponse? _$v;

  int? _syncedCount;
  int? get syncedCount => _$this._syncedCount;
  set syncedCount(int? syncedCount) => _$this._syncedCount = syncedCount;

  DateTime? _lastSyncedAt;
  DateTime? get lastSyncedAt => _$this._lastSyncedAt;
  set lastSyncedAt(DateTime? lastSyncedAt) =>
      _$this._lastSyncedAt = lastSyncedAt;

  bool? _debounced;
  bool? get debounced => _$this._debounced;
  set debounced(bool? debounced) => _$this._debounced = debounced;

  GoogleReviewsSyncResponseBuilder() {
    GoogleReviewsSyncResponse._defaults(this);
  }

  GoogleReviewsSyncResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _syncedCount = $v.syncedCount;
      _lastSyncedAt = $v.lastSyncedAt;
      _debounced = $v.debounced;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(GoogleReviewsSyncResponse other) {
    _$v = other as _$GoogleReviewsSyncResponse;
  }

  @override
  void update(void Function(GoogleReviewsSyncResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  GoogleReviewsSyncResponse build() => _build();

  _$GoogleReviewsSyncResponse _build() {
    final _$result = _$v ??
        _$GoogleReviewsSyncResponse._(
          syncedCount: BuiltValueNullFieldError.checkNotNull(
              syncedCount, r'GoogleReviewsSyncResponse', 'syncedCount'),
          lastSyncedAt: BuiltValueNullFieldError.checkNotNull(
              lastSyncedAt, r'GoogleReviewsSyncResponse', 'lastSyncedAt'),
          debounced: BuiltValueNullFieldError.checkNotNull(
              debounced, r'GoogleReviewsSyncResponse', 'debounced'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
