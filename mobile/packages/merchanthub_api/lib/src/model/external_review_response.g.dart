// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'external_review_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ExternalReviewResponse extends ExternalReviewResponse {
  @override
  final String id;
  @override
  final String authorName;
  @override
  final String? authorPhotoUrl;
  @override
  final int rating;
  @override
  final String? body;
  @override
  final String source_;
  @override
  final String? sourceUrl;
  @override
  final DateTime? externalPostedAt;

  factory _$ExternalReviewResponse(
          [void Function(ExternalReviewResponseBuilder)? updates]) =>
      (ExternalReviewResponseBuilder()..update(updates))._build();

  _$ExternalReviewResponse._(
      {required this.id,
      required this.authorName,
      this.authorPhotoUrl,
      required this.rating,
      this.body,
      required this.source_,
      this.sourceUrl,
      this.externalPostedAt})
      : super._();
  @override
  ExternalReviewResponse rebuild(
          void Function(ExternalReviewResponseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ExternalReviewResponseBuilder toBuilder() =>
      ExternalReviewResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ExternalReviewResponse &&
        id == other.id &&
        authorName == other.authorName &&
        authorPhotoUrl == other.authorPhotoUrl &&
        rating == other.rating &&
        body == other.body &&
        source_ == other.source_ &&
        sourceUrl == other.sourceUrl &&
        externalPostedAt == other.externalPostedAt;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, authorName.hashCode);
    _$hash = $jc(_$hash, authorPhotoUrl.hashCode);
    _$hash = $jc(_$hash, rating.hashCode);
    _$hash = $jc(_$hash, body.hashCode);
    _$hash = $jc(_$hash, source_.hashCode);
    _$hash = $jc(_$hash, sourceUrl.hashCode);
    _$hash = $jc(_$hash, externalPostedAt.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ExternalReviewResponse')
          ..add('id', id)
          ..add('authorName', authorName)
          ..add('authorPhotoUrl', authorPhotoUrl)
          ..add('rating', rating)
          ..add('body', body)
          ..add('source_', source_)
          ..add('sourceUrl', sourceUrl)
          ..add('externalPostedAt', externalPostedAt))
        .toString();
  }
}

class ExternalReviewResponseBuilder
    implements Builder<ExternalReviewResponse, ExternalReviewResponseBuilder> {
  _$ExternalReviewResponse? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _authorName;
  String? get authorName => _$this._authorName;
  set authorName(String? authorName) => _$this._authorName = authorName;

  String? _authorPhotoUrl;
  String? get authorPhotoUrl => _$this._authorPhotoUrl;
  set authorPhotoUrl(String? authorPhotoUrl) =>
      _$this._authorPhotoUrl = authorPhotoUrl;

  int? _rating;
  int? get rating => _$this._rating;
  set rating(int? rating) => _$this._rating = rating;

  String? _body;
  String? get body => _$this._body;
  set body(String? body) => _$this._body = body;

  String? _source_;
  String? get source_ => _$this._source_;
  set source_(String? source_) => _$this._source_ = source_;

  String? _sourceUrl;
  String? get sourceUrl => _$this._sourceUrl;
  set sourceUrl(String? sourceUrl) => _$this._sourceUrl = sourceUrl;

  DateTime? _externalPostedAt;
  DateTime? get externalPostedAt => _$this._externalPostedAt;
  set externalPostedAt(DateTime? externalPostedAt) =>
      _$this._externalPostedAt = externalPostedAt;

  ExternalReviewResponseBuilder() {
    ExternalReviewResponse._defaults(this);
  }

  ExternalReviewResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _authorName = $v.authorName;
      _authorPhotoUrl = $v.authorPhotoUrl;
      _rating = $v.rating;
      _body = $v.body;
      _source_ = $v.source_;
      _sourceUrl = $v.sourceUrl;
      _externalPostedAt = $v.externalPostedAt;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ExternalReviewResponse other) {
    _$v = other as _$ExternalReviewResponse;
  }

  @override
  void update(void Function(ExternalReviewResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ExternalReviewResponse build() => _build();

  _$ExternalReviewResponse _build() {
    final _$result = _$v ??
        _$ExternalReviewResponse._(
          id: BuiltValueNullFieldError.checkNotNull(
              id, r'ExternalReviewResponse', 'id'),
          authorName: BuiltValueNullFieldError.checkNotNull(
              authorName, r'ExternalReviewResponse', 'authorName'),
          authorPhotoUrl: authorPhotoUrl,
          rating: BuiltValueNullFieldError.checkNotNull(
              rating, r'ExternalReviewResponse', 'rating'),
          body: body,
          source_: BuiltValueNullFieldError.checkNotNull(
              source_, r'ExternalReviewResponse', 'source_'),
          sourceUrl: sourceUrl,
          externalPostedAt: externalPostedAt,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
