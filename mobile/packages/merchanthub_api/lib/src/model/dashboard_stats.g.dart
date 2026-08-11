// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard_stats.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$DashboardStats extends DashboardStats {
  @override
  final int totalReviews;
  @override
  final num averageRating;
  @override
  final BuiltMap<String, int> sentimentBreakdown;
  @override
  final BuiltList<ReviewResponse> recentReviews;
  @override
  final BuiltList<JsonObject> reviewVolumeByMonth;

  factory _$DashboardStats([void Function(DashboardStatsBuilder)? updates]) =>
      (DashboardStatsBuilder()..update(updates))._build();

  _$DashboardStats._(
      {required this.totalReviews,
      required this.averageRating,
      required this.sentimentBreakdown,
      required this.recentReviews,
      required this.reviewVolumeByMonth})
      : super._();
  @override
  DashboardStats rebuild(void Function(DashboardStatsBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  DashboardStatsBuilder toBuilder() => DashboardStatsBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is DashboardStats &&
        totalReviews == other.totalReviews &&
        averageRating == other.averageRating &&
        sentimentBreakdown == other.sentimentBreakdown &&
        recentReviews == other.recentReviews &&
        reviewVolumeByMonth == other.reviewVolumeByMonth;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, totalReviews.hashCode);
    _$hash = $jc(_$hash, averageRating.hashCode);
    _$hash = $jc(_$hash, sentimentBreakdown.hashCode);
    _$hash = $jc(_$hash, recentReviews.hashCode);
    _$hash = $jc(_$hash, reviewVolumeByMonth.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'DashboardStats')
          ..add('totalReviews', totalReviews)
          ..add('averageRating', averageRating)
          ..add('sentimentBreakdown', sentimentBreakdown)
          ..add('recentReviews', recentReviews)
          ..add('reviewVolumeByMonth', reviewVolumeByMonth))
        .toString();
  }
}

class DashboardStatsBuilder
    implements Builder<DashboardStats, DashboardStatsBuilder> {
  _$DashboardStats? _$v;

  int? _totalReviews;
  int? get totalReviews => _$this._totalReviews;
  set totalReviews(int? totalReviews) => _$this._totalReviews = totalReviews;

  num? _averageRating;
  num? get averageRating => _$this._averageRating;
  set averageRating(num? averageRating) =>
      _$this._averageRating = averageRating;

  MapBuilder<String, int>? _sentimentBreakdown;
  MapBuilder<String, int> get sentimentBreakdown =>
      _$this._sentimentBreakdown ??= MapBuilder<String, int>();
  set sentimentBreakdown(MapBuilder<String, int>? sentimentBreakdown) =>
      _$this._sentimentBreakdown = sentimentBreakdown;

  ListBuilder<ReviewResponse>? _recentReviews;
  ListBuilder<ReviewResponse> get recentReviews =>
      _$this._recentReviews ??= ListBuilder<ReviewResponse>();
  set recentReviews(ListBuilder<ReviewResponse>? recentReviews) =>
      _$this._recentReviews = recentReviews;

  ListBuilder<JsonObject>? _reviewVolumeByMonth;
  ListBuilder<JsonObject> get reviewVolumeByMonth =>
      _$this._reviewVolumeByMonth ??= ListBuilder<JsonObject>();
  set reviewVolumeByMonth(ListBuilder<JsonObject>? reviewVolumeByMonth) =>
      _$this._reviewVolumeByMonth = reviewVolumeByMonth;

  DashboardStatsBuilder() {
    DashboardStats._defaults(this);
  }

  DashboardStatsBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _totalReviews = $v.totalReviews;
      _averageRating = $v.averageRating;
      _sentimentBreakdown = $v.sentimentBreakdown.toBuilder();
      _recentReviews = $v.recentReviews.toBuilder();
      _reviewVolumeByMonth = $v.reviewVolumeByMonth.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(DashboardStats other) {
    _$v = other as _$DashboardStats;
  }

  @override
  void update(void Function(DashboardStatsBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  DashboardStats build() => _build();

  _$DashboardStats _build() {
    _$DashboardStats _$result;
    try {
      _$result = _$v ??
          _$DashboardStats._(
            totalReviews: BuiltValueNullFieldError.checkNotNull(
                totalReviews, r'DashboardStats', 'totalReviews'),
            averageRating: BuiltValueNullFieldError.checkNotNull(
                averageRating, r'DashboardStats', 'averageRating'),
            sentimentBreakdown: sentimentBreakdown.build(),
            recentReviews: recentReviews.build(),
            reviewVolumeByMonth: reviewVolumeByMonth.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'sentimentBreakdown';
        sentimentBreakdown.build();
        _$failedField = 'recentReviews';
        recentReviews.build();
        _$failedField = 'reviewVolumeByMonth';
        reviewVolumeByMonth.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'DashboardStats', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
