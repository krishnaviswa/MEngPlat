// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'platform_analytics.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$PlatformAnalytics extends PlatformAnalytics {
  @override
  final int totalUsers;
  @override
  final int totalBusinesses;
  @override
  final int pendingBusinesses;
  @override
  final int totalReviews;
  @override
  final int reportedReviews;

  factory _$PlatformAnalytics(
          [void Function(PlatformAnalyticsBuilder)? updates]) =>
      (PlatformAnalyticsBuilder()..update(updates))._build();

  _$PlatformAnalytics._(
      {required this.totalUsers,
      required this.totalBusinesses,
      required this.pendingBusinesses,
      required this.totalReviews,
      required this.reportedReviews})
      : super._();
  @override
  PlatformAnalytics rebuild(void Function(PlatformAnalyticsBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PlatformAnalyticsBuilder toBuilder() =>
      PlatformAnalyticsBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PlatformAnalytics &&
        totalUsers == other.totalUsers &&
        totalBusinesses == other.totalBusinesses &&
        pendingBusinesses == other.pendingBusinesses &&
        totalReviews == other.totalReviews &&
        reportedReviews == other.reportedReviews;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, totalUsers.hashCode);
    _$hash = $jc(_$hash, totalBusinesses.hashCode);
    _$hash = $jc(_$hash, pendingBusinesses.hashCode);
    _$hash = $jc(_$hash, totalReviews.hashCode);
    _$hash = $jc(_$hash, reportedReviews.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PlatformAnalytics')
          ..add('totalUsers', totalUsers)
          ..add('totalBusinesses', totalBusinesses)
          ..add('pendingBusinesses', pendingBusinesses)
          ..add('totalReviews', totalReviews)
          ..add('reportedReviews', reportedReviews))
        .toString();
  }
}

class PlatformAnalyticsBuilder
    implements Builder<PlatformAnalytics, PlatformAnalyticsBuilder> {
  _$PlatformAnalytics? _$v;

  int? _totalUsers;
  int? get totalUsers => _$this._totalUsers;
  set totalUsers(int? totalUsers) => _$this._totalUsers = totalUsers;

  int? _totalBusinesses;
  int? get totalBusinesses => _$this._totalBusinesses;
  set totalBusinesses(int? totalBusinesses) =>
      _$this._totalBusinesses = totalBusinesses;

  int? _pendingBusinesses;
  int? get pendingBusinesses => _$this._pendingBusinesses;
  set pendingBusinesses(int? pendingBusinesses) =>
      _$this._pendingBusinesses = pendingBusinesses;

  int? _totalReviews;
  int? get totalReviews => _$this._totalReviews;
  set totalReviews(int? totalReviews) => _$this._totalReviews = totalReviews;

  int? _reportedReviews;
  int? get reportedReviews => _$this._reportedReviews;
  set reportedReviews(int? reportedReviews) =>
      _$this._reportedReviews = reportedReviews;

  PlatformAnalyticsBuilder() {
    PlatformAnalytics._defaults(this);
  }

  PlatformAnalyticsBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _totalUsers = $v.totalUsers;
      _totalBusinesses = $v.totalBusinesses;
      _pendingBusinesses = $v.pendingBusinesses;
      _totalReviews = $v.totalReviews;
      _reportedReviews = $v.reportedReviews;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PlatformAnalytics other) {
    _$v = other as _$PlatformAnalytics;
  }

  @override
  void update(void Function(PlatformAnalyticsBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PlatformAnalytics build() => _build();

  _$PlatformAnalytics _build() {
    final _$result = _$v ??
        _$PlatformAnalytics._(
          totalUsers: BuiltValueNullFieldError.checkNotNull(
              totalUsers, r'PlatformAnalytics', 'totalUsers'),
          totalBusinesses: BuiltValueNullFieldError.checkNotNull(
              totalBusinesses, r'PlatformAnalytics', 'totalBusinesses'),
          pendingBusinesses: BuiltValueNullFieldError.checkNotNull(
              pendingBusinesses, r'PlatformAnalytics', 'pendingBusinesses'),
          totalReviews: BuiltValueNullFieldError.checkNotNull(
              totalReviews, r'PlatformAnalytics', 'totalReviews'),
          reportedReviews: BuiltValueNullFieldError.checkNotNull(
              reportedReviews, r'PlatformAnalytics', 'reportedReviews'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
