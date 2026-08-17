// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_approve_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$PaymentApproveResponse extends PaymentApproveResponse {
  @override
  final String id;
  @override
  final DateTime approvedAt;
  @override
  final String placementId;
  @override
  final DateTime endsAt;

  factory _$PaymentApproveResponse(
          [void Function(PaymentApproveResponseBuilder)? updates]) =>
      (PaymentApproveResponseBuilder()..update(updates))._build();

  _$PaymentApproveResponse._(
      {required this.id,
      required this.approvedAt,
      required this.placementId,
      required this.endsAt})
      : super._();
  @override
  PaymentApproveResponse rebuild(
          void Function(PaymentApproveResponseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PaymentApproveResponseBuilder toBuilder() =>
      PaymentApproveResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PaymentApproveResponse &&
        id == other.id &&
        approvedAt == other.approvedAt &&
        placementId == other.placementId &&
        endsAt == other.endsAt;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, approvedAt.hashCode);
    _$hash = $jc(_$hash, placementId.hashCode);
    _$hash = $jc(_$hash, endsAt.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PaymentApproveResponse')
          ..add('id', id)
          ..add('approvedAt', approvedAt)
          ..add('placementId', placementId)
          ..add('endsAt', endsAt))
        .toString();
  }
}

class PaymentApproveResponseBuilder
    implements Builder<PaymentApproveResponse, PaymentApproveResponseBuilder> {
  _$PaymentApproveResponse? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  DateTime? _approvedAt;
  DateTime? get approvedAt => _$this._approvedAt;
  set approvedAt(DateTime? approvedAt) => _$this._approvedAt = approvedAt;

  String? _placementId;
  String? get placementId => _$this._placementId;
  set placementId(String? placementId) => _$this._placementId = placementId;

  DateTime? _endsAt;
  DateTime? get endsAt => _$this._endsAt;
  set endsAt(DateTime? endsAt) => _$this._endsAt = endsAt;

  PaymentApproveResponseBuilder() {
    PaymentApproveResponse._defaults(this);
  }

  PaymentApproveResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _approvedAt = $v.approvedAt;
      _placementId = $v.placementId;
      _endsAt = $v.endsAt;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PaymentApproveResponse other) {
    _$v = other as _$PaymentApproveResponse;
  }

  @override
  void update(void Function(PaymentApproveResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PaymentApproveResponse build() => _build();

  _$PaymentApproveResponse _build() {
    final _$result = _$v ??
        _$PaymentApproveResponse._(
          id: BuiltValueNullFieldError.checkNotNull(
              id, r'PaymentApproveResponse', 'id'),
          approvedAt: BuiltValueNullFieldError.checkNotNull(
              approvedAt, r'PaymentApproveResponse', 'approvedAt'),
          placementId: BuiltValueNullFieldError.checkNotNull(
              placementId, r'PaymentApproveResponse', 'placementId'),
          endsAt: BuiltValueNullFieldError.checkNotNull(
              endsAt, r'PaymentApproveResponse', 'endsAt'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
