// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'review_report_create.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ReviewReportCreate extends ReviewReportCreate {
  @override
  final String reason;

  factory _$ReviewReportCreate(
          [void Function(ReviewReportCreateBuilder)? updates]) =>
      (ReviewReportCreateBuilder()..update(updates))._build();

  _$ReviewReportCreate._({required this.reason}) : super._();
  @override
  ReviewReportCreate rebuild(
          void Function(ReviewReportCreateBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ReviewReportCreateBuilder toBuilder() =>
      ReviewReportCreateBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ReviewReportCreate && reason == other.reason;
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
    return (newBuiltValueToStringHelper(r'ReviewReportCreate')
          ..add('reason', reason))
        .toString();
  }
}

class ReviewReportCreateBuilder
    implements Builder<ReviewReportCreate, ReviewReportCreateBuilder> {
  _$ReviewReportCreate? _$v;

  String? _reason;
  String? get reason => _$this._reason;
  set reason(String? reason) => _$this._reason = reason;

  ReviewReportCreateBuilder() {
    ReviewReportCreate._defaults(this);
  }

  ReviewReportCreateBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _reason = $v.reason;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ReviewReportCreate other) {
    _$v = other as _$ReviewReportCreate;
  }

  @override
  void update(void Function(ReviewReportCreateBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ReviewReportCreate build() => _build();

  _$ReviewReportCreate _build() {
    final _$result = _$v ??
        _$ReviewReportCreate._(
          reason: BuiltValueNullFieldError.checkNotNull(
              reason, r'ReviewReportCreate', 'reason'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
