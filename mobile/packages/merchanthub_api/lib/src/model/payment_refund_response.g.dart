// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_refund_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$PaymentRefundResponse extends PaymentRefundResponse {
  @override
  final String id;
  @override
  final String status;

  factory _$PaymentRefundResponse(
          [void Function(PaymentRefundResponseBuilder)? updates]) =>
      (PaymentRefundResponseBuilder()..update(updates))._build();

  _$PaymentRefundResponse._({required this.id, required this.status})
      : super._();
  @override
  PaymentRefundResponse rebuild(
          void Function(PaymentRefundResponseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PaymentRefundResponseBuilder toBuilder() =>
      PaymentRefundResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PaymentRefundResponse &&
        id == other.id &&
        status == other.status;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PaymentRefundResponse')
          ..add('id', id)
          ..add('status', status))
        .toString();
  }
}

class PaymentRefundResponseBuilder
    implements Builder<PaymentRefundResponse, PaymentRefundResponseBuilder> {
  _$PaymentRefundResponse? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _status;
  String? get status => _$this._status;
  set status(String? status) => _$this._status = status;

  PaymentRefundResponseBuilder() {
    PaymentRefundResponse._defaults(this);
  }

  PaymentRefundResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _status = $v.status;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PaymentRefundResponse other) {
    _$v = other as _$PaymentRefundResponse;
  }

  @override
  void update(void Function(PaymentRefundResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PaymentRefundResponse build() => _build();

  _$PaymentRefundResponse _build() {
    final _$result = _$v ??
        _$PaymentRefundResponse._(
          id: BuiltValueNullFieldError.checkNotNull(
              id, r'PaymentRefundResponse', 'id'),
          status: BuiltValueNullFieldError.checkNotNull(
              status, r'PaymentRefundResponse', 'status'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
