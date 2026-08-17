// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_reject_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$PaymentRejectResponse extends PaymentRejectResponse {
  @override
  final String id;
  @override
  final DateTime rejectedAt;

  factory _$PaymentRejectResponse(
          [void Function(PaymentRejectResponseBuilder)? updates]) =>
      (PaymentRejectResponseBuilder()..update(updates))._build();

  _$PaymentRejectResponse._({required this.id, required this.rejectedAt})
      : super._();
  @override
  PaymentRejectResponse rebuild(
          void Function(PaymentRejectResponseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PaymentRejectResponseBuilder toBuilder() =>
      PaymentRejectResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PaymentRejectResponse &&
        id == other.id &&
        rejectedAt == other.rejectedAt;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, rejectedAt.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PaymentRejectResponse')
          ..add('id', id)
          ..add('rejectedAt', rejectedAt))
        .toString();
  }
}

class PaymentRejectResponseBuilder
    implements Builder<PaymentRejectResponse, PaymentRejectResponseBuilder> {
  _$PaymentRejectResponse? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  DateTime? _rejectedAt;
  DateTime? get rejectedAt => _$this._rejectedAt;
  set rejectedAt(DateTime? rejectedAt) => _$this._rejectedAt = rejectedAt;

  PaymentRejectResponseBuilder() {
    PaymentRejectResponse._defaults(this);
  }

  PaymentRejectResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _rejectedAt = $v.rejectedAt;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PaymentRejectResponse other) {
    _$v = other as _$PaymentRejectResponse;
  }

  @override
  void update(void Function(PaymentRejectResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PaymentRejectResponse build() => _build();

  _$PaymentRejectResponse _build() {
    final _$result = _$v ??
        _$PaymentRejectResponse._(
          id: BuiltValueNullFieldError.checkNotNull(
              id, r'PaymentRejectResponse', 'id'),
          rejectedAt: BuiltValueNullFieldError.checkNotNull(
              rejectedAt, r'PaymentRejectResponse', 'rejectedAt'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
