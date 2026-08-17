// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'google_places_search_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$GooglePlacesSearchResponse extends GooglePlacesSearchResponse {
  @override
  final BuiltList<GooglePlaceCandidateResponse> candidates;

  factory _$GooglePlacesSearchResponse(
          [void Function(GooglePlacesSearchResponseBuilder)? updates]) =>
      (GooglePlacesSearchResponseBuilder()..update(updates))._build();

  _$GooglePlacesSearchResponse._({required this.candidates}) : super._();
  @override
  GooglePlacesSearchResponse rebuild(
          void Function(GooglePlacesSearchResponseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  GooglePlacesSearchResponseBuilder toBuilder() =>
      GooglePlacesSearchResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is GooglePlacesSearchResponse &&
        candidates == other.candidates;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, candidates.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'GooglePlacesSearchResponse')
          ..add('candidates', candidates))
        .toString();
  }
}

class GooglePlacesSearchResponseBuilder
    implements
        Builder<GooglePlacesSearchResponse, GooglePlacesSearchResponseBuilder> {
  _$GooglePlacesSearchResponse? _$v;

  ListBuilder<GooglePlaceCandidateResponse>? _candidates;
  ListBuilder<GooglePlaceCandidateResponse> get candidates =>
      _$this._candidates ??= ListBuilder<GooglePlaceCandidateResponse>();
  set candidates(ListBuilder<GooglePlaceCandidateResponse>? candidates) =>
      _$this._candidates = candidates;

  GooglePlacesSearchResponseBuilder() {
    GooglePlacesSearchResponse._defaults(this);
  }

  GooglePlacesSearchResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _candidates = $v.candidates.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(GooglePlacesSearchResponse other) {
    _$v = other as _$GooglePlacesSearchResponse;
  }

  @override
  void update(void Function(GooglePlacesSearchResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  GooglePlacesSearchResponse build() => _build();

  _$GooglePlacesSearchResponse _build() {
    _$GooglePlacesSearchResponse _$result;
    try {
      _$result = _$v ??
          _$GooglePlacesSearchResponse._(
            candidates: candidates.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'candidates';
        candidates.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'GooglePlacesSearchResponse', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
