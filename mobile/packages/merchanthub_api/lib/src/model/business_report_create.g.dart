// GENERATED CODE - DO NOT MODIFY BY HAND
part of 'business_report_create.dart';

class _$BusinessReportCreate extends BusinessReportCreate {
  @override
  final String reason;

  factory _$BusinessReportCreate(
          [void Function(BusinessReportCreateBuilder)? updates]) =>
      (BusinessReportCreateBuilder()..update(updates))._build();

  _$BusinessReportCreate._({required this.reason}) : super._();

  @override
  BusinessReportCreate rebuild(void Function(BusinessReportCreateBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  BusinessReportCreateBuilder toBuilder() => BusinessReportCreateBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is BusinessReportCreate && reason == other.reason;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, reason.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'BusinessReportCreate')..add('reason', reason)).toString();
  }
}

class BusinessReportCreateBuilder
    implements Builder<BusinessReportCreate, BusinessReportCreateBuilder> {
  _$BusinessReportCreate? _$v;
  String? _reason;
  String? get reason => _$this._reason;
  set reason(String? reason) => _$this._reason = reason;

  BusinessReportCreateBuilder() {
    BusinessReportCreate._defaults(this);
  }

  BusinessReportCreateBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _reason = $v.reason;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(BusinessReportCreate other) {
    _$v = other as _$BusinessReportCreate;
  }

  @override
  void update(void Function(BusinessReportCreateBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  BusinessReportCreate build() => _build();

  _$BusinessReportCreate _build() {
    final _$result = _$v ??
        _$BusinessReportCreate._(
          reason: BuiltValueNullFieldError.checkNotNull(reason, r'BusinessReportCreate', 'reason'),
        );
    replace(_$result);
    return _$result;
  }
}
