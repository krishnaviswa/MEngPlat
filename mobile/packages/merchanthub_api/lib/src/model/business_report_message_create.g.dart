// GENERATED CODE - DO NOT MODIFY BY HAND
part of 'business_report_message_create.dart';

class _$BusinessReportMessageCreate extends BusinessReportMessageCreate {
  @override
  final String body;

  factory _$BusinessReportMessageCreate(
          [void Function(BusinessReportMessageCreateBuilder)? updates]) =>
      (BusinessReportMessageCreateBuilder()..update(updates))._build();

  _$BusinessReportMessageCreate._({required this.body}) : super._();

  @override
  BusinessReportMessageCreate rebuild(
          void Function(BusinessReportMessageCreateBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  BusinessReportMessageCreateBuilder toBuilder() =>
      BusinessReportMessageCreateBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is BusinessReportMessageCreate && body == other.body;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, body.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'BusinessReportMessageCreate')..add('body', body)).toString();
  }
}

class BusinessReportMessageCreateBuilder
    implements Builder<BusinessReportMessageCreate, BusinessReportMessageCreateBuilder> {
  _$BusinessReportMessageCreate? _$v;
  String? _body;
  String? get body => _$this._body;
  set body(String? body) => _$this._body = body;

  BusinessReportMessageCreateBuilder() {
    BusinessReportMessageCreate._defaults(this);
  }

  BusinessReportMessageCreateBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _body = $v.body;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(BusinessReportMessageCreate other) {
    _$v = other as _$BusinessReportMessageCreate;
  }

  @override
  void update(void Function(BusinessReportMessageCreateBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  BusinessReportMessageCreate build() => _build();

  _$BusinessReportMessageCreate _build() {
    final _$result = _$v ??
        _$BusinessReportMessageCreate._(
          body: BuiltValueNullFieldError.checkNotNull(body, r'BusinessReportMessageCreate', 'body'),
        );
    replace(_$result);
    return _$result;
  }
}
