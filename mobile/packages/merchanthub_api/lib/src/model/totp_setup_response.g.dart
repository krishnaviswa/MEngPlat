// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'totp_setup_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$TotpSetupResponse extends TotpSetupResponse {
  @override
  final String otpauthUri;
  @override
  final String secret;
  @override
  final String qrSvg;

  factory _$TotpSetupResponse(
          [void Function(TotpSetupResponseBuilder)? updates]) =>
      (TotpSetupResponseBuilder()..update(updates))._build();

  _$TotpSetupResponse._(
      {required this.otpauthUri, required this.secret, required this.qrSvg})
      : super._();
  @override
  TotpSetupResponse rebuild(void Function(TotpSetupResponseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  TotpSetupResponseBuilder toBuilder() =>
      TotpSetupResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is TotpSetupResponse &&
        otpauthUri == other.otpauthUri &&
        secret == other.secret &&
        qrSvg == other.qrSvg;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, otpauthUri.hashCode);
    _$hash = $jc(_$hash, secret.hashCode);
    _$hash = $jc(_$hash, qrSvg.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'TotpSetupResponse')
          ..add('otpauthUri', otpauthUri)
          ..add('secret', secret)
          ..add('qrSvg', qrSvg))
        .toString();
  }
}

class TotpSetupResponseBuilder
    implements Builder<TotpSetupResponse, TotpSetupResponseBuilder> {
  _$TotpSetupResponse? _$v;

  String? _otpauthUri;
  String? get otpauthUri => _$this._otpauthUri;
  set otpauthUri(String? otpauthUri) => _$this._otpauthUri = otpauthUri;

  String? _secret;
  String? get secret => _$this._secret;
  set secret(String? secret) => _$this._secret = secret;

  String? _qrSvg;
  String? get qrSvg => _$this._qrSvg;
  set qrSvg(String? qrSvg) => _$this._qrSvg = qrSvg;

  TotpSetupResponseBuilder() {
    TotpSetupResponse._defaults(this);
  }

  TotpSetupResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _otpauthUri = $v.otpauthUri;
      _secret = $v.secret;
      _qrSvg = $v.qrSvg;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(TotpSetupResponse other) {
    _$v = other as _$TotpSetupResponse;
  }

  @override
  void update(void Function(TotpSetupResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  TotpSetupResponse build() => _build();

  _$TotpSetupResponse _build() {
    final _$result = _$v ??
        _$TotpSetupResponse._(
          otpauthUri: BuiltValueNullFieldError.checkNotNull(
              otpauthUri, r'TotpSetupResponse', 'otpauthUri'),
          secret: BuiltValueNullFieldError.checkNotNull(
              secret, r'TotpSetupResponse', 'secret'),
          qrSvg: BuiltValueNullFieldError.checkNotNull(
              qrSvg, r'TotpSetupResponse', 'qrSvg'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
