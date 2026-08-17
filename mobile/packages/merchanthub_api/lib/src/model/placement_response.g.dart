// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'placement_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$PlacementResponse extends PlacementResponse {
  @override
  final String businessId;
  @override
  final bool active;
  @override
  final PlacementWindow? placement;
  @override
  final FeaturedSku sku;
  @override
  final BuiltList<FeaturedSku>? skus;
  @override
  final bool? awaitingApproval;
  @override
  final PaymentLedger? payment;

  factory _$PlacementResponse(
          [void Function(PlacementResponseBuilder)? updates]) =>
      (PlacementResponseBuilder()..update(updates))._build();

  _$PlacementResponse._(
      {required this.businessId,
      required this.active,
      this.placement,
      required this.sku,
      this.skus,
      this.awaitingApproval,
      this.payment})
      : super._();
  @override
  PlacementResponse rebuild(void Function(PlacementResponseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PlacementResponseBuilder toBuilder() =>
      PlacementResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PlacementResponse &&
        businessId == other.businessId &&
        active == other.active &&
        placement == other.placement &&
        sku == other.sku &&
        skus == other.skus &&
        awaitingApproval == other.awaitingApproval &&
        payment == other.payment;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, businessId.hashCode);
    _$hash = $jc(_$hash, active.hashCode);
    _$hash = $jc(_$hash, placement.hashCode);
    _$hash = $jc(_$hash, sku.hashCode);
    _$hash = $jc(_$hash, skus.hashCode);
    _$hash = $jc(_$hash, awaitingApproval.hashCode);
    _$hash = $jc(_$hash, payment.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PlacementResponse')
          ..add('businessId', businessId)
          ..add('active', active)
          ..add('placement', placement)
          ..add('sku', sku)
          ..add('skus', skus)
          ..add('awaitingApproval', awaitingApproval)
          ..add('payment', payment))
        .toString();
  }
}

class PlacementResponseBuilder
    implements Builder<PlacementResponse, PlacementResponseBuilder> {
  _$PlacementResponse? _$v;

  String? _businessId;
  String? get businessId => _$this._businessId;
  set businessId(String? businessId) => _$this._businessId = businessId;

  bool? _active;
  bool? get active => _$this._active;
  set active(bool? active) => _$this._active = active;

  PlacementWindowBuilder? _placement;
  PlacementWindowBuilder get placement =>
      _$this._placement ??= PlacementWindowBuilder();
  set placement(PlacementWindowBuilder? placement) =>
      _$this._placement = placement;

  FeaturedSkuBuilder? _sku;
  FeaturedSkuBuilder get sku => _$this._sku ??= FeaturedSkuBuilder();
  set sku(FeaturedSkuBuilder? sku) => _$this._sku = sku;

  ListBuilder<FeaturedSku>? _skus;
  ListBuilder<FeaturedSku> get skus =>
      _$this._skus ??= ListBuilder<FeaturedSku>();
  set skus(ListBuilder<FeaturedSku>? skus) => _$this._skus = skus;

  bool? _awaitingApproval;
  bool? get awaitingApproval => _$this._awaitingApproval;
  set awaitingApproval(bool? awaitingApproval) =>
      _$this._awaitingApproval = awaitingApproval;

  PaymentLedgerBuilder? _payment;
  PaymentLedgerBuilder get payment =>
      _$this._payment ??= PaymentLedgerBuilder();
  set payment(PaymentLedgerBuilder? payment) => _$this._payment = payment;

  PlacementResponseBuilder() {
    PlacementResponse._defaults(this);
  }

  PlacementResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _businessId = $v.businessId;
      _active = $v.active;
      _placement = $v.placement?.toBuilder();
      _sku = $v.sku.toBuilder();
      _skus = $v.skus?.toBuilder();
      _awaitingApproval = $v.awaitingApproval;
      _payment = $v.payment?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PlacementResponse other) {
    _$v = other as _$PlacementResponse;
  }

  @override
  void update(void Function(PlacementResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PlacementResponse build() => _build();

  _$PlacementResponse _build() {
    _$PlacementResponse _$result;
    try {
      _$result = _$v ??
          _$PlacementResponse._(
            businessId: BuiltValueNullFieldError.checkNotNull(
                businessId, r'PlacementResponse', 'businessId'),
            active: BuiltValueNullFieldError.checkNotNull(
                active, r'PlacementResponse', 'active'),
            placement: _placement?.build(),
            sku: sku.build(),
            skus: _skus?.build(),
            awaitingApproval: awaitingApproval,
            payment: _payment?.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'placement';
        _placement?.build();
        _$failedField = 'sku';
        sku.build();
        _$failedField = 'skus';
        _skus?.build();

        _$failedField = 'payment';
        _payment?.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'PlacementResponse', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
