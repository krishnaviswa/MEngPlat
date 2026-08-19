// GENERATED CODE - DO NOT MODIFY BY HAND
part of 'support_ticket_create.dart';

class _$SupportTicketCreate extends SupportTicketCreate {
  @override
  final String name;
  @override
  final String phone;
  @override
  final String issue;
  @override
  final String? businessId;

  factory _$SupportTicketCreate(
          [void Function(SupportTicketCreateBuilder)? updates]) =>
      (SupportTicketCreateBuilder()..update(updates))._build();

  _$SupportTicketCreate._(
      {required this.name, required this.phone, required this.issue, this.businessId})
      : super._();

  @override
  SupportTicketCreate rebuild(
          void Function(SupportTicketCreateBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  SupportTicketCreateBuilder toBuilder() =>
      SupportTicketCreateBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is SupportTicketCreate &&
        name == other.name &&
        phone == other.phone &&
        issue == other.issue &&
        businessId == other.businessId;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jc(_$hash, phone.hashCode);
    _$hash = $jc(_$hash, issue.hashCode);
    _$hash = $jc(_$hash, businessId.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'SupportTicketCreate')
          ..add('name', name)
          ..add('phone', phone)
          ..add('issue', issue)
          ..add('businessId', businessId))
        .toString();
  }
}

class SupportTicketCreateBuilder
    implements Builder<SupportTicketCreate, SupportTicketCreateBuilder> {
  _$SupportTicketCreate? _$v;
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

  SupportTicketCreateBuilder() {
    SupportTicketCreate._defaults(this);
  }

  SupportTicketCreateBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _name = $v.name;
      _phone = $v.phone;
      _issue = $v.issue;
      _businessId = $v.businessId;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(SupportTicketCreate other) {
    _$v = other as _$SupportTicketCreate;
  }

  @override
  void update(void Function(SupportTicketCreateBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  SupportTicketCreate build() => _build();

  _$SupportTicketCreate _build() {
    final _$result = _$v ??
        _$SupportTicketCreate._(
          name: BuiltValueNullFieldError.checkNotNull(name, r'SupportTicketCreate', 'name'),
          phone: BuiltValueNullFieldError.checkNotNull(phone, r'SupportTicketCreate', 'phone'),
          issue: BuiltValueNullFieldError.checkNotNull(issue, r'SupportTicketCreate', 'issue'),
          businessId: businessId,
        );
    replace(_$result);
    return _$result;
  }
}
