// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_ledger.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$PaymentLedger extends PaymentLedger {
  @override
  final String id;
  @override
  final String status;
  @override
  final int amountPaise;
  @override
  final String currency;
  @override
  final String? skuCode;
  @override
  final int? durationDays;
  @override
  final int? platformFeePaise;
  @override
  final int? gatewayFeePaise;
  @override
  final String provider;
  @override
  final String providerOrderId;
  @override
  final DateTime createdAt;
  @override
  final DateTime? approvedAt;
  @override
  final DateTime? rejectedAt;

  factory _$PaymentLedger([void Function(PaymentLedgerBuilder)? updates]) =>
      (PaymentLedgerBuilder()..update(updates))._build();

  _$PaymentLedger._(
      {required this.id,
      required this.status,
      required this.amountPaise,
      required this.currency,
      this.skuCode,
      this.durationDays,
      this.platformFeePaise,
      this.gatewayFeePaise,
      required this.provider,
      required this.providerOrderId,
      required this.createdAt,
      this.approvedAt,
      this.rejectedAt})
      : super._();
  @override
  PaymentLedger rebuild(void Function(PaymentLedgerBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PaymentLedgerBuilder toBuilder() => PaymentLedgerBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PaymentLedger &&
        id == other.id &&
        status == other.status &&
        amountPaise == other.amountPaise &&
        currency == other.currency &&
        skuCode == other.skuCode &&
        durationDays == other.durationDays &&
        platformFeePaise == other.platformFeePaise &&
        gatewayFeePaise == other.gatewayFeePaise &&
        provider == other.provider &&
        providerOrderId == other.providerOrderId &&
        createdAt == other.createdAt &&
        approvedAt == other.approvedAt &&
        rejectedAt == other.rejectedAt;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jc(_$hash, amountPaise.hashCode);
    _$hash = $jc(_$hash, currency.hashCode);
    _$hash = $jc(_$hash, skuCode.hashCode);
    _$hash = $jc(_$hash, durationDays.hashCode);
    _$hash = $jc(_$hash, platformFeePaise.hashCode);
    _$hash = $jc(_$hash, gatewayFeePaise.hashCode);
    _$hash = $jc(_$hash, provider.hashCode);
    _$hash = $jc(_$hash, providerOrderId.hashCode);
    _$hash = $jc(_$hash, createdAt.hashCode);
    _$hash = $jc(_$hash, approvedAt.hashCode);
    _$hash = $jc(_$hash, rejectedAt.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PaymentLedger')
          ..add('id', id)
          ..add('status', status)
          ..add('amountPaise', amountPaise)
          ..add('currency', currency)
          ..add('skuCode', skuCode)
          ..add('durationDays', durationDays)
          ..add('platformFeePaise', platformFeePaise)
          ..add('gatewayFeePaise', gatewayFeePaise)
          ..add('provider', provider)
          ..add('providerOrderId', providerOrderId)
          ..add('createdAt', createdAt)
          ..add('approvedAt', approvedAt)
          ..add('rejectedAt', rejectedAt))
        .toString();
  }
}

class PaymentLedgerBuilder
    implements Builder<PaymentLedger, PaymentLedgerBuilder> {
  _$PaymentLedger? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _status;
  String? get status => _$this._status;
  set status(String? status) => _$this._status = status;

  int? _amountPaise;
  int? get amountPaise => _$this._amountPaise;
  set amountPaise(int? amountPaise) => _$this._amountPaise = amountPaise;

  String? _currency;
  String? get currency => _$this._currency;
  set currency(String? currency) => _$this._currency = currency;

  String? _skuCode;
  String? get skuCode => _$this._skuCode;
  set skuCode(String? skuCode) => _$this._skuCode = skuCode;

  int? _durationDays;
  int? get durationDays => _$this._durationDays;
  set durationDays(int? durationDays) => _$this._durationDays = durationDays;

  int? _platformFeePaise;
  int? get platformFeePaise => _$this._platformFeePaise;
  set platformFeePaise(int? platformFeePaise) =>
      _$this._platformFeePaise = platformFeePaise;

  int? _gatewayFeePaise;
  int? get gatewayFeePaise => _$this._gatewayFeePaise;
  set gatewayFeePaise(int? gatewayFeePaise) =>
      _$this._gatewayFeePaise = gatewayFeePaise;

  String? _provider;
  String? get provider => _$this._provider;
  set provider(String? provider) => _$this._provider = provider;

  String? _providerOrderId;
  String? get providerOrderId => _$this._providerOrderId;
  set providerOrderId(String? providerOrderId) =>
      _$this._providerOrderId = providerOrderId;

  DateTime? _createdAt;
  DateTime? get createdAt => _$this._createdAt;
  set createdAt(DateTime? createdAt) => _$this._createdAt = createdAt;

  DateTime? _approvedAt;
  DateTime? get approvedAt => _$this._approvedAt;
  set approvedAt(DateTime? approvedAt) => _$this._approvedAt = approvedAt;

  DateTime? _rejectedAt;
  DateTime? get rejectedAt => _$this._rejectedAt;
  set rejectedAt(DateTime? rejectedAt) => _$this._rejectedAt = rejectedAt;

  PaymentLedgerBuilder() {
    PaymentLedger._defaults(this);
  }

  PaymentLedgerBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _status = $v.status;
      _amountPaise = $v.amountPaise;
      _currency = $v.currency;
      _skuCode = $v.skuCode;
      _durationDays = $v.durationDays;
      _platformFeePaise = $v.platformFeePaise;
      _gatewayFeePaise = $v.gatewayFeePaise;
      _provider = $v.provider;
      _providerOrderId = $v.providerOrderId;
      _createdAt = $v.createdAt;
      _approvedAt = $v.approvedAt;
      _rejectedAt = $v.rejectedAt;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PaymentLedger other) {
    _$v = other as _$PaymentLedger;
  }

  @override
  void update(void Function(PaymentLedgerBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PaymentLedger build() => _build();

  _$PaymentLedger _build() {
    final _$result = _$v ??
        _$PaymentLedger._(
          id: BuiltValueNullFieldError.checkNotNull(id, r'PaymentLedger', 'id'),
          status: BuiltValueNullFieldError.checkNotNull(
              status, r'PaymentLedger', 'status'),
          amountPaise: BuiltValueNullFieldError.checkNotNull(
              amountPaise, r'PaymentLedger', 'amountPaise'),
          currency: BuiltValueNullFieldError.checkNotNull(
              currency, r'PaymentLedger', 'currency'),
          skuCode: skuCode,
          durationDays: durationDays,
          platformFeePaise: platformFeePaise,
          gatewayFeePaise: gatewayFeePaise,
          provider: BuiltValueNullFieldError.checkNotNull(
              provider, r'PaymentLedger', 'provider'),
          providerOrderId: BuiltValueNullFieldError.checkNotNull(
              providerOrderId, r'PaymentLedger', 'providerOrderId'),
          createdAt: BuiltValueNullFieldError.checkNotNull(
              createdAt, r'PaymentLedger', 'createdAt'),
          approvedAt: approvedAt,
          rejectedAt: rejectedAt,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
