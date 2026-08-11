// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'public_platform_stats.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$PublicPlatformStats extends PublicPlatformStats {
  @override
  final int totalBusinesses;
  @override
  final int totalReviews;
  @override
  final int totalCategories;
  @override
  final int totalCities;

  factory _$PublicPlatformStats(
          [void Function(PublicPlatformStatsBuilder)? updates]) =>
      (PublicPlatformStatsBuilder()..update(updates))._build();

  _$PublicPlatformStats._(
      {required this.totalBusinesses,
      required this.totalReviews,
      required this.totalCategories,
      required this.totalCities})
      : super._();
  @override
  PublicPlatformStats rebuild(
          void Function(PublicPlatformStatsBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PublicPlatformStatsBuilder toBuilder() =>
      PublicPlatformStatsBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PublicPlatformStats &&
        totalBusinesses == other.totalBusinesses &&
        totalReviews == other.totalReviews &&
        totalCategories == other.totalCategories &&
        totalCities == other.totalCities;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, totalBusinesses.hashCode);
    _$hash = $jc(_$hash, totalReviews.hashCode);
    _$hash = $jc(_$hash, totalCategories.hashCode);
    _$hash = $jc(_$hash, totalCities.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PublicPlatformStats')
          ..add('totalBusinesses', totalBusinesses)
          ..add('totalReviews', totalReviews)
          ..add('totalCategories', totalCategories)
          ..add('totalCities', totalCities))
        .toString();
  }
}

class PublicPlatformStatsBuilder
    implements Builder<PublicPlatformStats, PublicPlatformStatsBuilder> {
  _$PublicPlatformStats? _$v;

  int? _totalBusinesses;
  int? get totalBusinesses => _$this._totalBusinesses;
  set totalBusinesses(int? totalBusinesses) =>
      _$this._totalBusinesses = totalBusinesses;

  int? _totalReviews;
  int? get totalReviews => _$this._totalReviews;
  set totalReviews(int? totalReviews) => _$this._totalReviews = totalReviews;

  int? _totalCategories;
  int? get totalCategories => _$this._totalCategories;
  set totalCategories(int? totalCategories) =>
      _$this._totalCategories = totalCategories;

  int? _totalCities;
  int? get totalCities => _$this._totalCities;
  set totalCities(int? totalCities) => _$this._totalCities = totalCities;

  PublicPlatformStatsBuilder() {
    PublicPlatformStats._defaults(this);
  }

  PublicPlatformStatsBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _totalBusinesses = $v.totalBusinesses;
      _totalReviews = $v.totalReviews;
      _totalCategories = $v.totalCategories;
      _totalCities = $v.totalCities;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PublicPlatformStats other) {
    _$v = other as _$PublicPlatformStats;
  }

  @override
  void update(void Function(PublicPlatformStatsBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PublicPlatformStats build() => _build();

  _$PublicPlatformStats _build() {
    final _$result = _$v ??
        _$PublicPlatformStats._(
          totalBusinesses: BuiltValueNullFieldError.checkNotNull(
              totalBusinesses, r'PublicPlatformStats', 'totalBusinesses'),
          totalReviews: BuiltValueNullFieldError.checkNotNull(
              totalReviews, r'PublicPlatformStats', 'totalReviews'),
          totalCategories: BuiltValueNullFieldError.checkNotNull(
              totalCategories, r'PublicPlatformStats', 'totalCategories'),
          totalCities: BuiltValueNullFieldError.checkNotNull(
              totalCities, r'PublicPlatformStats', 'totalCities'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
