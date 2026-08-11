// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_analysis_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$AIAnalysisResponse extends AIAnalysisResponse {
  @override
  final String id;
  @override
  final String analysisType;
  @override
  final Sentiment? sentiment;
  @override
  final String? summary;
  @override
  final BuiltList<String>? positives;
  @override
  final BuiltList<String>? complaints;
  @override
  final String? suggestedResponse;
  @override
  final JsonObject? imageInsights;
  @override
  final String provider;
  @override
  final bool? degraded;

  factory _$AIAnalysisResponse(
          [void Function(AIAnalysisResponseBuilder)? updates]) =>
      (AIAnalysisResponseBuilder()..update(updates))._build();

  _$AIAnalysisResponse._(
      {required this.id,
      required this.analysisType,
      this.sentiment,
      this.summary,
      this.positives,
      this.complaints,
      this.suggestedResponse,
      this.imageInsights,
      required this.provider,
      this.degraded})
      : super._();
  @override
  AIAnalysisResponse rebuild(
          void Function(AIAnalysisResponseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  AIAnalysisResponseBuilder toBuilder() =>
      AIAnalysisResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is AIAnalysisResponse &&
        id == other.id &&
        analysisType == other.analysisType &&
        sentiment == other.sentiment &&
        summary == other.summary &&
        positives == other.positives &&
        complaints == other.complaints &&
        suggestedResponse == other.suggestedResponse &&
        imageInsights == other.imageInsights &&
        provider == other.provider &&
        degraded == other.degraded;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, analysisType.hashCode);
    _$hash = $jc(_$hash, sentiment.hashCode);
    _$hash = $jc(_$hash, summary.hashCode);
    _$hash = $jc(_$hash, positives.hashCode);
    _$hash = $jc(_$hash, complaints.hashCode);
    _$hash = $jc(_$hash, suggestedResponse.hashCode);
    _$hash = $jc(_$hash, imageInsights.hashCode);
    _$hash = $jc(_$hash, provider.hashCode);
    _$hash = $jc(_$hash, degraded.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'AIAnalysisResponse')
          ..add('id', id)
          ..add('analysisType', analysisType)
          ..add('sentiment', sentiment)
          ..add('summary', summary)
          ..add('positives', positives)
          ..add('complaints', complaints)
          ..add('suggestedResponse', suggestedResponse)
          ..add('imageInsights', imageInsights)
          ..add('provider', provider)
          ..add('degraded', degraded))
        .toString();
  }
}

class AIAnalysisResponseBuilder
    implements Builder<AIAnalysisResponse, AIAnalysisResponseBuilder> {
  _$AIAnalysisResponse? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _analysisType;
  String? get analysisType => _$this._analysisType;
  set analysisType(String? analysisType) => _$this._analysisType = analysisType;

  Sentiment? _sentiment;
  Sentiment? get sentiment => _$this._sentiment;
  set sentiment(Sentiment? sentiment) => _$this._sentiment = sentiment;

  String? _summary;
  String? get summary => _$this._summary;
  set summary(String? summary) => _$this._summary = summary;

  ListBuilder<String>? _positives;
  ListBuilder<String> get positives =>
      _$this._positives ??= ListBuilder<String>();
  set positives(ListBuilder<String>? positives) =>
      _$this._positives = positives;

  ListBuilder<String>? _complaints;
  ListBuilder<String> get complaints =>
      _$this._complaints ??= ListBuilder<String>();
  set complaints(ListBuilder<String>? complaints) =>
      _$this._complaints = complaints;

  String? _suggestedResponse;
  String? get suggestedResponse => _$this._suggestedResponse;
  set suggestedResponse(String? suggestedResponse) =>
      _$this._suggestedResponse = suggestedResponse;

  JsonObject? _imageInsights;
  JsonObject? get imageInsights => _$this._imageInsights;
  set imageInsights(JsonObject? imageInsights) =>
      _$this._imageInsights = imageInsights;

  String? _provider;
  String? get provider => _$this._provider;
  set provider(String? provider) => _$this._provider = provider;

  bool? _degraded;
  bool? get degraded => _$this._degraded;
  set degraded(bool? degraded) => _$this._degraded = degraded;

  AIAnalysisResponseBuilder() {
    AIAnalysisResponse._defaults(this);
  }

  AIAnalysisResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _analysisType = $v.analysisType;
      _sentiment = $v.sentiment;
      _summary = $v.summary;
      _positives = $v.positives?.toBuilder();
      _complaints = $v.complaints?.toBuilder();
      _suggestedResponse = $v.suggestedResponse;
      _imageInsights = $v.imageInsights;
      _provider = $v.provider;
      _degraded = $v.degraded;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(AIAnalysisResponse other) {
    _$v = other as _$AIAnalysisResponse;
  }

  @override
  void update(void Function(AIAnalysisResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  AIAnalysisResponse build() => _build();

  _$AIAnalysisResponse _build() {
    _$AIAnalysisResponse _$result;
    try {
      _$result = _$v ??
          _$AIAnalysisResponse._(
            id: BuiltValueNullFieldError.checkNotNull(
                id, r'AIAnalysisResponse', 'id'),
            analysisType: BuiltValueNullFieldError.checkNotNull(
                analysisType, r'AIAnalysisResponse', 'analysisType'),
            sentiment: sentiment,
            summary: summary,
            positives: _positives?.build(),
            complaints: _complaints?.build(),
            suggestedResponse: suggestedResponse,
            imageInsights: imageInsights,
            provider: BuiltValueNullFieldError.checkNotNull(
                provider, r'AIAnalysisResponse', 'provider'),
            degraded: degraded,
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'positives';
        _positives?.build();
        _$failedField = 'complaints';
        _complaints?.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'AIAnalysisResponse', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
