// GENERATED CODE - DO NOT MODIFY BY HAND
part of 'support_ticket_admin_update.dart';

class _$SupportTicketAdminUpdate extends SupportTicketAdminUpdate {
  @override
  final String? status;
  @override
  final String? adminResponse;

  factory _$SupportTicketAdminUpdate(
          [void Function(SupportTicketAdminUpdateBuilder)? updates]) =>
      (SupportTicketAdminUpdateBuilder()..update(updates))._build();

  _$SupportTicketAdminUpdate._({this.status, this.adminResponse}) : super._();

  @override
  SupportTicketAdminUpdate rebuild(
          void Function(SupportTicketAdminUpdateBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  SupportTicketAdminUpdateBuilder toBuilder() =>
      SupportTicketAdminUpdateBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is SupportTicketAdminUpdate &&
        status == other.status &&
        adminResponse == other.adminResponse;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jc(_$hash, adminResponse.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'SupportTicketAdminUpdate')
          ..add('status', status)
          ..add('adminResponse', adminResponse))
        .toString();
  }
}

class SupportTicketAdminUpdateBuilder
    implements Builder<SupportTicketAdminUpdate, SupportTicketAdminUpdateBuilder> {
  _$SupportTicketAdminUpdate? _$v;
  String? _status;
  String? get status => _$this._status;
  set status(String? status) => _$this._status = status;
  String? _adminResponse;
  String? get adminResponse => _$this._adminResponse;
  set adminResponse(String? adminResponse) => _$this._adminResponse = adminResponse;

  SupportTicketAdminUpdateBuilder() {
    SupportTicketAdminUpdate._defaults(this);
  }

  SupportTicketAdminUpdateBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _status = $v.status;
      _adminResponse = $v.adminResponse;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(SupportTicketAdminUpdate other) {
    _$v = other as _$SupportTicketAdminUpdate;
  }

  @override
  void update(void Function(SupportTicketAdminUpdateBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  SupportTicketAdminUpdate build() => _build();

  _$SupportTicketAdminUpdate _build() {
    final _$result = _$v ?? _$SupportTicketAdminUpdate._(status: status, adminResponse: adminResponse);
    replace(_$result);
    return _$result;
  }
}
