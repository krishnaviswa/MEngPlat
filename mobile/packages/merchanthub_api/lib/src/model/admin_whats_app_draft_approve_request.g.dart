// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_whats_app_draft_approve_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$AdminWhatsAppDraftApproveRequest
    extends AdminWhatsAppDraftApproveRequest {
  @override
  final JsonObject? fields;

  factory _$AdminWhatsAppDraftApproveRequest(
          [void Function(AdminWhatsAppDraftApproveRequestBuilder)? updates]) =>
      (AdminWhatsAppDraftApproveRequestBuilder()..update(updates))._build();

  _$AdminWhatsAppDraftApproveRequest._({this.fields}) : super._();
  @override
  AdminWhatsAppDraftApproveRequest rebuild(
          void Function(AdminWhatsAppDraftApproveRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  AdminWhatsAppDraftApproveRequestBuilder toBuilder() =>
      AdminWhatsAppDraftApproveRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is AdminWhatsAppDraftApproveRequest && fields == other.fields;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, fields.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'AdminWhatsAppDraftApproveRequest')
          ..add('fields', fields))
        .toString();
  }
}

class AdminWhatsAppDraftApproveRequestBuilder
    implements
        Builder<AdminWhatsAppDraftApproveRequest,
            AdminWhatsAppDraftApproveRequestBuilder> {
  _$AdminWhatsAppDraftApproveRequest? _$v;

  JsonObject? _fields;
  JsonObject? get fields => _$this._fields;
  set fields(JsonObject? fields) => _$this._fields = fields;

  AdminWhatsAppDraftApproveRequestBuilder() {
    AdminWhatsAppDraftApproveRequest._defaults(this);
  }

  AdminWhatsAppDraftApproveRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _fields = $v.fields;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(AdminWhatsAppDraftApproveRequest other) {
    _$v = other as _$AdminWhatsAppDraftApproveRequest;
  }

  @override
  void update(void Function(AdminWhatsAppDraftApproveRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  AdminWhatsAppDraftApproveRequest build() => _build();

  _$AdminWhatsAppDraftApproveRequest _build() {
    final _$result = _$v ??
        _$AdminWhatsAppDraftApproveRequest._(
          fields: fields,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
