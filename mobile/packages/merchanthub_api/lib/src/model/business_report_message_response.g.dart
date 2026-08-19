// GENERATED CODE - DO NOT MODIFY BY HAND
part of 'business_report_message_response.dart';

class _$BusinessReportMessageResponse extends BusinessReportMessageResponse {
  @override
  final String id;
  @override
  final String reportId;
  @override
  final String authorId;
  @override
  final String body;
  @override
  final DateTime createdAt;

  factory _$BusinessReportMessageResponse(
          [void Function(BusinessReportMessageResponseBuilder)? updates]) =>
      (BusinessReportMessageResponseBuilder()..update(updates))._build();

  _$BusinessReportMessageResponse._({
    required this.id,
    required this.reportId,
    required this.authorId,
    required this.body,
    required this.createdAt,
  }) : super._();

  @override
  BusinessReportMessageResponse rebuild(
          void Function(BusinessReportMessageResponseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  BusinessReportMessageResponseBuilder toBuilder() =>
      BusinessReportMessageResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is BusinessReportMessageResponse &&
        id == other.id &&
        reportId == other.reportId &&
        authorId == other.authorId &&
        body == other.body &&
        createdAt == other.createdAt;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, reportId.hashCode);
    _$hash = $jc(_$hash, authorId.hashCode);
    _$hash = $jc(_$hash, body.hashCode);
    _$hash = $jc(_$hash, createdAt.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'BusinessReportMessageResponse')..add('id', id)).toString();
  }
}

class BusinessReportMessageResponseBuilder
    implements Builder<BusinessReportMessageResponse, BusinessReportMessageResponseBuilder> {
  _$BusinessReportMessageResponse? _$v;
  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;
  String? _reportId;
  String? get reportId => _$this._reportId;
  set reportId(String? reportId) => _$this._reportId = reportId;
  String? _authorId;
  String? get authorId => _$this._authorId;
  set authorId(String? authorId) => _$this._authorId = authorId;
  String? _body;
  String? get body => _$this._body;
  set body(String? body) => _$this._body = body;
  DateTime? _createdAt;
  DateTime? get createdAt => _$this._createdAt;
  set createdAt(DateTime? createdAt) => _$this._createdAt = createdAt;

  BusinessReportMessageResponseBuilder() {
    BusinessReportMessageResponse._defaults(this);
  }

  BusinessReportMessageResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _reportId = $v.reportId;
      _authorId = $v.authorId;
      _body = $v.body;
      _createdAt = $v.createdAt;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(BusinessReportMessageResponse other) {
    _$v = other as _$BusinessReportMessageResponse;
  }

  @override
  void update(void Function(BusinessReportMessageResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  BusinessReportMessageResponse build() => _build();

  _$BusinessReportMessageResponse _build() {
    final _$result = _$v ??
        _$BusinessReportMessageResponse._(
          id: BuiltValueNullFieldError.checkNotNull(id, r'BusinessReportMessageResponse', 'id'),
          reportId: BuiltValueNullFieldError.checkNotNull(reportId, r'BusinessReportMessageResponse', 'reportId'),
          authorId: BuiltValueNullFieldError.checkNotNull(authorId, r'BusinessReportMessageResponse', 'authorId'),
          body: BuiltValueNullFieldError.checkNotNull(body, r'BusinessReportMessageResponse', 'body'),
          createdAt: BuiltValueNullFieldError.checkNotNull(createdAt, r'BusinessReportMessageResponse', 'createdAt'),
        );
    replace(_$result);
    return _$result;
  }
}
