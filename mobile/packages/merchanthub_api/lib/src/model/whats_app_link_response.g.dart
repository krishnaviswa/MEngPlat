// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'whats_app_link_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$WhatsAppLinkResponse extends WhatsAppLinkResponse {
  @override
  final bool available;
  @override
  final String? waUrl;
  @override
  final String? token;
  @override
  final DateTime? expiresAt;
  @override
  final String? displayNumber;

  factory _$WhatsAppLinkResponse(
          [void Function(WhatsAppLinkResponseBuilder)? updates]) =>
      (WhatsAppLinkResponseBuilder()..update(updates))._build();

  _$WhatsAppLinkResponse._(
      {required this.available,
      this.waUrl,
      this.token,
      this.expiresAt,
      this.displayNumber})
      : super._();
  @override
  WhatsAppLinkResponse rebuild(
          void Function(WhatsAppLinkResponseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  WhatsAppLinkResponseBuilder toBuilder() =>
      WhatsAppLinkResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is WhatsAppLinkResponse &&
        available == other.available &&
        waUrl == other.waUrl &&
        token == other.token &&
        expiresAt == other.expiresAt &&
        displayNumber == other.displayNumber;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, available.hashCode);
    _$hash = $jc(_$hash, waUrl.hashCode);
    _$hash = $jc(_$hash, token.hashCode);
    _$hash = $jc(_$hash, expiresAt.hashCode);
    _$hash = $jc(_$hash, displayNumber.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'WhatsAppLinkResponse')
          ..add('available', available)
          ..add('waUrl', waUrl)
          ..add('token', token)
          ..add('expiresAt', expiresAt)
          ..add('displayNumber', displayNumber))
        .toString();
  }
}

class WhatsAppLinkResponseBuilder
    implements Builder<WhatsAppLinkResponse, WhatsAppLinkResponseBuilder> {
  _$WhatsAppLinkResponse? _$v;

  bool? _available;
  bool? get available => _$this._available;
  set available(bool? available) => _$this._available = available;

  String? _waUrl;
  String? get waUrl => _$this._waUrl;
  set waUrl(String? waUrl) => _$this._waUrl = waUrl;

  String? _token;
  String? get token => _$this._token;
  set token(String? token) => _$this._token = token;

  DateTime? _expiresAt;
  DateTime? get expiresAt => _$this._expiresAt;
  set expiresAt(DateTime? expiresAt) => _$this._expiresAt = expiresAt;

  String? _displayNumber;
  String? get displayNumber => _$this._displayNumber;
  set displayNumber(String? displayNumber) =>
      _$this._displayNumber = displayNumber;

  WhatsAppLinkResponseBuilder() {
    WhatsAppLinkResponse._defaults(this);
  }

  WhatsAppLinkResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _available = $v.available;
      _waUrl = $v.waUrl;
      _token = $v.token;
      _expiresAt = $v.expiresAt;
      _displayNumber = $v.displayNumber;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(WhatsAppLinkResponse other) {
    _$v = other as _$WhatsAppLinkResponse;
  }

  @override
  void update(void Function(WhatsAppLinkResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  WhatsAppLinkResponse build() => _build();

  _$WhatsAppLinkResponse _build() {
    final _$result = _$v ??
        _$WhatsAppLinkResponse._(
          available: BuiltValueNullFieldError.checkNotNull(
              available, r'WhatsAppLinkResponse', 'available'),
          waUrl: waUrl,
          token: token,
          expiresAt: expiresAt,
          displayNumber: displayNumber,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
