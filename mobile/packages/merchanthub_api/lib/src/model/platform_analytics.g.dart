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
  @override
  final int? openSupportTickets;
  @override
  final int? repeatShopReports;
  @override
  final int? processingBusinesses;

  factory _$PlatformAnalytics(
          [void Function(PlatformAnalyticsBuilder)? updates]) =>
      (PlatformAnalyticsBuilder()..update(updates))._build();

  _$PlatformAnalytics._(
      {required this.totalUsers,
      required this.totalBusinesses,
      required this.pendingBusinesses,
      required this.totalReviews,
      required this.reportedReviews,
      this.openSupportTickets,
      this.repeatShopReports,
      this.processingBusinesses})
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
        reportedReviews == other.reportedReviews &&
        openSupportTickets == other.openSupportTickets &&
        repeatShopReports == other.repeatShopReports &&
        processingBusinesses == other.processingBusinesses;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, totalUsers.hashCode);
    _$hash = $jc(_$hash, totalBusinesses.hashCode);
    _$hash = $jc(_$hash, pendingBusinesses.hashCode);
    _$hash = $jc(_$hash, totalReviews.hashCode);
    _$hash = $jc(_$hash, reportedReviews.hashCode);
    _$hash = $jc(_$hash, openSupportTickets.hashCode);
    _$hash = $jc(_$hash, repeatShopReports.hashCode);
    _$hash = $jc(_$hash, processingBusinesses.hashCode);
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
          ..add('reportedReviews', reportedReviews)
          ..add('openSupportTickets', openSupportTickets)
          ..add('repeatShopReports', repeatShopReports)
          ..add('processingBusinesses', processingBusinesses))
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

  int? _openSupportTickets;
  int? get openSupportTickets => _$this._openSupportTickets;
  set openSupportTickets(int? openSupportTickets) =>
      _$this._openSupportTickets = openSupportTickets;

  int? _repeatShopReports;
  int? get repeatShopReports => _$this._repeatShopReports;
  set repeatShopReports(int? repeatShopReports) =>
      _$this._repeatShopReports = repeatShopReports;

  int? _processingBusinesses;
  int? get processingBusinesses => _$this._processingBusinesses;
  set processingBusinesses(int? processingBusinesses) =>
      _$this._processingBusinesses = processingBusinesses;

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
      _openSupportTickets = $v.openSupportTickets;
      _repeatShopReports = $v.repeatShopReports;
      _processingBusinesses = $v.processingBusinesses;
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
          openSupportTickets: openSupportTickets,
          repeatShopReports: repeatShopReports,
          processingBusinesses: processingBusinesses,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
