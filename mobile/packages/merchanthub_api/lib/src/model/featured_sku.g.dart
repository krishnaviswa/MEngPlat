// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'featured_sku.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$FeaturedSku extends FeaturedSku {
  @override
  final String code;
  @override
  final int durationDays;
  @override
  final int listedPriceInr;
  @override
  final int? amountPaise;

  factory _$FeaturedSku([void Function(FeaturedSkuBuilder)? updates]) =>
      (FeaturedSkuBuilder()..update(updates))._build();

  _$FeaturedSku._(
      {required this.code,
      required this.durationDays,
      required this.listedPriceInr,
      this.amountPaise})
      : super._();
  @override
  FeaturedSku rebuild(void Function(FeaturedSkuBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  FeaturedSkuBuilder toBuilder() => FeaturedSkuBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is FeaturedSku &&
        code == other.code &&
        durationDays == other.durationDays &&
        listedPriceInr == other.listedPriceInr &&
        amountPaise == other.amountPaise;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, code.hashCode);
    _$hash = $jc(_$hash, durationDays.hashCode);
    _$hash = $jc(_$hash, listedPriceInr.hashCode);
    _$hash = $jc(_$hash, amountPaise.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'FeaturedSku')
          ..add('code', code)
          ..add('durationDays', durationDays)
          ..add('listedPriceInr', listedPriceInr)
          ..add('amountPaise', amountPaise))
        .toString();
  }
}

class FeaturedSkuBuilder implements Builder<FeaturedSku, FeaturedSkuBuilder> {
  _$FeaturedSku? _$v;

  String? _code;
  String? get code => _$this._code;
  set code(String? code) => _$this._code = code;

  int? _durationDays;
  int? get durationDays => _$this._durationDays;
  set durationDays(int? durationDays) => _$this._durationDays = durationDays;

  int? _listedPriceInr;
  int? get listedPriceInr => _$this._listedPriceInr;
  set listedPriceInr(int? listedPriceInr) =>
      _$this._listedPriceInr = listedPriceInr;

  int? _amountPaise;
  int? get amountPaise => _$this._amountPaise;
  set amountPaise(int? amountPaise) => _$this._amountPaise = amountPaise;

  FeaturedSkuBuilder() {
    FeaturedSku._defaults(this);
  }

  FeaturedSkuBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _code = $v.code;
      _durationDays = $v.durationDays;
      _listedPriceInr = $v.listedPriceInr;
      _amountPaise = $v.amountPaise;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(FeaturedSku other) {
    _$v = other as _$FeaturedSku;
  }

  @override
  void update(void Function(FeaturedSkuBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  FeaturedSku build() => _build();

  _$FeaturedSku _build() {
    final _$result = _$v ??
        _$FeaturedSku._(
          code: BuiltValueNullFieldError.checkNotNull(
              code, r'FeaturedSku', 'code'),
          durationDays: BuiltValueNullFieldError.checkNotNull(
              durationDays, r'FeaturedSku', 'durationDays'),
          listedPriceInr: BuiltValueNullFieldError.checkNotNull(
              listedPriceInr, r'FeaturedSku', 'listedPriceInr'),
          amountPaise: amountPaise,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
