// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'login_result.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$LoginResult extends LoginResult {
  @override
  final String? accessToken;
  @override
  final String? refreshToken;
  @override
  final String? tokenType;
  @override
  final bool? mfaRequired;
  @override
  final bool? mfaEnrollmentRequired;
  @override
  final String? mfaToken;

  factory _$LoginResult([void Function(LoginResultBuilder)? updates]) =>
      (LoginResultBuilder()..update(updates))._build();

  _$LoginResult._(
      {this.accessToken,
      this.refreshToken,
      this.tokenType,
      this.mfaRequired,
      this.mfaEnrollmentRequired,
      this.mfaToken})
      : super._();
  @override
  LoginResult rebuild(void Function(LoginResultBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  LoginResultBuilder toBuilder() => LoginResultBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is LoginResult &&
        accessToken == other.accessToken &&
        refreshToken == other.refreshToken &&
        tokenType == other.tokenType &&
        mfaRequired == other.mfaRequired &&
        mfaEnrollmentRequired == other.mfaEnrollmentRequired &&
        mfaToken == other.mfaToken;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, accessToken.hashCode);
    _$hash = $jc(_$hash, refreshToken.hashCode);
    _$hash = $jc(_$hash, tokenType.hashCode);
    _$hash = $jc(_$hash, mfaRequired.hashCode);
    _$hash = $jc(_$hash, mfaEnrollmentRequired.hashCode);
    _$hash = $jc(_$hash, mfaToken.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'LoginResult')
          ..add('accessToken', accessToken)
          ..add('refreshToken', refreshToken)
          ..add('tokenType', tokenType)
          ..add('mfaRequired', mfaRequired)
          ..add('mfaEnrollmentRequired', mfaEnrollmentRequired)
          ..add('mfaToken', mfaToken))
        .toString();
  }
}

class LoginResultBuilder implements Builder<LoginResult, LoginResultBuilder> {
  _$LoginResult? _$v;

  String? _accessToken;
  String? get accessToken => _$this._accessToken;
  set accessToken(String? accessToken) => _$this._accessToken = accessToken;

  String? _refreshToken;
  String? get refreshToken => _$this._refreshToken;
  set refreshToken(String? refreshToken) => _$this._refreshToken = refreshToken;

  String? _tokenType;
  String? get tokenType => _$this._tokenType;
  set tokenType(String? tokenType) => _$this._tokenType = tokenType;

  bool? _mfaRequired;
  bool? get mfaRequired => _$this._mfaRequired;
  set mfaRequired(bool? mfaRequired) => _$this._mfaRequired = mfaRequired;

  bool? _mfaEnrollmentRequired;
  bool? get mfaEnrollmentRequired => _$this._mfaEnrollmentRequired;
  set mfaEnrollmentRequired(bool? mfaEnrollmentRequired) =>
      _$this._mfaEnrollmentRequired = mfaEnrollmentRequired;

  String? _mfaToken;
  String? get mfaToken => _$this._mfaToken;
  set mfaToken(String? mfaToken) => _$this._mfaToken = mfaToken;

  LoginResultBuilder() {
    LoginResult._defaults(this);
  }

  LoginResultBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _accessToken = $v.accessToken;
      _refreshToken = $v.refreshToken;
      _tokenType = $v.tokenType;
      _mfaRequired = $v.mfaRequired;
      _mfaEnrollmentRequired = $v.mfaEnrollmentRequired;
      _mfaToken = $v.mfaToken;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(LoginResult other) {
    _$v = other as _$LoginResult;
  }

  @override
  void update(void Function(LoginResultBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  LoginResult build() => _build();

  _$LoginResult _build() {
    final _$result = _$v ??
        _$LoginResult._(
          accessToken: accessToken,
          refreshToken: refreshToken,
          tokenType: tokenType,
          mfaRequired: mfaRequired,
          mfaEnrollmentRequired: mfaEnrollmentRequired,
          mfaToken: mfaToken,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
