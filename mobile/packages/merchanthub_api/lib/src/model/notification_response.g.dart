// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$NotificationResponse extends NotificationResponse {
  @override
  final String id;
  @override
  final String type;
  @override
  final String title;
  @override
  final String message;
  @override
  final bool isRead;
  @override
  final JsonObject? extraData;
  @override
  final DateTime createdAt;

  factory _$NotificationResponse(
          [void Function(NotificationResponseBuilder)? updates]) =>
      (NotificationResponseBuilder()..update(updates))._build();

  _$NotificationResponse._(
      {required this.id,
      required this.type,
      required this.title,
      required this.message,
      required this.isRead,
      this.extraData,
      required this.createdAt})
      : super._();
  @override
  NotificationResponse rebuild(
          void Function(NotificationResponseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  NotificationResponseBuilder toBuilder() =>
      NotificationResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is NotificationResponse &&
        id == other.id &&
        type == other.type &&
        title == other.title &&
        message == other.message &&
        isRead == other.isRead &&
        extraData == other.extraData &&
        createdAt == other.createdAt;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, type.hashCode);
    _$hash = $jc(_$hash, title.hashCode);
    _$hash = $jc(_$hash, message.hashCode);
    _$hash = $jc(_$hash, isRead.hashCode);
    _$hash = $jc(_$hash, extraData.hashCode);
    _$hash = $jc(_$hash, createdAt.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'NotificationResponse')
          ..add('id', id)
          ..add('type', type)
          ..add('title', title)
          ..add('message', message)
          ..add('isRead', isRead)
          ..add('extraData', extraData)
          ..add('createdAt', createdAt))
        .toString();
  }
}

class NotificationResponseBuilder
    implements Builder<NotificationResponse, NotificationResponseBuilder> {
  _$NotificationResponse? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _type;
  String? get type => _$this._type;
  set type(String? type) => _$this._type = type;

  String? _title;
  String? get title => _$this._title;
  set title(String? title) => _$this._title = title;

  String? _message;
  String? get message => _$this._message;
  set message(String? message) => _$this._message = message;

  bool? _isRead;
  bool? get isRead => _$this._isRead;
  set isRead(bool? isRead) => _$this._isRead = isRead;

  JsonObject? _extraData;
  JsonObject? get extraData => _$this._extraData;
  set extraData(JsonObject? extraData) => _$this._extraData = extraData;

  DateTime? _createdAt;
  DateTime? get createdAt => _$this._createdAt;
  set createdAt(DateTime? createdAt) => _$this._createdAt = createdAt;

  NotificationResponseBuilder() {
    NotificationResponse._defaults(this);
  }

  NotificationResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _type = $v.type;
      _title = $v.title;
      _message = $v.message;
      _isRead = $v.isRead;
      _extraData = $v.extraData;
      _createdAt = $v.createdAt;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(NotificationResponse other) {
    _$v = other as _$NotificationResponse;
  }

  @override
  void update(void Function(NotificationResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  NotificationResponse build() => _build();

  _$NotificationResponse _build() {
    final _$result = _$v ??
        _$NotificationResponse._(
          id: BuiltValueNullFieldError.checkNotNull(
              id, r'NotificationResponse', 'id'),
          type: BuiltValueNullFieldError.checkNotNull(
              type, r'NotificationResponse', 'type'),
          title: BuiltValueNullFieldError.checkNotNull(
              title, r'NotificationResponse', 'title'),
          message: BuiltValueNullFieldError.checkNotNull(
              message, r'NotificationResponse', 'message'),
          isRead: BuiltValueNullFieldError.checkNotNull(
              isRead, r'NotificationResponse', 'isRead'),
          extraData: extraData,
          createdAt: BuiltValueNullFieldError.checkNotNull(
              createdAt, r'NotificationResponse', 'createdAt'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
