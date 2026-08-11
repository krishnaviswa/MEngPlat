// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reply_create.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ReplyCreate extends ReplyCreate {
  @override
  final String body;

  factory _$ReplyCreate([void Function(ReplyCreateBuilder)? updates]) =>
      (ReplyCreateBuilder()..update(updates))._build();

  _$ReplyCreate._({required this.body}) : super._();
  @override
  ReplyCreate rebuild(void Function(ReplyCreateBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ReplyCreateBuilder toBuilder() => ReplyCreateBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ReplyCreate && body == other.body;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, body.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ReplyCreate')..add('body', body))
        .toString();
  }
}

class ReplyCreateBuilder implements Builder<ReplyCreate, ReplyCreateBuilder> {
  _$ReplyCreate? _$v;

  String? _body;
  String? get body => _$this._body;
  set body(String? body) => _$this._body = body;

  ReplyCreateBuilder() {
    ReplyCreate._defaults(this);
  }

  ReplyCreateBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _body = $v.body;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ReplyCreate other) {
    _$v = other as _$ReplyCreate;
  }

  @override
  void update(void Function(ReplyCreateBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ReplyCreate build() => _build();

  _$ReplyCreate _build() {
    final _$result = _$v ??
        _$ReplyCreate._(
          body: BuiltValueNullFieldError.checkNotNull(
              body, r'ReplyCreate', 'body'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
