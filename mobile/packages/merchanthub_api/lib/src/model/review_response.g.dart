// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'review_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ReviewResponse extends ReviewResponse {
  @override
  final String id;
  @override
  final String businessId;
  @override
  final String authorId;
  @override
  final int rating;
  @override
  final String? title;
  @override
  final String body;
  @override
  final ReviewStatus status;
  @override
  final int likeCount;
  @override
  final DateTime createdAt;
  @override
  final UserResponse? author;
  @override
  final AIAnalysisResponse? aiAnalysis;
  @override
  final ReplyResponse? reply;
  @override
  final BuiltList<String>? photoUrls;
  @override
  final BusinessSummary? business;

  factory _$ReviewResponse([void Function(ReviewResponseBuilder)? updates]) =>
      (ReviewResponseBuilder()..update(updates))._build();

  _$ReviewResponse._(
      {required this.id,
      required this.businessId,
      required this.authorId,
      required this.rating,
      this.title,
      required this.body,
      required this.status,
      required this.likeCount,
      required this.createdAt,
      this.author,
      this.aiAnalysis,
      this.reply,
      this.photoUrls,
      this.business})
      : super._();
  @override
  ReviewResponse rebuild(void Function(ReviewResponseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ReviewResponseBuilder toBuilder() => ReviewResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ReviewResponse &&
        id == other.id &&
        businessId == other.businessId &&
        authorId == other.authorId &&
        rating == other.rating &&
        title == other.title &&
        body == other.body &&
        status == other.status &&
        likeCount == other.likeCount &&
        createdAt == other.createdAt &&
        author == other.author &&
        aiAnalysis == other.aiAnalysis &&
        reply == other.reply &&
        photoUrls == other.photoUrls &&
        business == other.business;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, businessId.hashCode);
    _$hash = $jc(_$hash, authorId.hashCode);
    _$hash = $jc(_$hash, rating.hashCode);
    _$hash = $jc(_$hash, title.hashCode);
    _$hash = $jc(_$hash, body.hashCode);
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jc(_$hash, likeCount.hashCode);
    _$hash = $jc(_$hash, createdAt.hashCode);
    _$hash = $jc(_$hash, author.hashCode);
    _$hash = $jc(_$hash, aiAnalysis.hashCode);
    _$hash = $jc(_$hash, reply.hashCode);
    _$hash = $jc(_$hash, photoUrls.hashCode);
    _$hash = $jc(_$hash, business.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ReviewResponse')
          ..add('id', id)
          ..add('businessId', businessId)
          ..add('authorId', authorId)
          ..add('rating', rating)
          ..add('title', title)
          ..add('body', body)
          ..add('status', status)
          ..add('likeCount', likeCount)
          ..add('createdAt', createdAt)
          ..add('author', author)
          ..add('aiAnalysis', aiAnalysis)
          ..add('reply', reply)
          ..add('photoUrls', photoUrls)
          ..add('business', business))
        .toString();
  }
}

class ReviewResponseBuilder
    implements Builder<ReviewResponse, ReviewResponseBuilder> {
  _$ReviewResponse? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _businessId;
  String? get businessId => _$this._businessId;
  set businessId(String? businessId) => _$this._businessId = businessId;

  String? _authorId;
  String? get authorId => _$this._authorId;
  set authorId(String? authorId) => _$this._authorId = authorId;

  int? _rating;
  int? get rating => _$this._rating;
  set rating(int? rating) => _$this._rating = rating;

  String? _title;
  String? get title => _$this._title;
  set title(String? title) => _$this._title = title;

  String? _body;
  String? get body => _$this._body;
  set body(String? body) => _$this._body = body;

  ReviewStatus? _status;
  ReviewStatus? get status => _$this._status;
  set status(ReviewStatus? status) => _$this._status = status;

  int? _likeCount;
  int? get likeCount => _$this._likeCount;
  set likeCount(int? likeCount) => _$this._likeCount = likeCount;

  DateTime? _createdAt;
  DateTime? get createdAt => _$this._createdAt;
  set createdAt(DateTime? createdAt) => _$this._createdAt = createdAt;

  UserResponseBuilder? _author;
  UserResponseBuilder get author => _$this._author ??= UserResponseBuilder();
  set author(UserResponseBuilder? author) => _$this._author = author;

  AIAnalysisResponseBuilder? _aiAnalysis;
  AIAnalysisResponseBuilder get aiAnalysis =>
      _$this._aiAnalysis ??= AIAnalysisResponseBuilder();
  set aiAnalysis(AIAnalysisResponseBuilder? aiAnalysis) =>
      _$this._aiAnalysis = aiAnalysis;

  ReplyResponseBuilder? _reply;
  ReplyResponseBuilder get reply => _$this._reply ??= ReplyResponseBuilder();
  set reply(ReplyResponseBuilder? reply) => _$this._reply = reply;

  ListBuilder<String>? _photoUrls;
  ListBuilder<String> get photoUrls =>
      _$this._photoUrls ??= ListBuilder<String>();
  set photoUrls(ListBuilder<String>? photoUrls) =>
      _$this._photoUrls = photoUrls;

  BusinessSummaryBuilder? _business;
  BusinessSummaryBuilder get business =>
      _$this._business ??= BusinessSummaryBuilder();
  set business(BusinessSummaryBuilder? business) => _$this._business = business;

  ReviewResponseBuilder() {
    ReviewResponse._defaults(this);
  }

  ReviewResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _businessId = $v.businessId;
      _authorId = $v.authorId;
      _rating = $v.rating;
      _title = $v.title;
      _body = $v.body;
      _status = $v.status;
      _likeCount = $v.likeCount;
      _createdAt = $v.createdAt;
      _author = $v.author?.toBuilder();
      _aiAnalysis = $v.aiAnalysis?.toBuilder();
      _reply = $v.reply?.toBuilder();
      _photoUrls = $v.photoUrls?.toBuilder();
      _business = $v.business?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ReviewResponse other) {
    _$v = other as _$ReviewResponse;
  }

  @override
  void update(void Function(ReviewResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ReviewResponse build() => _build();

  _$ReviewResponse _build() {
    _$ReviewResponse _$result;
    try {
      _$result = _$v ??
          _$ReviewResponse._(
            id: BuiltValueNullFieldError.checkNotNull(
                id, r'ReviewResponse', 'id'),
            businessId: BuiltValueNullFieldError.checkNotNull(
                businessId, r'ReviewResponse', 'businessId'),
            authorId: BuiltValueNullFieldError.checkNotNull(
                authorId, r'ReviewResponse', 'authorId'),
            rating: BuiltValueNullFieldError.checkNotNull(
                rating, r'ReviewResponse', 'rating'),
            title: title,
            body: BuiltValueNullFieldError.checkNotNull(
                body, r'ReviewResponse', 'body'),
            status: BuiltValueNullFieldError.checkNotNull(
                status, r'ReviewResponse', 'status'),
            likeCount: BuiltValueNullFieldError.checkNotNull(
                likeCount, r'ReviewResponse', 'likeCount'),
            createdAt: BuiltValueNullFieldError.checkNotNull(
                createdAt, r'ReviewResponse', 'createdAt'),
            author: _author?.build(),
            aiAnalysis: _aiAnalysis?.build(),
            reply: _reply?.build(),
            photoUrls: _photoUrls?.build(),
            business: _business?.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'author';
        _author?.build();
        _$failedField = 'aiAnalysis';
        _aiAnalysis?.build();
        _$failedField = 'reply';
        _reply?.build();
        _$failedField = 'photoUrls';
        _photoUrls?.build();
        _$failedField = 'business';
        _business?.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'ReviewResponse', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
