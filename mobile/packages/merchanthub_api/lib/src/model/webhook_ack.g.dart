// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'webhook_ack.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$WebhookAck extends WebhookAck {
  @override
  final bool? ok;
  @override
  final bool? duplicate;

  factory _$WebhookAck([void Function(WebhookAckBuilder)? updates]) =>
      (WebhookAckBuilder()..update(updates))._build();

  _$WebhookAck._({this.ok, this.duplicate}) : super._();
  @override
  WebhookAck rebuild(void Function(WebhookAckBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  WebhookAckBuilder toBuilder() => WebhookAckBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is WebhookAck &&
        ok == other.ok &&
        duplicate == other.duplicate;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, ok.hashCode);
    _$hash = $jc(_$hash, duplicate.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'WebhookAck')
          ..add('ok', ok)
          ..add('duplicate', duplicate))
        .toString();
  }
}

class WebhookAckBuilder implements Builder<WebhookAck, WebhookAckBuilder> {
  _$WebhookAck? _$v;

  bool? _ok;
  bool? get ok => _$this._ok;
  set ok(bool? ok) => _$this._ok = ok;

  bool? _duplicate;
  bool? get duplicate => _$this._duplicate;
  set duplicate(bool? duplicate) => _$this._duplicate = duplicate;

  WebhookAckBuilder() {
    WebhookAck._defaults(this);
  }

  WebhookAckBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _ok = $v.ok;
      _duplicate = $v.duplicate;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(WebhookAck other) {
    _$v = other as _$WebhookAck;
  }

  @override
  void update(void Function(WebhookAckBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  WebhookAck build() => _build();

  _$WebhookAck _build() {
    final _$result = _$v ??
        _$WebhookAck._(
          ok: ok,
          duplicate: duplicate,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
