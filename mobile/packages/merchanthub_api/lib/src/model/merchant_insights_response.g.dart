// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'merchant_insights_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$MerchantInsightsResponse extends MerchantInsightsResponse {
  @override
  final String businessId;
  @override
  final String? merchantSummary;
  @override
  final BuiltList<String> frequentlyMentionedPositives;
  @override
  final BuiltList<String> frequentlyMentionedComplaints;
  @override
  final BuiltList<String> suggestedResponses;
  @override
  final BuiltList<JsonObject> monthlyTrends;
  @override
  final BuiltMap<String, int> sentimentBreakdown;
  @override
  final bool? degraded;

  factory _$MerchantInsightsResponse(
          [void Function(MerchantInsightsResponseBuilder)? updates]) =>
      (MerchantInsightsResponseBuilder()..update(updates))._build();

  _$MerchantInsightsResponse._(
      {required this.businessId,
      this.merchantSummary,
      required this.frequentlyMentionedPositives,
      required this.frequentlyMentionedComplaints,
      required this.suggestedResponses,
      required this.monthlyTrends,
      required this.sentimentBreakdown,
      this.degraded})
      : super._();
  @override
  MerchantInsightsResponse rebuild(
          void Function(MerchantInsightsResponseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  MerchantInsightsResponseBuilder toBuilder() =>
      MerchantInsightsResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is MerchantInsightsResponse &&
        businessId == other.businessId &&
        merchantSummary == other.merchantSummary &&
        frequentlyMentionedPositives == other.frequentlyMentionedPositives &&
        frequentlyMentionedComplaints == other.frequentlyMentionedComplaints &&
        suggestedResponses == other.suggestedResponses &&
        monthlyTrends == other.monthlyTrends &&
        sentimentBreakdown == other.sentimentBreakdown &&
        degraded == other.degraded;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, businessId.hashCode);
    _$hash = $jc(_$hash, merchantSummary.hashCode);
    _$hash = $jc(_$hash, frequentlyMentionedPositives.hashCode);
    _$hash = $jc(_$hash, frequentlyMentionedComplaints.hashCode);
    _$hash = $jc(_$hash, suggestedResponses.hashCode);
    _$hash = $jc(_$hash, monthlyTrends.hashCode);
    _$hash = $jc(_$hash, sentimentBreakdown.hashCode);
    _$hash = $jc(_$hash, degraded.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'MerchantInsightsResponse')
          ..add('businessId', businessId)
          ..add('merchantSummary', merchantSummary)
          ..add('frequentlyMentionedPositives', frequentlyMentionedPositives)
          ..add('frequentlyMentionedComplaints', frequentlyMentionedComplaints)
          ..add('suggestedResponses', suggestedResponses)
          ..add('monthlyTrends', monthlyTrends)
          ..add('sentimentBreakdown', sentimentBreakdown)
          ..add('degraded', degraded))
        .toString();
  }
}

class MerchantInsightsResponseBuilder
    implements
        Builder<MerchantInsightsResponse, MerchantInsightsResponseBuilder> {
  _$MerchantInsightsResponse? _$v;

  String? _businessId;
  String? get businessId => _$this._businessId;
  set businessId(String? businessId) => _$this._businessId = businessId;

  String? _merchantSummary;
  String? get merchantSummary => _$this._merchantSummary;
  set merchantSummary(String? merchantSummary) =>
      _$this._merchantSummary = merchantSummary;

  ListBuilder<String>? _frequentlyMentionedPositives;
  ListBuilder<String> get frequentlyMentionedPositives =>
      _$this._frequentlyMentionedPositives ??= ListBuilder<String>();
  set frequentlyMentionedPositives(
          ListBuilder<String>? frequentlyMentionedPositives) =>
      _$this._frequentlyMentionedPositives = frequentlyMentionedPositives;

  ListBuilder<String>? _frequentlyMentionedComplaints;
  ListBuilder<String> get frequentlyMentionedComplaints =>
      _$this._frequentlyMentionedComplaints ??= ListBuilder<String>();
  set frequentlyMentionedComplaints(
          ListBuilder<String>? frequentlyMentionedComplaints) =>
      _$this._frequentlyMentionedComplaints = frequentlyMentionedComplaints;

  ListBuilder<String>? _suggestedResponses;
  ListBuilder<String> get suggestedResponses =>
      _$this._suggestedResponses ??= ListBuilder<String>();
  set suggestedResponses(ListBuilder<String>? suggestedResponses) =>
      _$this._suggestedResponses = suggestedResponses;

  ListBuilder<JsonObject>? _monthlyTrends;
  ListBuilder<JsonObject> get monthlyTrends =>
      _$this._monthlyTrends ??= ListBuilder<JsonObject>();
  set monthlyTrends(ListBuilder<JsonObject>? monthlyTrends) =>
      _$this._monthlyTrends = monthlyTrends;

  MapBuilder<String, int>? _sentimentBreakdown;
  MapBuilder<String, int> get sentimentBreakdown =>
      _$this._sentimentBreakdown ??= MapBuilder<String, int>();
  set sentimentBreakdown(MapBuilder<String, int>? sentimentBreakdown) =>
      _$this._sentimentBreakdown = sentimentBreakdown;

  bool? _degraded;
  bool? get degraded => _$this._degraded;
  set degraded(bool? degraded) => _$this._degraded = degraded;

  MerchantInsightsResponseBuilder() {
    MerchantInsightsResponse._defaults(this);
  }

  MerchantInsightsResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _businessId = $v.businessId;
      _merchantSummary = $v.merchantSummary;
      _frequentlyMentionedPositives =
          $v.frequentlyMentionedPositives.toBuilder();
      _frequentlyMentionedComplaints =
          $v.frequentlyMentionedComplaints.toBuilder();
      _suggestedResponses = $v.suggestedResponses.toBuilder();
      _monthlyTrends = $v.monthlyTrends.toBuilder();
      _sentimentBreakdown = $v.sentimentBreakdown.toBuilder();
      _degraded = $v.degraded;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(MerchantInsightsResponse other) {
    _$v = other as _$MerchantInsightsResponse;
  }

  @override
  void update(void Function(MerchantInsightsResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  MerchantInsightsResponse build() => _build();

  _$MerchantInsightsResponse _build() {
    _$MerchantInsightsResponse _$result;
    try {
      _$result = _$v ??
          _$MerchantInsightsResponse._(
            businessId: BuiltValueNullFieldError.checkNotNull(
                businessId, r'MerchantInsightsResponse', 'businessId'),
            merchantSummary: merchantSummary,
            frequentlyMentionedPositives: frequentlyMentionedPositives.build(),
            frequentlyMentionedComplaints:
                frequentlyMentionedComplaints.build(),
            suggestedResponses: suggestedResponses.build(),
            monthlyTrends: monthlyTrends.build(),
            sentimentBreakdown: sentimentBreakdown.build(),
            degraded: degraded,
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'frequentlyMentionedPositives';
        frequentlyMentionedPositives.build();
        _$failedField = 'frequentlyMentionedComplaints';
        frequentlyMentionedComplaints.build();
        _$failedField = 'suggestedResponses';
        suggestedResponses.build();
        _$failedField = 'monthlyTrends';
        monthlyTrends.build();
        _$failedField = 'sentimentBreakdown';
        sentimentBreakdown.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'MerchantInsightsResponse', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
