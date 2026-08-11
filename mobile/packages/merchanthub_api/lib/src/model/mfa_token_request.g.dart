// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mfa_token_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$MfaTokenRequest extends MfaTokenRequest {
  @override
  final String mfaToken;

  factory _$MfaTokenRequest([void Function(MfaTokenRequestBuilder)? updates]) =>
      (MfaTokenRequestBuilder()..update(updates))._build();

  _$MfaTokenRequest._({required this.mfaToken}) : super._();
  @override
  MfaTokenRequest rebuild(void Function(MfaTokenRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  MfaTokenRequestBuilder toBuilder() => MfaTokenRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is MfaTokenRequest && mfaToken == other.mfaToken;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, mfaToken.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'MfaTokenRequest')
          ..add('mfaToken', mfaToken))
        .toString();
  }
}

class MfaTokenRequestBuilder
    implements Builder<MfaTokenRequest, MfaTokenRequestBuilder> {
  _$MfaTokenRequest? _$v;

  String? _mfaToken;
  String? get mfaToken => _$this._mfaToken;
  set mfaToken(String? mfaToken) => _$this._mfaToken = mfaToken;

  MfaTokenRequestBuilder() {
    MfaTokenRequest._defaults(this);
  }

  MfaTokenRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _mfaToken = $v.mfaToken;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(MfaTokenRequest other) {
    _$v = other as _$MfaTokenRequest;
  }

  @override
  void update(void Function(MfaTokenRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  MfaTokenRequest build() => _build();

  _$MfaTokenRequest _build() {
    final _$result = _$v ??
        _$MfaTokenRequest._(
          mfaToken: BuiltValueNullFieldError.checkNotNull(
              mfaToken, r'MfaTokenRequest', 'mfaToken'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
