// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_payment_row.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$AdminPaymentRow extends AdminPaymentRow {
  @override
  final String id;
  @override
  final String status;
  @override
  final int amountPaise;
  @override
  final String currency;
  @override
  final String skuCode;
  @override
  final int durationDays;
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
  @override
  final int? platformFeePaise;
  @override
  final int? gatewayFeePaise;
  @override
  final String businessId;
  @override
  final String businessName;
  @override
  final String merchantUserId;
  @override
  final String merchantEmail;
  @override
  final String merchantName;
  @override
  final int merchantPaymentCount;
  @override
  final bool awaitingApproval;

  factory _$AdminPaymentRow([void Function(AdminPaymentRowBuilder)? updates]) =>
      (AdminPaymentRowBuilder()..update(updates))._build();

  _$AdminPaymentRow._(
      {required this.id,
      required this.status,
      required this.amountPaise,
      required this.currency,
      required this.skuCode,
      required this.durationDays,
      required this.provider,
      required this.providerOrderId,
      required this.createdAt,
      this.approvedAt,
      this.rejectedAt,
      this.platformFeePaise,
      this.gatewayFeePaise,
      required this.businessId,
      required this.businessName,
      required this.merchantUserId,
      required this.merchantEmail,
      required this.merchantName,
      required this.merchantPaymentCount,
      required this.awaitingApproval})
      : super._();
  @override
  AdminPaymentRow rebuild(void Function(AdminPaymentRowBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  AdminPaymentRowBuilder toBuilder() => AdminPaymentRowBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is AdminPaymentRow &&
        id == other.id &&
        status == other.status &&
        amountPaise == other.amountPaise &&
        currency == other.currency &&
        skuCode == other.skuCode &&
        durationDays == other.durationDays &&
        provider == other.provider &&
        providerOrderId == other.providerOrderId &&
        createdAt == other.createdAt &&
        approvedAt == other.approvedAt &&
        rejectedAt == other.rejectedAt &&
        platformFeePaise == other.platformFeePaise &&
        gatewayFeePaise == other.gatewayFeePaise &&
        businessId == other.businessId &&
        businessName == other.businessName &&
        merchantUserId == other.merchantUserId &&
        merchantEmail == other.merchantEmail &&
        merchantName == other.merchantName &&
        merchantPaymentCount == other.merchantPaymentCount &&
        awaitingApproval == other.awaitingApproval;
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
    _$hash = $jc(_$hash, provider.hashCode);
    _$hash = $jc(_$hash, providerOrderId.hashCode);
    _$hash = $jc(_$hash, createdAt.hashCode);
    _$hash = $jc(_$hash, approvedAt.hashCode);
    _$hash = $jc(_$hash, rejectedAt.hashCode);
    _$hash = $jc(_$hash, platformFeePaise.hashCode);
    _$hash = $jc(_$hash, gatewayFeePaise.hashCode);
    _$hash = $jc(_$hash, businessId.hashCode);
    _$hash = $jc(_$hash, businessName.hashCode);
    _$hash = $jc(_$hash, merchantUserId.hashCode);
    _$hash = $jc(_$hash, merchantEmail.hashCode);
    _$hash = $jc(_$hash, merchantName.hashCode);
    _$hash = $jc(_$hash, merchantPaymentCount.hashCode);
    _$hash = $jc(_$hash, awaitingApproval.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'AdminPaymentRow')
          ..add('id', id)
          ..add('status', status)
          ..add('amountPaise', amountPaise)
          ..add('currency', currency)
          ..add('skuCode', skuCode)
          ..add('durationDays', durationDays)
          ..add('provider', provider)
          ..add('providerOrderId', providerOrderId)
          ..add('createdAt', createdAt)
          ..add('approvedAt', approvedAt)
          ..add('rejectedAt', rejectedAt)
          ..add('platformFeePaise', platformFeePaise)
          ..add('gatewayFeePaise', gatewayFeePaise)
          ..add('businessId', businessId)
          ..add('businessName', businessName)
          ..add('merchantUserId', merchantUserId)
          ..add('merchantEmail', merchantEmail)
          ..add('merchantName', merchantName)
          ..add('merchantPaymentCount', merchantPaymentCount)
          ..add('awaitingApproval', awaitingApproval))
        .toString();
  }
}

