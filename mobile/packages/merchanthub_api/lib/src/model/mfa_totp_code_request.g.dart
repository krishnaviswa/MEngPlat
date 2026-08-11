// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mfa_totp_code_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$MfaTotpCodeRequest extends MfaTotpCodeRequest {
  @override
  final String mfaToken;
  @override
  final String code;

  factory _$MfaTotpCodeRequest(
          [void Function(MfaTotpCodeRequestBuilder)? updates]) =>
      (MfaTotpCodeRequestBuilder()..update(updates))._build();

  _$MfaTotpCodeRequest._({required this.mfaToken, required this.code})
      : super._();
  @override
  MfaTotpCodeRequest rebuild(
          void Function(MfaTotpCodeRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  MfaTotpCodeRequestBuilder toBuilder() =>
      MfaTotpCodeRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is MfaTotpCodeRequest &&
        mfaToken == other.mfaToken &&
        code == other.code;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, mfaToken.hashCode);
    _$hash = $jc(_$hash, code.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'MfaTotpCodeRequest')
          ..add('mfaToken', mfaToken)
          ..add('code', code))
        .toString();
  }
}

class MfaTotpCodeRequestBuilder
    implements Builder<MfaTotpCodeRequest, MfaTotpCodeRequestBuilder> {
  _$MfaTotpCodeRequest? _$v;

  String? _mfaToken;
  String? get mfaToken => _$this._mfaToken;
  set mfaToken(String? mfaToken) => _$this._mfaToken = mfaToken;

  String? _code;
  String? get code => _$this._code;
  set code(String? code) => _$this._code = code;

  MfaTotpCodeRequestBuilder() {
    MfaTotpCodeRequest._defaults(this);
  }

  MfaTotpCodeRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _mfaToken = $v.mfaToken;
      _code = $v.code;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(MfaTotpCodeRequest other) {
    _$v = other as _$MfaTotpCodeRequest;
  }

  @override
  void update(void Function(MfaTotpCodeRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  MfaTotpCodeRequest build() => _build();

  _$MfaTotpCodeRequest _build() {
    final _$result = _$v ??
        _$MfaTotpCodeRequest._(
          mfaToken: BuiltValueNullFieldError.checkNotNull(
              mfaToken, r'MfaTotpCodeRequest', 'mfaToken'),
          code: BuiltValueNullFieldError.checkNotNull(
              code, r'MfaTotpCodeRequest', 'code'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
