// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'business_report_response.dart';

class _$BusinessReportResponse extends BusinessReportResponse {
  @override
  final String id;
  @override
  final String businessId;
  @override
  final String reporterId;
  @override
  final String reason;
  @override
  final String status;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;
  @override
  final String? businessName;
  @override
  final BuiltList<BusinessReportMessageResponse>? messages;
  @override
  final int? reportCount;
  @override
  final bool? isRepeat;

  factory _$BusinessReportResponse(
          [void Function(BusinessReportResponseBuilder)? updates]) =>
      (BusinessReportResponseBuilder()..update(updates))._build();

  _$BusinessReportResponse._({
    required this.id,
    required this.businessId,
    required this.reporterId,
    required this.reason,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.businessName,
    this.messages,
    this.reportCount,
    this.isRepeat,
  }) : super._();

  @override
  BusinessReportResponse rebuild(
          void Function(BusinessReportResponseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  BusinessReportResponseBuilder toBuilder() =>
      BusinessReportResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is BusinessReportResponse &&
        id == other.id &&
        businessId == other.businessId &&
        reporterId == other.reporterId &&
        reason == other.reason &&
        status == other.status &&
        createdAt == other.createdAt &&
        updatedAt == other.updatedAt &&
        businessName == other.businessName &&
        messages == other.messages &&
        reportCount == other.reportCount &&
        isRepeat == other.isRepeat;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, businessId.hashCode);
    _$hash = $jc(_$hash, reporterId.hashCode);
    _$hash = $jc(_$hash, reason.hashCode);
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jc(_$hash, createdAt.hashCode);
    _$hash = $jc(_$hash, updatedAt.hashCode);
    _$hash = $jc(_$hash, businessName.hashCode);
    _$hash = $jc(_$hash, messages.hashCode);
    _$hash = $jc(_$hash, reportCount.hashCode);
    _$hash = $jc(_$hash, isRepeat.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'BusinessReportResponse')..add('id', id))
        .toString();
  }
}

class BusinessReportResponseBuilder
    implements Builder<BusinessReportResponse, BusinessReportResponseBuilder> {
  _$BusinessReportResponse? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _businessId;
  String? get businessId => _$this._businessId;
  set businessId(String? businessId) => _$this._businessId = businessId;

  String? _reporterId;
  String? get reporterId => _$this._reporterId;
  set reporterId(String? reporterId) => _$this._reporterId = reporterId;

  String? _reason;
  String? get reason => _$this._reason;
  set reason(String? reason) => _$this._reason = reason;

  String? _status;
  String? get status => _$this._status;
  set status(String? status) => _$this._status = status;

  DateTime? _createdAt;
  DateTime? get createdAt => _$this._createdAt;
  set createdAt(DateTime? createdAt) => _$this._createdAt = createdAt;

  DateTime? _updatedAt;
  DateTime? get updatedAt => _$this._updatedAt;
  set updatedAt(DateTime? updatedAt) => _$this._updatedAt = updatedAt;

  String? _businessName;
  String? get businessName => _$this._businessName;
  set businessName(String? businessName) => _$this._businessName = businessName;

  ListBuilder<BusinessReportMessageResponse>? _messages;
  ListBuilder<BusinessReportMessageResponse> get messages =>
      _$this._messages ??= ListBuilder<BusinessReportMessageResponse>();
  set messages(ListBuilder<BusinessReportMessageResponse>? messages) =>
      _$this._messages = messages;

  int? _reportCount;
  int? get reportCount => _$this._reportCount;
  set reportCount(int? reportCount) => _$this._reportCount = reportCount;

  bool? _isRepeat;
  bool? get isRepeat => _$this._isRepeat;
  set isRepeat(bool? isRepeat) => _$this._isRepeat = isRepeat;

  BusinessReportResponseBuilder() {
    BusinessReportResponse._defaults(this);
  }

  BusinessReportResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _businessId = $v.businessId;
      _reporterId = $v.reporterId;
      _reason = $v.reason;
      _status = $v.status;
      _createdAt = $v.createdAt;
      _updatedAt = $v.updatedAt;
      _businessName = $v.businessName;
      _messages = $v.messages?.toBuilder();
      _reportCount = $v.reportCount;
      _isRepeat = $v.isRepeat;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(BusinessReportResponse other) {
    _$v = other as _$BusinessReportResponse;
  }

  @override
  void update(void Function(BusinessReportResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  BusinessReportResponse build() => _build();

  _$BusinessReportResponse _build() {
    _$BusinessReportResponse _$result;
    try {
      _$result = _$v ??
          _$BusinessReportResponse._(
            id: BuiltValueNullFieldError.checkNotNull(
                id, r'BusinessReportResponse', 'id'),
            businessId: BuiltValueNullFieldError.checkNotNull(
                businessId, r'BusinessReportResponse', 'businessId'),
            reporterId: BuiltValueNullFieldError.checkNotNull(
                reporterId, r'BusinessReportResponse', 'reporterId'),
            reason: BuiltValueNullFieldError.checkNotNull(
                reason, r'BusinessReportResponse', 'reason'),
            status: BuiltValueNullFieldError.checkNotNull(
                status, r'BusinessReportResponse', 'status'),
            createdAt: BuiltValueNullFieldError.checkNotNull(
                createdAt, r'BusinessReportResponse', 'createdAt'),
            updatedAt: BuiltValueNullFieldError.checkNotNull(
                updatedAt, r'BusinessReportResponse', 'updatedAt'),
            businessName: businessName,
            messages: _messages?.build(),
            reportCount: reportCount,
            isRepeat: isRepeat,
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'messages';
        _messages?.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'BusinessReportResponse', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
