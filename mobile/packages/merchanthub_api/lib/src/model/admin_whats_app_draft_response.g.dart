// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_whats_app_draft_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$AdminWhatsAppDraftResponse extends AdminWhatsAppDraftResponse {
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
  @override
  final String businessId;
  @override
  final String businessName;

  factory _$AdminWhatsAppDraftResponse(
          [void Function(AdminWhatsAppDraftResponseBuilder)? updates]) =>
      (AdminWhatsAppDraftResponseBuilder()..update(updates))._build();

  _$AdminWhatsAppDraftResponse._(
      {required this.id,
      required this.source_,
      required this.extractedFields,
      required this.status,
      this.degraded,
      required this.createdAt,
      required this.businessId,
      required this.businessName})
      : super._();
  @override
  AdminWhatsAppDraftResponse rebuild(
          void Function(AdminWhatsAppDraftResponseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  AdminWhatsAppDraftResponseBuilder toBuilder() =>
      AdminWhatsAppDraftResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is AdminWhatsAppDraftResponse &&
        id == other.id &&
        source_ == other.source_ &&
        extractedFields == other.extractedFields &&
        status == other.status &&
        degraded == other.degraded &&
        createdAt == other.createdAt &&
        businessId == other.businessId &&
        businessName == other.businessName;
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
    _$hash = $jc(_$hash, businessId.hashCode);
    _$hash = $jc(_$hash, businessName.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'AdminWhatsAppDraftResponse')
          ..add('id', id)
          ..add('source_', source_)
          ..add('extractedFields', extractedFields)
          ..add('status', status)
          ..add('degraded', degraded)
          ..add('createdAt', createdAt)
          ..add('businessId', businessId)
          ..add('businessName', businessName))
        .toString();
  }
}

class AdminWhatsAppDraftResponseBuilder
    implements
        Builder<AdminWhatsAppDraftResponse, AdminWhatsAppDraftResponseBuilder> {
  _$AdminWhatsAppDraftResponse? _$v;

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

  String? _businessId;
  String? get businessId => _$this._businessId;
  set businessId(String? businessId) => _$this._businessId = businessId;

  String? _businessName;
  String? get businessName => _$this._businessName;
  set businessName(String? businessName) => _$this._businessName = businessName;

  AdminWhatsAppDraftResponseBuilder() {
    AdminWhatsAppDraftResponse._defaults(this);
  }

  AdminWhatsAppDraftResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _source_ = $v.source_;
      _extractedFields = $v.extractedFields;
      _status = $v.status;
      _degraded = $v.degraded;
      _createdAt = $v.createdAt;
      _businessId = $v.businessId;
      _businessName = $v.businessName;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(AdminWhatsAppDraftResponse other) {
    _$v = other as _$AdminWhatsAppDraftResponse;
  }

  @override
  void update(void Function(AdminWhatsAppDraftResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  AdminWhatsAppDraftResponse build() => _build();

  _$AdminWhatsAppDraftResponse _build() {
    final _$result = _$v ??
        _$AdminWhatsAppDraftResponse._(
          id: BuiltValueNullFieldError.checkNotNull(
              id, r'AdminWhatsAppDraftResponse', 'id'),
          source_: BuiltValueNullFieldError.checkNotNull(
              source_, r'AdminWhatsAppDraftResponse', 'source_'),
          extractedFields: BuiltValueNullFieldError.checkNotNull(
              extractedFields,
              r'AdminWhatsAppDraftResponse',
              'extractedFields'),
          status: BuiltValueNullFieldError.checkNotNull(
              status, r'AdminWhatsAppDraftResponse', 'status'),
          degraded: degraded,
          createdAt: BuiltValueNullFieldError.checkNotNull(
              createdAt, r'AdminWhatsAppDraftResponse', 'createdAt'),
          businessId: BuiltValueNullFieldError.checkNotNull(
              businessId, r'AdminWhatsAppDraftResponse', 'businessId'),
          businessName: BuiltValueNullFieldError.checkNotNull(
              businessName, r'AdminWhatsAppDraftResponse', 'businessName'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
