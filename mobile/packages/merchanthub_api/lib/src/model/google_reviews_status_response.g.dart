// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'google_reviews_status_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$GoogleReviewsStatusResponse extends GoogleReviewsStatusResponse {
  @override
  final bool linked;
  @override
  final String? placeId;
  @override
  final int reviewCount;
  @override
  final DateTime? lastSyncedAt;

  factory _$GoogleReviewsStatusResponse(
          [void Function(GoogleReviewsStatusResponseBuilder)? updates]) =>
      (GoogleReviewsStatusResponseBuilder()..update(updates))._build();

  _$GoogleReviewsStatusResponse._(
      {required this.linked,
      this.placeId,
      required this.reviewCount,
      this.lastSyncedAt})
      : super._();
  @override
  GoogleReviewsStatusResponse rebuild(
          void Function(GoogleReviewsStatusResponseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  GoogleReviewsStatusResponseBuilder toBuilder() =>
      GoogleReviewsStatusResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is GoogleReviewsStatusResponse &&
        linked == other.linked &&
        placeId == other.placeId &&
        reviewCount == other.reviewCount &&
        lastSyncedAt == other.lastSyncedAt;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, linked.hashCode);
    _$hash = $jc(_$hash, placeId.hashCode);
    _$hash = $jc(_$hash, reviewCount.hashCode);
    _$hash = $jc(_$hash, lastSyncedAt.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'GoogleReviewsStatusResponse')
          ..add('linked', linked)
          ..add('placeId', placeId)
          ..add('reviewCount', reviewCount)
          ..add('lastSyncedAt', lastSyncedAt))
        .toString();
  }
}

class GoogleReviewsStatusResponseBuilder
    implements
        Builder<GoogleReviewsStatusResponse,
            GoogleReviewsStatusResponseBuilder> {
  _$GoogleReviewsStatusResponse? _$v;

  bool? _linked;
  bool? get linked => _$this._linked;
  set linked(bool? linked) => _$this._linked = linked;

  String? _placeId;
  String? get placeId => _$this._placeId;
  set placeId(String? placeId) => _$this._placeId = placeId;

  int? _reviewCount;
  int? get reviewCount => _$this._reviewCount;
  set reviewCount(int? reviewCount) => _$this._reviewCount = reviewCount;

  DateTime? _lastSyncedAt;
  DateTime? get lastSyncedAt => _$this._lastSyncedAt;
  set lastSyncedAt(DateTime? lastSyncedAt) =>
      _$this._lastSyncedAt = lastSyncedAt;

  GoogleReviewsStatusResponseBuilder() {
    GoogleReviewsStatusResponse._defaults(this);
  }

  GoogleReviewsStatusResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _linked = $v.linked;
      _placeId = $v.placeId;
      _reviewCount = $v.reviewCount;
      _lastSyncedAt = $v.lastSyncedAt;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(GoogleReviewsStatusResponse other) {
    _$v = other as _$GoogleReviewsStatusResponse;
  }

  @override
  void update(void Function(GoogleReviewsStatusResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  GoogleReviewsStatusResponse build() => _build();

  _$GoogleReviewsStatusResponse _build() {
    final _$result = _$v ??
        _$GoogleReviewsStatusResponse._(
          linked: BuiltValueNullFieldError.checkNotNull(
              linked, r'GoogleReviewsStatusResponse', 'linked'),
          placeId: placeId,
          reviewCount: BuiltValueNullFieldError.checkNotNull(
              reviewCount, r'GoogleReviewsStatusResponse', 'reviewCount'),
          lastSyncedAt: lastSyncedAt,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
