// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mock_aadhaar_otp_request.dart';

class _$MockAadhaarOtpRequest extends MockAadhaarOtpRequest {
  @override
  final String aadhaarNumber;

  factory _$MockAadhaarOtpRequest(
          [void Function(MockAadhaarOtpRequestBuilder)? updates]) =>
      (MockAadhaarOtpRequestBuilder()..update(updates))._build();

  _$MockAadhaarOtpRequest._({required this.aadhaarNumber}) : super._();

  @override
  MockAadhaarOtpRequest rebuild(
          void Function(MockAadhaarOtpRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  MockAadhaarOtpRequestBuilder toBuilder() =>
      MockAadhaarOtpRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is MockAadhaarOtpRequest && aadhaarNumber == other.aadhaarNumber;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, aadhaarNumber.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'MockAadhaarOtpRequest')
          ..add('aadhaarNumber', aadhaarNumber))
        .toString();
  }
}

class MockAadhaarOtpRequestBuilder
    implements Builder<MockAadhaarOtpRequest, MockAadhaarOtpRequestBuilder> {
  _$MockAadhaarOtpRequest? _$v;

  String? _aadhaarNumber;
  String? get aadhaarNumber => _$this._aadhaarNumber;
  set aadhaarNumber(String? aadhaarNumber) => _$this._aadhaarNumber = aadhaarNumber;

  MockAadhaarOtpRequestBuilder() {
    MockAadhaarOtpRequest._defaults(this);
  }

  MockAadhaarOtpRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _aadhaarNumber = $v.aadhaarNumber;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(MockAadhaarOtpRequest other) {
    _$v = other as _$MockAadhaarOtpRequest;
  }

  @override
  void update(void Function(MockAadhaarOtpRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  MockAadhaarOtpRequest build() => _build();

  _$MockAadhaarOtpRequest _build() {
    final _$result = _$v ??
        _$MockAadhaarOtpRequest._(
          aadhaarNumber: BuiltValueNullFieldError.checkNotNull(
              aadhaarNumber, r'MockAadhaarOtpRequest', 'aadhaarNumber'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