class AdminPaymentRowBuilder
    implements Builder<AdminPaymentRow, AdminPaymentRowBuilder> {
  _$AdminPaymentRow? _$v;

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

  int? _platformFeePaise;
  int? get platformFeePaise => _$this._platformFeePaise;
  set platformFeePaise(int? platformFeePaise) =>
      _$this._platformFeePaise = platformFeePaise;

  int? _gatewayFeePaise;
  int? get gatewayFeePaise => _$this._gatewayFeePaise;
  set gatewayFeePaise(int? gatewayFeePaise) =>
      _$this._gatewayFeePaise = gatewayFeePaise;

  String? _businessId;
  String? get businessId => _$this._businessId;
  set businessId(String? businessId) => _$this._businessId = businessId;

  String? _businessName;
  String? get businessName => _$this._businessName;
  set businessName(String? businessName) => _$this._businessName = businessName;

  String? _merchantUserId;
  String? get merchantUserId => _$this._merchantUserId;
  set merchantUserId(String? merchantUserId) =>
      _$this._merchantUserId = merchantUserId;

  String? _merchantEmail;
  String? get merchantEmail => _$this._merchantEmail;
  set merchantEmail(String? merchantEmail) =>
      _$this._merchantEmail = merchantEmail;

  String? _merchantName;
  String? get merchantName => _$this._merchantName;
  set merchantName(String? merchantName) => _$this._merchantName = merchantName;

  int? _merchantPaymentCount;
  int? get merchantPaymentCount => _$this._merchantPaymentCount;
  set merchantPaymentCount(int? merchantPaymentCount) =>
      _$this._merchantPaymentCount = merchantPaymentCount;

  bool? _awaitingApproval;
  bool? get awaitingApproval => _$this._awaitingApproval;
  set awaitingApproval(bool? awaitingApproval) =>
      _$this._awaitingApproval = awaitingApproval;

  AdminPaymentRowBuilder() {
    AdminPaymentRow._defaults(this);
  }

  AdminPaymentRowBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _status = $v.status;
      _amountPaise = $v.amountPaise;
      _currency = $v.currency;
      _skuCode = $v.skuCode;
      _durationDays = $v.durationDays;
      _provider = $v.provider;
      _providerOrderId = $v.providerOrderId;
      _createdAt = $v.createdAt;
      _approvedAt = $v.approvedAt;
      _rejectedAt = $v.rejectedAt;
      _platformFeePaise = $v.platformFeePaise;
      _gatewayFeePaise = $v.gatewayFeePaise;
      _businessId = $v.businessId;
      _businessName = $v.businessName;
      _merchantUserId = $v.merchantUserId;
      _merchantEmail = $v.merchantEmail;
      _merchantName = $v.merchantName;
      _merchantPaymentCount = $v.merchantPaymentCount;
      _awaitingApproval = $v.awaitingApproval;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(AdminPaymentRow other) {
    _$v = other as _$AdminPaymentRow;
  }

  @override
  void update(void Function(AdminPaymentRowBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  AdminPaymentRow build() => _build();

  _$AdminPaymentRow _build() {
    final _$result = _$v ??
        _$AdminPaymentRow._(
          id: BuiltValueNullFieldError.checkNotNull(
              id, r'AdminPaymentRow', 'id'),
          status: BuiltValueNullFieldError.checkNotNull(
              status, r'AdminPaymentRow', 'status'),
          amountPaise: BuiltValueNullFieldError.checkNotNull(
              amountPaise, r'AdminPaymentRow', 'amountPaise'),
          currency: BuiltValueNullFieldError.checkNotNull(
              currency, r'AdminPaymentRow', 'currency'),
          skuCode: BuiltValueNullFieldError.checkNotNull(
              skuCode, r'AdminPaymentRow', 'skuCode'),
          durationDays: BuiltValueNullFieldError.checkNotNull(
              durationDays, r'AdminPaymentRow', 'durationDays'),
          provider: BuiltValueNullFieldError.checkNotNull(
              provider, r'AdminPaymentRow', 'provider'),
          providerOrderId: BuiltValueNullFieldError.checkNotNull(
              providerOrderId, r'AdminPaymentRow', 'providerOrderId'),
          createdAt: BuiltValueNullFieldError.checkNotNull(
              createdAt, r'AdminPaymentRow', 'createdAt'),
          approvedAt: approvedAt,
          rejectedAt: rejectedAt,
          platformFeePaise: platformFeePaise,
          gatewayFeePaise: gatewayFeePaise,
          businessId: BuiltValueNullFieldError.checkNotNull(
              businessId, r'AdminPaymentRow', 'businessId'),
          businessName: BuiltValueNullFieldError.checkNotNull(
              businessName, r'AdminPaymentRow', 'businessName'),
          merchantUserId: BuiltValueNullFieldError.checkNotNull(
              merchantUserId, r'AdminPaymentRow', 'merchantUserId'),
          merchantEmail: BuiltValueNullFieldError.checkNotNull(
              merchantEmail, r'AdminPaymentRow', 'merchantEmail'),
          merchantName: BuiltValueNullFieldError.checkNotNull(
              merchantName, r'AdminPaymentRow', 'merchantName'),
          merchantPaymentCount: BuiltValueNullFieldError.checkNotNull(
              merchantPaymentCount, r'AdminPaymentRow', 'merchantPaymentCount'),
          awaitingApproval: BuiltValueNullFieldError.checkNotNull(
              awaitingApproval, r'AdminPaymentRow', 'awaitingApproval'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
