// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'whats_app_draft_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$WhatsAppDraftResponse extends WhatsAppDraftResponse {
  @override
  final String id;
  @override
  final String source_;
  @override
  final JsonObject extractedFields;
  @override
  final DraftStatus status;
  @override
  final bool? degraded;
  @override
  final DateTime createdAt;

  factory _$WhatsAppDraftResponse(
          [void Function(WhatsAppDraftResponseBuilder)? updates]) =>
      (WhatsAppDraftResponseBuilder()..update(updates))._build();

  _$WhatsAppDraftResponse._(
      {required this.id,
      required this.source_,
      required this.extractedFields,
      required this.status,
      this.degraded,
      required this.createdAt})
      : super._();
  @override
  WhatsAppDraftResponse rebuild(
          void Function(WhatsAppDraftResponseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  WhatsAppDraftResponseBuilder toBuilder() =>
      WhatsAppDraftResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is WhatsAppDraftResponse &&
        id == other.id &&
        source_ == other.source_ &&
        extractedFields == other.extractedFields &&
        status == other.status &&
        degraded == other.degraded &&
        createdAt == other.createdAt;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, source_.hashCode);
    _$hash = $jc(_$hash, extractedFields.hashCode);
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jc(_$hash, degraded.hashCode);
    _$hash = $jc(_$hash, createdAt.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'WhatsAppDraftResponse')
          ..add('id', id)
          ..add('source_', source_)
          ..add('extractedFields', extractedFields)
          ..add('status', status)
          ..add('degraded', degraded)
          ..add('createdAt', createdAt))
        .toString();
  }
}

class WhatsAppDraftResponseBuilder
    implements Builder<WhatsAppDraftResponse, WhatsAppDraftResponseBuilder> {
  _$WhatsAppDraftResponse? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _source_;
  String? get source_ => _$this._source_;
  set source_(String? source_) => _$this._source_ = source_;

  JsonObject? _extractedFields;
  JsonObject? get extractedFields => _$this._extractedFields;
  set extractedFields(JsonObject? extractedFields) =>
      _$this._extractedFields = extractedFields;

  DraftStatus? _status;
  DraftStatus? get status => _$this._status;
  set status(DraftStatus? status) => _$this._status = status;

  bool? _degraded;
  bool? get degraded => _$this._degraded;
  set degraded(bool? degraded) => _$this._degraded = degraded;

  DateTime? _createdAt;
  DateTime? get createdAt => _$this._createdAt;
  set createdAt(DateTime? createdAt) => _$this._createdAt = createdAt;

  WhatsAppDraftResponseBuilder() {
    WhatsAppDraftResponse._defaults(this);
  }

  WhatsAppDraftResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _source_ = $v.source_;
      _extractedFields = $v.extractedFields;
      _status = $v.status;
      _degraded = $v.degraded;
      _createdAt = $v.createdAt;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(WhatsAppDraftResponse other) {
    _$v = other as _$WhatsAppDraftResponse;
  }

  @override
  void update(void Function(WhatsAppDraftResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  WhatsAppDraftResponse build() => _build();

  _$WhatsAppDraftResponse _build() {
    final _$result = _$v ??
        _$WhatsAppDraftResponse._(
          id: BuiltValueNullFieldError.checkNotNull(
              id, r'WhatsAppDraftResponse', 'id'),
          source_: BuiltValueNullFieldError.checkNotNull(
              source_, r'WhatsAppDraftResponse', 'source_'),
          extractedFields: BuiltValueNullFieldError.checkNotNull(
              extractedFields, r'WhatsAppDraftResponse', 'extractedFields'),
          status: BuiltValueNullFieldError.checkNotNull(
              status, r'WhatsAppDraftResponse', 'status'),
          degraded: degraded,
          createdAt: BuiltValueNullFieldError.checkNotNull(
              createdAt, r'WhatsAppDraftResponse', 'createdAt'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
