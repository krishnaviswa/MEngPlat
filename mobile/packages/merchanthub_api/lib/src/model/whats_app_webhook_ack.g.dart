// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'whats_app_webhook_ack.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$WhatsAppWebhookAck extends WhatsAppWebhookAck {
  @override
  final bool? ok;
  @override
  final int? processed;

  factory _$WhatsAppWebhookAck(
          [void Function(WhatsAppWebhookAckBuilder)? updates]) =>
      (WhatsAppWebhookAckBuilder()..update(updates))._build();

  _$WhatsAppWebhookAck._({this.ok, this.processed}) : super._();
  @override
  WhatsAppWebhookAck rebuild(
          void Function(WhatsAppWebhookAckBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  WhatsAppWebhookAckBuilder toBuilder() =>
      WhatsAppWebhookAckBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is WhatsAppWebhookAck &&
        ok == other.ok &&
        processed == other.processed;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, ok.hashCode);
    _$hash = $jc(_$hash, processed.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'WhatsAppWebhookAck')
          ..add('ok', ok)
          ..add('processed', processed))
        .toString();
  }
}

class WhatsAppWebhookAckBuilder
    implements Builder<WhatsAppWebhookAck, WhatsAppWebhookAckBuilder> {
  _$WhatsAppWebhookAck? _$v;

  bool? _ok;
  bool? get ok => _$this._ok;
  set ok(bool? ok) => _$this._ok = ok;

  int? _processed;
  int? get processed => _$this._processed;
  set processed(int? processed) => _$this._processed = processed;

  WhatsAppWebhookAckBuilder() {
    WhatsAppWebhookAck._defaults(this);
  }

  WhatsAppWebhookAckBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _ok = $v.ok;
      _processed = $v.processed;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(WhatsAppWebhookAck other) {
    _$v = other as _$WhatsAppWebhookAck;
  }

  @override
  void update(void Function(WhatsAppWebhookAckBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  WhatsAppWebhookAck build() => _build();

  _$WhatsAppWebhookAck _build() {
    final _$result = _$v ??
        _$WhatsAppWebhookAck._(
          ok: ok,
          processed: processed,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
