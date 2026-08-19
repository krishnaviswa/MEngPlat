// GENERATED CODE - DO NOT MODIFY BY HAND
part of 'support_ticket_response.dart';

class _$SupportTicketResponse extends SupportTicketResponse {
  @override
  final String id;
  @override
  final String name;
  @override
  final String phone;
  @override
  final String issue;
  @override
  final String? businessId;
  @override
  final String? reporterId;
  @override
  final String status;
  @override
  final String? adminResponse;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;

  factory _$SupportTicketResponse(
          [void Function(SupportTicketResponseBuilder)? updates]) =>
      (SupportTicketResponseBuilder()..update(updates))._build();

  _$SupportTicketResponse._({
    required this.id,
    required this.name,
    required this.phone,
    required this.issue,
    this.businessId,
    this.reporterId,
    required this.status,
    this.adminResponse,
    required this.createdAt,
    required this.updatedAt,
  }) : super._();

  @override
  SupportTicketResponse rebuild(void Function(SupportTicketResponseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  SupportTicketResponseBuilder toBuilder() => SupportTicketResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is SupportTicketResponse &&
        id == other.id &&
        name == other.name &&
        phone == other.phone &&
        issue == other.issue &&
        businessId == other.businessId &&
        reporterId == other.reporterId &&
        status == other.status &&
        adminResponse == other.adminResponse &&
        createdAt == other.createdAt &&
        updatedAt == other.updatedAt;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jc(_$hash, phone.hashCode);
    _$hash = $jc(_$hash, issue.hashCode);
    _$hash = $jc(_$hash, businessId.hashCode);
    _$hash = $jc(_$hash, reporterId.hashCode);
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jc(_$hash, adminResponse.hashCode);
    _$hash = $jc(_$hash, createdAt.hashCode);
    _$hash = $jc(_$hash, updatedAt.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'SupportTicketResponse')
          ..add('id', id)
          ..add('name', name)
          ..add('status', status))
        .toString();
  }
}

class SupportTicketResponseBuilder
    implements Builder<SupportTicketResponse, SupportTicketResponseBuilder> {
  _$SupportTicketResponse? _$v;
  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;
  String? _name;
  String? get name => _$this._name;
  set name(String? name) => _$this._name = name;
  String? _phone;
  String? get phone => _$this._phone;
  set phone(String? phone) => _$this._phone = phone;
  String? _issue;
  String? get issue => _$this._issue;
  set issue(String? issue) => _$this._issue = issue;
  String? _businessId;
  String? get businessId => _$this._businessId;
  set businessId(String? businessId) => _$this._businessId = businessId;
  String? _reporterId;
  String? get reporterId => _$this._reporterId;
  set reporterId(String? reporterId) => _$this._reporterId = reporterId;
  String? _status;
  String? get status => _$this._status;
  set status(String? status) => _$this._status = status;
  String? _adminResponse;
  String? get adminResponse => _$this._adminResponse;
  set adminResponse(String? adminResponse) => _$this._adminResponse = adminResponse;
  DateTime? _createdAt;
  DateTime? get createdAt => _$this._createdAt;
  set createdAt(DateTime? createdAt) => _$this._createdAt = createdAt;
  DateTime? _updatedAt;
  DateTime? get updatedAt => _$this._updatedAt;
  set updatedAt(DateTime? updatedAt) => _$this._updatedAt = updatedAt;

  SupportTicketResponseBuilder() {
    SupportTicketResponse._defaults(this);
  }

  SupportTicketResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _name = $v.name;
      _phone = $v.phone;
      _issue = $v.issue;
      _businessId = $v.businessId;
      _reporterId = $v.reporterId;
      _status = $v.status;
      _adminResponse = $v.adminResponse;
      _createdAt = $v.createdAt;
      _updatedAt = $v.updatedAt;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(SupportTicketResponse other) {
    _$v = other as _$SupportTicketResponse;
  }

  @override
  void update(void Function(SupportTicketResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  SupportTicketResponse build() => _build();

  _$SupportTicketResponse _build() {
    final _$result = _$v ??
        _$SupportTicketResponse._(
          id: BuiltValueNullFieldError.checkNotNull(id, r'SupportTicketResponse', 'id'),
          name: BuiltValueNullFieldError.checkNotNull(name, r'SupportTicketResponse', 'name'),
          phone: BuiltValueNullFieldError.checkNotNull(phone, r'SupportTicketResponse', 'phone'),
          issue: BuiltValueNullFieldError.checkNotNull(issue, r'SupportTicketResponse', 'issue'),
          businessId: businessId,
          reporterId: reporterId,
          status: BuiltValueNullFieldError.checkNotNull(status, r'SupportTicketResponse', 'status'),
          adminResponse: adminResponse,
          createdAt: BuiltValueNullFieldError.checkNotNull(createdAt, r'SupportTicketResponse', 'createdAt'),
          updatedAt: BuiltValueNullFieldError.checkNotNull(updatedAt, r'SupportTicketResponse', 'updatedAt'),
        );
    replace(_$result);
    return _$result;
  }
}
