// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'review_create.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ReviewCreate extends ReviewCreate {
  @override
  final String businessId;
  @override
  final int rating;
  @override
  final String? title;
  @override
  final String body;

  factory _$ReviewCreate([void Function(ReviewCreateBuilder)? updates]) =>
      (ReviewCreateBuilder()..update(updates))._build();

  _$ReviewCreate._(
      {required this.businessId,
      required this.rating,
      this.title,
      required this.body})
      : super._();
  @override
  ReviewCreate rebuild(void Function(ReviewCreateBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ReviewCreateBuilder toBuilder() => ReviewCreateBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ReviewCreate &&
        businessId == other.businessId &&
        rating == other.rating &&
        title == other.title &&
        body == other.body;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, businessId.hashCode);
    _$hash = $jc(_$hash, rating.hashCode);
    _$hash = $jc(_$hash, title.hashCode);
    _$hash = $jc(_$hash, body.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ReviewCreate')
          ..add('businessId', businessId)
          ..add('rating', rating)
          ..add('title', title)
          ..add('body', body))
        .toString();
  }
}

class ReviewCreateBuilder
    implements Builder<ReviewCreate, ReviewCreateBuilder> {
  _$ReviewCreate? _$v;

  String? _businessId;
  String? get businessId => _$this._businessId;
  set businessId(String? businessId) => _$this._businessId = businessId;

  int? _rating;
  int? get rating => _$this._rating;
  set rating(int? rating) => _$this._rating = rating;

  String? _title;
  String? get title => _$this._title;
  set title(String? title) => _$this._title = title;

  String? _body;
  String? get body => _$this._body;
  set body(String? body) => _$this._body = body;

  ReviewCreateBuilder() {
    ReviewCreate._defaults(this);
  }

  ReviewCreateBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _businessId = $v.businessId;
      _rating = $v.rating;
      _title = $v.title;
      _body = $v.body;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ReviewCreate other) {
    _$v = other as _$ReviewCreate;
  }

  @override
  void update(void Function(ReviewCreateBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ReviewCreate build() => _build();

  _$ReviewCreate _build() {
    final _$result = _$v ??
        _$ReviewCreate._(
          businessId: BuiltValueNullFieldError.checkNotNull(
              businessId, r'ReviewCreate', 'businessId'),
          rating: BuiltValueNullFieldError.checkNotNull(
              rating, r'ReviewCreate', 'rating'),
          title: title,
          body: BuiltValueNullFieldError.checkNotNull(
              body, r'ReviewCreate', 'body'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
