// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'featured_checkout_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$FeaturedCheckoutRequest extends FeaturedCheckoutRequest {
  @override
  final String businessId;
  @override
  final String skuCode;

  factory _$FeaturedCheckoutRequest(
          [void Function(FeaturedCheckoutRequestBuilder)? updates]) =>
      (FeaturedCheckoutRequestBuilder()..update(updates))._build();

  _$FeaturedCheckoutRequest._({required this.businessId, required this.skuCode})
      : super._();
  @override
  FeaturedCheckoutRequest rebuild(
          void Function(FeaturedCheckoutRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  FeaturedCheckoutRequestBuilder toBuilder() =>
      FeaturedCheckoutRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is FeaturedCheckoutRequest &&
        businessId == other.businessId &&
        skuCode == other.skuCode;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, businessId.hashCode);
    _$hash = $jc(_$hash, skuCode.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'FeaturedCheckoutRequest')
          ..add('businessId', businessId)
          ..add('skuCode', skuCode))
        .toString();
  }
}

class FeaturedCheckoutRequestBuilder
    implements
        Builder<FeaturedCheckoutRequest, FeaturedCheckoutRequestBuilder> {
  _$FeaturedCheckoutRequest? _$v;

  String? _businessId;
  String? get businessId => _$this._businessId;
  set businessId(String? businessId) => _$this._businessId = businessId;

  String? _skuCode;
  String? get skuCode => _$this._skuCode;
  set skuCode(String? skuCode) => _$this._skuCode = skuCode;

  FeaturedCheckoutRequestBuilder() {
    FeaturedCheckoutRequest._defaults(this);
  }

  FeaturedCheckoutRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _businessId = $v.businessId;
      _skuCode = $v.skuCode;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(FeaturedCheckoutRequest other) {
    _$v = other as _$FeaturedCheckoutRequest;
  }

  @override
  void update(void Function(FeaturedCheckoutRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  FeaturedCheckoutRequest build() => _build();

  _$FeaturedCheckoutRequest _build() {
    final _$result = _$v ??
        _$FeaturedCheckoutRequest._(
          businessId: BuiltValueNullFieldError.checkNotNull(
              businessId, r'FeaturedCheckoutRequest', 'businessId'),
          skuCode: BuiltValueNullFieldError.checkNotNull(
              skuCode, r'FeaturedCheckoutRequest', 'skuCode'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
