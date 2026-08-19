// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mock_otp_verify_request.dart';

class _$MockOtpVerifyRequest extends MockOtpVerifyRequest {
  @override
  final String code;

  factory _$MockOtpVerifyRequest(
          [void Function(MockOtpVerifyRequestBuilder)? updates]) =>
      (MockOtpVerifyRequestBuilder()..update(updates))._build();

  _$MockOtpVerifyRequest._({required this.code}) : super._();

  @override
  MockOtpVerifyRequest rebuild(
          void Function(MockOtpVerifyRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  MockOtpVerifyRequestBuilder toBuilder() =>
      MockOtpVerifyRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is MockOtpVerifyRequest && code == other.code;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, code.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'MockOtpVerifyRequest')..add('code', code))
        .toString();
  }
}

class MockOtpVerifyRequestBuilder
    implements Builder<MockOtpVerifyRequest, MockOtpVerifyRequestBuilder> {
  _$MockOtpVerifyRequest? _$v;

  String? _code;
  String? get code => _$this._code;
  set code(String? code) => _$this._code = code;

  MockOtpVerifyRequestBuilder() {
    MockOtpVerifyRequest._defaults(this);
  }

  MockOtpVerifyRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _code = $v.code;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(MockOtpVerifyRequest other) {
    _$v = other as _$MockOtpVerifyRequest;
  }

  @override
  void update(void Function(MockOtpVerifyRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  MockOtpVerifyRequest build() => _build();

  _$MockOtpVerifyRequest _build() {
    final _$result = _$v ??
        _$MockOtpVerifyRequest._(
          code: BuiltValueNullFieldError.checkNotNull(
              code, r'MockOtpVerifyRequest', 'code'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
