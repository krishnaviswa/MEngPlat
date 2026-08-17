// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mock_complete_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$MockCompleteRequest extends MockCompleteRequest {
  @override
  final String providerOrderId;
  @override
  final String outcome;

  factory _$MockCompleteRequest(
          [void Function(MockCompleteRequestBuilder)? updates]) =>
      (MockCompleteRequestBuilder()..update(updates))._build();

  _$MockCompleteRequest._(
      {required this.providerOrderId, required this.outcome})
      : super._();
  @override
  MockCompleteRequest rebuild(
          void Function(MockCompleteRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  MockCompleteRequestBuilder toBuilder() =>
      MockCompleteRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is MockCompleteRequest &&
        providerOrderId == other.providerOrderId &&
        outcome == other.outcome;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, providerOrderId.hashCode);
    _$hash = $jc(_$hash, outcome.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'MockCompleteRequest')
          ..add('providerOrderId', providerOrderId)
          ..add('outcome', outcome))
        .toString();
  }
}

class MockCompleteRequestBuilder
    implements Builder<MockCompleteRequest, MockCompleteRequestBuilder> {
  _$MockCompleteRequest? _$v;

  String? _providerOrderId;
  String? get providerOrderId => _$this._providerOrderId;
  set providerOrderId(String? providerOrderId) =>
      _$this._providerOrderId = providerOrderId;

  String? _outcome;
  String? get outcome => _$this._outcome;
  set outcome(String? outcome) => _$this._outcome = outcome;

  MockCompleteRequestBuilder() {
    MockCompleteRequest._defaults(this);
  }

  MockCompleteRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _providerOrderId = $v.providerOrderId;
      _outcome = $v.outcome;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(MockCompleteRequest other) {
    _$v = other as _$MockCompleteRequest;
  }

  @override
  void update(void Function(MockCompleteRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  MockCompleteRequest build() => _build();

  _$MockCompleteRequest _build() {
    final _$result = _$v ??
        _$MockCompleteRequest._(
          providerOrderId: BuiltValueNullFieldError.checkNotNull(
              providerOrderId, r'MockCompleteRequest', 'providerOrderId'),
          outcome: BuiltValueNullFieldError.checkNotNull(
              outcome, r'MockCompleteRequest', 'outcome'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
