// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'phone_otp_verify_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$PhoneOtpVerifyRequest extends PhoneOtpVerifyRequest {
  @override
  final String phone;
  @override
  final String code;
  @override
  final String? fullName;
  @override
  final UserRole? role;

  factory _$PhoneOtpVerifyRequest(
          [void Function(PhoneOtpVerifyRequestBuilder)? updates]) =>
      (PhoneOtpVerifyRequestBuilder()..update(updates))._build();

  _$PhoneOtpVerifyRequest._(
      {required this.phone, required this.code, this.fullName, this.role})
      : super._();
  @override
  PhoneOtpVerifyRequest rebuild(
          void Function(PhoneOtpVerifyRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PhoneOtpVerifyRequestBuilder toBuilder() =>
      PhoneOtpVerifyRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PhoneOtpVerifyRequest &&
        phone == other.phone &&
        code == other.code &&
        fullName == other.fullName &&
        role == other.role;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, phone.hashCode);
    _$hash = $jc(_$hash, code.hashCode);
    _$hash = $jc(_$hash, fullName.hashCode);
    _$hash = $jc(_$hash, role.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PhoneOtpVerifyRequest')
          ..add('phone', phone)
          ..add('code', code)
          ..add('fullName', fullName)
          ..add('role', role))
        .toString();
  }
}

class PhoneOtpVerifyRequestBuilder
    implements Builder<PhoneOtpVerifyRequest, PhoneOtpVerifyRequestBuilder> {
  _$PhoneOtpVerifyRequest? _$v;

  String? _phone;
  String? get phone => _$this._phone;
  set phone(String? phone) => _$this._phone = phone;

  String? _code;
  String? get code => _$this._code;
  set code(String? code) => _$this._code = code;

  String? _fullName;
  String? get fullName => _$this._fullName;
  set fullName(String? fullName) => _$this._fullName = fullName;

  UserRole? _role;
  UserRole? get role => _$this._role;
  set role(UserRole? role) => _$this._role = role;

  PhoneOtpVerifyRequestBuilder() {
    PhoneOtpVerifyRequest._defaults(this);
  }

  PhoneOtpVerifyRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _phone = $v.phone;
      _code = $v.code;
      _fullName = $v.fullName;
      _role = $v.role;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PhoneOtpVerifyRequest other) {
    _$v = other as _$PhoneOtpVerifyRequest;
  }

  @override
  void update(void Function(PhoneOtpVerifyRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PhoneOtpVerifyRequest build() => _build();

  _$PhoneOtpVerifyRequest _build() {
    final _$result = _$v ??
        _$PhoneOtpVerifyRequest._(
          phone: BuiltValueNullFieldError.checkNotNull(
              phone, r'PhoneOtpVerifyRequest', 'phone'),
          code: BuiltValueNullFieldError.checkNotNull(
              code, r'PhoneOtpVerifyRequest', 'code'),
          fullName: fullName,
          role: role,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
