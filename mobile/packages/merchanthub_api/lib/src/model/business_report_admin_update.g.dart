// GENERATED CODE - DO NOT MODIFY BY HAND
part of 'business_report_admin_update.dart';

class _$BusinessReportAdminUpdate extends BusinessReportAdminUpdate {
  @override
  final String status;

  factory _$BusinessReportAdminUpdate(
          [void Function(BusinessReportAdminUpdateBuilder)? updates]) =>
      (BusinessReportAdminUpdateBuilder()..update(updates))._build();

  _$BusinessReportAdminUpdate._({required this.status}) : super._();

  @override
  BusinessReportAdminUpdate rebuild(
          void Function(BusinessReportAdminUpdateBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  BusinessReportAdminUpdateBuilder toBuilder() =>
      BusinessReportAdminUpdateBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is BusinessReportAdminUpdate && status == other.status;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'BusinessReportAdminUpdate')..add('status', status)).toString();
  }
}

class BusinessReportAdminUpdateBuilder
    implements Builder<BusinessReportAdminUpdate, BusinessReportAdminUpdateBuilder> {
  _$BusinessReportAdminUpdate? _$v;
  String? _status;
  String? get status => _$this._status;
  set status(String? status) => _$this._status = status;

  BusinessReportAdminUpdateBuilder() {
    BusinessReportAdminUpdate._defaults(this);
  }

  BusinessReportAdminUpdateBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _status = $v.status;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(BusinessReportAdminUpdate other) {
    _$v = other as _$BusinessReportAdminUpdate;
  }

  @override
  void update(void Function(BusinessReportAdminUpdateBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  BusinessReportAdminUpdate build() => _build();

  _$BusinessReportAdminUpdate _build() {
    final _$result = _$v ??
        _$BusinessReportAdminUpdate._(
          status: BuiltValueNullFieldError.checkNotNull(status, r'BusinessReportAdminUpdate', 'status'),
        );
    replace(_$result);
    return _$result;
  }
}
