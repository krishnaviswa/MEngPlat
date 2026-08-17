// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'featured_checkout_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$FeaturedCheckoutResponse extends FeaturedCheckoutResponse {
  @override
  final String paymentId;
  @override
  final String provider;
  @override
  final String providerOrderId;
  @override
  final int amountPaise;
  @override
  final String currency;
  @override
  final FeaturedSku sku;
  @override
  final CheckoutFields checkout;

  factory _$FeaturedCheckoutResponse(
          [void Function(FeaturedCheckoutResponseBuilder)? updates]) =>
      (FeaturedCheckoutResponseBuilder()..update(updates))._build();

  _$FeaturedCheckoutResponse._(
      {required this.paymentId,
      required this.provider,
      required this.providerOrderId,
      required this.amountPaise,
      required this.currency,
      required this.sku,
      required this.checkout})
      : super._();
  @override
  FeaturedCheckoutResponse rebuild(
          void Function(FeaturedCheckoutResponseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  FeaturedCheckoutResponseBuilder toBuilder() =>
      FeaturedCheckoutResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is FeaturedCheckoutResponse &&
        paymentId == other.paymentId &&
        provider == other.provider &&
        providerOrderId == other.providerOrderId &&
        amountPaise == other.amountPaise &&
        currency == other.currency &&
        sku == other.sku &&
        checkout == other.checkout;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, paymentId.hashCode);
    _$hash = $jc(_$hash, provider.hashCode);
    _$hash = $jc(_$hash, providerOrderId.hashCode);
    _$hash = $jc(_$hash, amountPaise.hashCode);
    _$hash = $jc(_$hash, currency.hashCode);
    _$hash = $jc(_$hash, sku.hashCode);
    _$hash = $jc(_$hash, checkout.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'FeaturedCheckoutResponse')
          ..add('paymentId', paymentId)
          ..add('provider', provider)
          ..add('providerOrderId', providerOrderId)
          ..add('amountPaise', amountPaise)
          ..add('currency', currency)
          ..add('sku', sku)
          ..add('checkout', checkout))
        .toString();
  }
}

class FeaturedCheckoutResponseBuilder
    implements
        Builder<FeaturedCheckoutResponse, FeaturedCheckoutResponseBuilder> {
  _$FeaturedCheckoutResponse? _$v;

  String? _paymentId;
  String? get paymentId => _$this._paymentId;
  set paymentId(String? paymentId) => _$this._paymentId = paymentId;

  String? _provider;
  String? get provider => _$this._provider;
  set provider(String? provider) => _$this._provider = provider;

  String? _providerOrderId;
  String? get providerOrderId => _$this._providerOrderId;
  set providerOrderId(String? providerOrderId) =>
      _$this._providerOrderId = providerOrderId;

  int? _amountPaise;
  int? get amountPaise => _$this._amountPaise;
  set amountPaise(int? amountPaise) => _$this._amountPaise = amountPaise;

  String? _currency;
  String? get currency => _$this._currency;
  set currency(String? currency) => _$this._currency = currency;

  FeaturedSkuBuilder? _sku;
  FeaturedSkuBuilder get sku => _$this._sku ??= FeaturedSkuBuilder();
  set sku(FeaturedSkuBuilder? sku) => _$this._sku = sku;

  CheckoutFieldsBuilder? _checkout;
  CheckoutFieldsBuilder get checkout =>
      _$this._checkout ??= CheckoutFieldsBuilder();
  set checkout(CheckoutFieldsBuilder? checkout) => _$this._checkout = checkout;

  FeaturedCheckoutResponseBuilder() {
    FeaturedCheckoutResponse._defaults(this);
  }

  FeaturedCheckoutResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _paymentId = $v.paymentId;
      _provider = $v.provider;
      _providerOrderId = $v.providerOrderId;
      _amountPaise = $v.amountPaise;
      _currency = $v.currency;
      _sku = $v.sku.toBuilder();
      _checkout = $v.checkout.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(FeaturedCheckoutResponse other) {
    _$v = other as _$FeaturedCheckoutResponse;
  }

  @override
  void update(void Function(FeaturedCheckoutResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  FeaturedCheckoutResponse build() => _build();

  _$FeaturedCheckoutResponse _build() {
    _$FeaturedCheckoutResponse _$result;
    try {
      _$result = _$v ??
          _$FeaturedCheckoutResponse._(
            paymentId: BuiltValueNullFieldError.checkNotNull(
                paymentId, r'FeaturedCheckoutResponse', 'paymentId'),
            provider: BuiltValueNullFieldError.checkNotNull(
                provider, r'FeaturedCheckoutResponse', 'provider'),
            providerOrderId: BuiltValueNullFieldError.checkNotNull(
                providerOrderId,
                r'FeaturedCheckoutResponse',
                'providerOrderId'),
            amountPaise: BuiltValueNullFieldError.checkNotNull(
                amountPaise, r'FeaturedCheckoutResponse', 'amountPaise'),
            currency: BuiltValueNullFieldError.checkNotNull(
                currency, r'FeaturedCheckoutResponse', 'currency'),
            sku: sku.build(),
            checkout: checkout.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'sku';
        sku.build();
        _$failedField = 'checkout';
        checkout.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'FeaturedCheckoutResponse', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
