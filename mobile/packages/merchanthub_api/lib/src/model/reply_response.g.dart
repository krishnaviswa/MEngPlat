// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reply_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ReplyResponse extends ReplyResponse {
  @override
  final String id;
  @override
  final String body;
  @override
  final DateTime createdAt;

  factory _$ReplyResponse([void Function(ReplyResponseBuilder)? updates]) =>
      (ReplyResponseBuilder()..update(updates))._build();

  _$ReplyResponse._(
      {required this.id, required this.body, required this.createdAt})
      : super._();
  @override
  ReplyResponse rebuild(void Function(ReplyResponseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ReplyResponseBuilder toBuilder() => ReplyResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ReplyResponse &&
        id == other.id &&
        body == other.body &&
        createdAt == other.createdAt;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, body.hashCode);
    _$hash = $jc(_$hash, createdAt.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ReplyResponse')
          ..add('id', id)
          ..add('body', body)
          ..add('createdAt', createdAt))
        .toString();
  }
}

class ReplyResponseBuilder
    implements Builder<ReplyResponse, ReplyResponseBuilder> {
  _$ReplyResponse? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _body;
  String? get body => _$this._body;
  set body(String? body) => _$this._body = body;

  DateTime? _createdAt;
  DateTime? get createdAt => _$this._createdAt;
  set createdAt(DateTime? createdAt) => _$this._createdAt = createdAt;

  ReplyResponseBuilder() {
    ReplyResponse._defaults(this);
  }

  ReplyResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _body = $v.body;
      _createdAt = $v.createdAt;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ReplyResponse other) {
    _$v = other as _$ReplyResponse;
  }

  @override
  void update(void Function(ReplyResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ReplyResponse build() => _build();

  _$ReplyResponse _build() {
    final _$result = _$v ??
        _$ReplyResponse._(
          id: BuiltValueNullFieldError.checkNotNull(id, r'ReplyResponse', 'id'),
          body: BuiltValueNullFieldError.checkNotNull(
              body, r'ReplyResponse', 'body'),
          createdAt: BuiltValueNullFieldError.checkNotNull(
              createdAt, r'ReplyResponse', 'createdAt'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
