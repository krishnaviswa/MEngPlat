// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'google_auth_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$GoogleAuthRequest extends GoogleAuthRequest {
  @override
  final String credential;

  factory _$GoogleAuthRequest(
          [void Function(GoogleAuthRequestBuilder)? updates]) =>
      (GoogleAuthRequestBuilder()..update(updates))._build();

  _$GoogleAuthRequest._({required this.credential}) : super._();
  @override
  GoogleAuthRequest rebuild(void Function(GoogleAuthRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  GoogleAuthRequestBuilder toBuilder() =>
      GoogleAuthRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is GoogleAuthRequest && credential == other.credential;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, credential.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'GoogleAuthRequest')
          ..add('credential', credential))
        .toString();
  }
}

class GoogleAuthRequestBuilder
    implements Builder<GoogleAuthRequest, GoogleAuthRequestBuilder> {
  _$GoogleAuthRequest? _$v;

  String? _credential;
  String? get credential => _$this._credential;
  set credential(String? credential) => _$this._credential = credential;

  GoogleAuthRequestBuilder() {
    GoogleAuthRequest._defaults(this);
  }

  GoogleAuthRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _credential = $v.credential;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(GoogleAuthRequest other) {
    _$v = other as _$GoogleAuthRequest;
  }

  @override
  void update(void Function(GoogleAuthRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  GoogleAuthRequest build() => _build();

  _$GoogleAuthRequest _build() {
    final _$result = _$v ??
        _$GoogleAuthRequest._(
          credential: BuiltValueNullFieldError.checkNotNull(
              credential, r'GoogleAuthRequest', 'credential'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
