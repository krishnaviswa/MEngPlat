// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mock_aadhaar_otp_response.dart';

class _$MockAadhaarOtpResponse extends MockAadhaarOtpResponse {
  @override
  final String message;
  @override
  final String? devCode;

  factory _$MockAadhaarOtpResponse(
          [void Function(MockAadhaarOtpResponseBuilder)? updates]) =>
      (MockAadhaarOtpResponseBuilder()..update(updates))._build();

  _$MockAadhaarOtpResponse._({required this.message, this.devCode}) : super._();

  @override
  MockAadhaarOtpResponse rebuild(
          void Function(MockAadhaarOtpResponseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  MockAadhaarOtpResponseBuilder toBuilder() =>
      MockAadhaarOtpResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is MockAadhaarOtpResponse &&
        message == other.message &&
        devCode == other.devCode;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, message.hashCode);
    _$hash = $jc(_$hash, devCode.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'MockAadhaarOtpResponse')
          ..add('message', message)
          ..add('devCode', devCode))
        .toString();
  }
}

class MockAadhaarOtpResponseBuilder
    implements Builder<MockAadhaarOtpResponse, MockAadhaarOtpResponseBuilder> {
  _$MockAadhaarOtpResponse? _$v;

  String? _message;
  String? get message => _$this._message;
  set message(String? message) => _$this._message = message;

  String? _devCode;
  String? get devCode => _$this._devCode;
  set devCode(String? devCode) => _$this._devCode = devCode;

  MockAadhaarOtpResponseBuilder() {
    MockAadhaarOtpResponse._defaults(this);
  }

  MockAadhaarOtpResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _message = $v.message;
      _devCode = $v.devCode;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(MockAadhaarOtpResponse other) {
    _$v = other as _$MockAadhaarOtpResponse;
  }

  @override
  void update(void Function(MockAadhaarOtpResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  MockAadhaarOtpResponse build() => _build();

  _$MockAadhaarOtpResponse _build() {
    final _$result = _$v ??
        _$MockAadhaarOtpResponse._(
          message: BuiltValueNullFieldError.checkNotNull(
              message, r'MockAadhaarOtpResponse', 'message'),
          devCode: devCode,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
