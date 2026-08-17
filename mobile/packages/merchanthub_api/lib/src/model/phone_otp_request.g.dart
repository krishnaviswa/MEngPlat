// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'phone_otp_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$PhoneOtpRequest extends PhoneOtpRequest {
  @override
  final String phone;

  factory _$PhoneOtpRequest([void Function(PhoneOtpRequestBuilder)? updates]) =>
      (PhoneOtpRequestBuilder()..update(updates))._build();

  _$PhoneOtpRequest._({required this.phone}) : super._();
  @override
  PhoneOtpRequest rebuild(void Function(PhoneOtpRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PhoneOtpRequestBuilder toBuilder() => PhoneOtpRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PhoneOtpRequest && phone == other.phone;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, phone.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PhoneOtpRequest')
          ..add('phone', phone))
        .toString();
  }
}

class PhoneOtpRequestBuilder
    implements Builder<PhoneOtpRequest, PhoneOtpRequestBuilder> {
  _$PhoneOtpRequest? _$v;

  String? _phone;
  String? get phone => _$this._phone;
  set phone(String? phone) => _$this._phone = phone;

  PhoneOtpRequestBuilder() {
    PhoneOtpRequest._defaults(this);
  }

  PhoneOtpRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _phone = $v.phone;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PhoneOtpRequest other) {
    _$v = other as _$PhoneOtpRequest;
  }

  @override
  void update(void Function(PhoneOtpRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PhoneOtpRequest build() => _build();

  _$PhoneOtpRequest _build() {
    final _$result = _$v ??
        _$PhoneOtpRequest._(
          phone: BuiltValueNullFieldError.checkNotNull(
              phone, r'PhoneOtpRequest', 'phone'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
