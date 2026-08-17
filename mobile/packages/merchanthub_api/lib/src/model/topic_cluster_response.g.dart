// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'topic_cluster_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$TopicClusterResponse extends TopicClusterResponse {
  @override
  final String businessId;
  @override
  final BuiltList<TopicItem>? topics;
  @override
  final bool? degraded;
  @override
  final bool? insufficientData;
  @override
  final bool? unavailable;

  factory _$TopicClusterResponse(
          [void Function(TopicClusterResponseBuilder)? updates]) =>
      (TopicClusterResponseBuilder()..update(updates))._build();

  _$TopicClusterResponse._(
      {required this.businessId,
      this.topics,
      this.degraded,
      this.insufficientData,
      this.unavailable})
      : super._();
  @override
  TopicClusterResponse rebuild(
          void Function(TopicClusterResponseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  TopicClusterResponseBuilder toBuilder() =>
      TopicClusterResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is TopicClusterResponse &&
        businessId == other.businessId &&
        topics == other.topics &&
        degraded == other.degraded &&
        insufficientData == other.insufficientData &&
        unavailable == other.unavailable;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, businessId.hashCode);
    _$hash = $jc(_$hash, topics.hashCode);
    _$hash = $jc(_$hash, degraded.hashCode);
    _$hash = $jc(_$hash, insufficientData.hashCode);
    _$hash = $jc(_$hash, unavailable.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'TopicClusterResponse')
          ..add('businessId', businessId)
          ..add('topics', topics)
          ..add('degraded', degraded)
          ..add('insufficientData', insufficientData)
          ..add('unavailable', unavailable))
        .toString();
  }
}

class TopicClusterResponseBuilder
    implements Builder<TopicClusterResponse, TopicClusterResponseBuilder> {
  _$TopicClusterResponse? _$v;

  String? _businessId;
  String? get businessId => _$this._businessId;
  set businessId(String? businessId) => _$this._businessId = businessId;

  ListBuilder<TopicItem>? _topics;
  ListBuilder<TopicItem> get topics =>
      _$this._topics ??= ListBuilder<TopicItem>();
  set topics(ListBuilder<TopicItem>? topics) => _$this._topics = topics;

  bool? _degraded;
  bool? get degraded => _$this._degraded;
  set degraded(bool? degraded) => _$this._degraded = degraded;

  bool? _insufficientData;
  bool? get insufficientData => _$this._insufficientData;
  set insufficientData(bool? insufficientData) =>
      _$this._insufficientData = insufficientData;

  bool? _unavailable;
  bool? get unavailable => _$this._unavailable;
  set unavailable(bool? unavailable) => _$this._unavailable = unavailable;

  TopicClusterResponseBuilder() {
    TopicClusterResponse._defaults(this);
  }

  TopicClusterResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _businessId = $v.businessId;
      _topics = $v.topics?.toBuilder();
      _degraded = $v.degraded;
      _insufficientData = $v.insufficientData;
      _unavailable = $v.unavailable;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(TopicClusterResponse other) {
    _$v = other as _$TopicClusterResponse;
  }

  @override
  void update(void Function(TopicClusterResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  TopicClusterResponse build() => _build();

  _$TopicClusterResponse _build() {
    _$TopicClusterResponse _$result;
    try {
      _$result = _$v ??
          _$TopicClusterResponse._(
            businessId: BuiltValueNullFieldError.checkNotNull(
                businessId, r'TopicClusterResponse', 'businessId'),
            topics: _topics?.build(),
            degraded: degraded,
            insufficientData: insufficientData,
            unavailable: unavailable,
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'topics';
        _topics?.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'TopicClusterResponse', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
