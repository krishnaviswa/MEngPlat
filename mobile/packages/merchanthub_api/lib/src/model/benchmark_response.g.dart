// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'benchmark_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$BenchmarkResponse extends BenchmarkResponse {
  @override
  final String businessId;
  @override
  final num ownRating;
  @override
  final num? categoryMedian;
  @override
  final num? cityMedian;
  @override
  final int categorySampleSize;
  @override
  final int citySampleSize;
  @override
  final String disclaimer;

  factory _$BenchmarkResponse(
          [void Function(BenchmarkResponseBuilder)? updates]) =>
      (BenchmarkResponseBuilder()..update(updates))._build();

  _$BenchmarkResponse._(
      {required this.businessId,
      required this.ownRating,
      this.categoryMedian,
      this.cityMedian,
      required this.categorySampleSize,
      required this.citySampleSize,
      required this.disclaimer})
      : super._();
  @override
  BenchmarkResponse rebuild(void Function(BenchmarkResponseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  BenchmarkResponseBuilder toBuilder() =>
      BenchmarkResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is BenchmarkResponse &&
        businessId == other.businessId &&
        ownRating == other.ownRating &&
        categoryMedian == other.categoryMedian &&
        cityMedian == other.cityMedian &&
        categorySampleSize == other.categorySampleSize &&
        citySampleSize == other.citySampleSize &&
        disclaimer == other.disclaimer;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, businessId.hashCode);
    _$hash = $jc(_$hash, ownRating.hashCode);
    _$hash = $jc(_$hash, categoryMedian.hashCode);
    _$hash = $jc(_$hash, cityMedian.hashCode);
    _$hash = $jc(_$hash, categorySampleSize.hashCode);
    _$hash = $jc(_$hash, citySampleSize.hashCode);
    _$hash = $jc(_$hash, disclaimer.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'BenchmarkResponse')
          ..add('businessId', businessId)
          ..add('ownRating', ownRating)
          ..add('categoryMedian', categoryMedian)
          ..add('cityMedian', cityMedian)
          ..add('categorySampleSize', categorySampleSize)
          ..add('citySampleSize', citySampleSize)
          ..add('disclaimer', disclaimer))
        .toString();
  }
}

class BenchmarkResponseBuilder
    implements Builder<BenchmarkResponse, BenchmarkResponseBuilder> {
  _$BenchmarkResponse? _$v;

  String? _businessId;
  String? get businessId => _$this._businessId;
  set businessId(String? businessId) => _$this._businessId = businessId;

  num? _ownRating;
  num? get ownRating => _$this._ownRating;
  set ownRating(num? ownRating) => _$this._ownRating = ownRating;

  num? _categoryMedian;
  num? get categoryMedian => _$this._categoryMedian;
  set categoryMedian(num? categoryMedian) =>
      _$this._categoryMedian = categoryMedian;

  num? _cityMedian;
  num? get cityMedian => _$this._cityMedian;
  set cityMedian(num? cityMedian) => _$this._cityMedian = cityMedian;

  int? _categorySampleSize;
  int? get categorySampleSize => _$this._categorySampleSize;
  set categorySampleSize(int? categorySampleSize) =>
      _$this._categorySampleSize = categorySampleSize;

  int? _citySampleSize;
  int? get citySampleSize => _$this._citySampleSize;
  set citySampleSize(int? citySampleSize) =>
      _$this._citySampleSize = citySampleSize;

  String? _disclaimer;
  String? get disclaimer => _$this._disclaimer;
  set disclaimer(String? disclaimer) => _$this._disclaimer = disclaimer;

  BenchmarkResponseBuilder() {
    BenchmarkResponse._defaults(this);
  }

  BenchmarkResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _businessId = $v.businessId;
      _ownRating = $v.ownRating;
      _categoryMedian = $v.categoryMedian;
      _cityMedian = $v.cityMedian;
      _categorySampleSize = $v.categorySampleSize;
      _citySampleSize = $v.citySampleSize;
      _disclaimer = $v.disclaimer;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(BenchmarkResponse other) {
    _$v = other as _$BenchmarkResponse;
  }

  @override
  void update(void Function(BenchmarkResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  BenchmarkResponse build() => _build();

  _$BenchmarkResponse _build() {
    final _$result = _$v ??
        _$BenchmarkResponse._(
          businessId: BuiltValueNullFieldError.checkNotNull(
              businessId, r'BenchmarkResponse', 'businessId'),
          ownRating: BuiltValueNullFieldError.checkNotNull(
              ownRating, r'BenchmarkResponse', 'ownRating'),
          categoryMedian: categoryMedian,
          cityMedian: cityMedian,
          categorySampleSize: BuiltValueNullFieldError.checkNotNull(
              categorySampleSize, r'BenchmarkResponse', 'categorySampleSize'),
          citySampleSize: BuiltValueNullFieldError.checkNotNull(
              citySampleSize, r'BenchmarkResponse', 'citySampleSize'),
          disclaimer: BuiltValueNullFieldError.checkNotNull(
              disclaimer, r'BenchmarkResponse', 'disclaimer'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
