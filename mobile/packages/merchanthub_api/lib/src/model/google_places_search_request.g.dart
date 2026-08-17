// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'google_places_search_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$GooglePlacesSearchRequest extends GooglePlacesSearchRequest {
  @override
  final String query;

  factory _$GooglePlacesSearchRequest(
          [void Function(GooglePlacesSearchRequestBuilder)? updates]) =>
      (GooglePlacesSearchRequestBuilder()..update(updates))._build();

  _$GooglePlacesSearchRequest._({required this.query}) : super._();
  @override
  GooglePlacesSearchRequest rebuild(
          void Function(GooglePlacesSearchRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  GooglePlacesSearchRequestBuilder toBuilder() =>
      GooglePlacesSearchRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is GooglePlacesSearchRequest && query == other.query;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, query.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'GooglePlacesSearchRequest')
          ..add('query', query))
        .toString();
  }
}

class GooglePlacesSearchRequestBuilder
    implements
        Builder<GooglePlacesSearchRequest, GooglePlacesSearchRequestBuilder> {
  _$GooglePlacesSearchRequest? _$v;

  String? _query;
  String? get query => _$this._query;
  set query(String? query) => _$this._query = query;

  GooglePlacesSearchRequestBuilder() {
    GooglePlacesSearchRequest._defaults(this);
  }

  GooglePlacesSearchRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _query = $v.query;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(GooglePlacesSearchRequest other) {
    _$v = other as _$GooglePlacesSearchRequest;
  }

  @override
  void update(void Function(GooglePlacesSearchRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  GooglePlacesSearchRequest build() => _build();

  _$GooglePlacesSearchRequest _build() {
    final _$result = _$v ??
        _$GooglePlacesSearchRequest._(
          query: BuiltValueNullFieldError.checkNotNull(
              query, r'GooglePlacesSearchRequest', 'query'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
