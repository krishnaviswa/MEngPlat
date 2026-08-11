// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$UserResponse extends UserResponse {
  @override
  final String email;
  @override
  final String fullName;
  @override
  final String id;
  @override
  final UserRole role;
  @override
  final bool isActive;
  @override
  final String? avatarUrl;
  @override
  final DateTime createdAt;

  factory _$UserResponse([void Function(UserResponseBuilder)? updates]) =>
      (UserResponseBuilder()..update(updates))._build();

  _$UserResponse._(
      {required this.email,
      required this.fullName,
      required this.id,
      required this.role,
      required this.isActive,
      this.avatarUrl,
      required this.createdAt})
      : super._();
  @override
  UserResponse rebuild(void Function(UserResponseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  UserResponseBuilder toBuilder() => UserResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is UserResponse &&
        email == other.email &&
        fullName == other.fullName &&
        id == other.id &&
        role == other.role &&
        isActive == other.isActive &&
        avatarUrl == other.avatarUrl &&
        createdAt == other.createdAt;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, email.hashCode);
    _$hash = $jc(_$hash, fullName.hashCode);
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, role.hashCode);
    _$hash = $jc(_$hash, isActive.hashCode);
    _$hash = $jc(_$hash, avatarUrl.hashCode);
    _$hash = $jc(_$hash, createdAt.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'UserResponse')
          ..add('email', email)
          ..add('fullName', fullName)
          ..add('id', id)
          ..add('role', role)
          ..add('isActive', isActive)
          ..add('avatarUrl', avatarUrl)
          ..add('createdAt', createdAt))
        .toString();
  }
}

class UserResponseBuilder
    implements Builder<UserResponse, UserResponseBuilder> {
  _$UserResponse? _$v;

  String? _email;
  String? get email => _$this._email;
  set email(String? email) => _$this._email = email;

  String? _fullName;
  String? get fullName => _$this._fullName;
  set fullName(String? fullName) => _$this._fullName = fullName;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  UserRole? _role;
  UserRole? get role => _$this._role;
  set role(UserRole? role) => _$this._role = role;

  bool? _isActive;
  bool? get isActive => _$this._isActive;
  set isActive(bool? isActive) => _$this._isActive = isActive;

  String? _avatarUrl;
  String? get avatarUrl => _$this._avatarUrl;
  set avatarUrl(String? avatarUrl) => _$this._avatarUrl = avatarUrl;

  DateTime? _createdAt;
  DateTime? get createdAt => _$this._createdAt;
  set createdAt(DateTime? createdAt) => _$this._createdAt = createdAt;

  UserResponseBuilder() {
    UserResponse._defaults(this);
  }

  UserResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _email = $v.email;
      _fullName = $v.fullName;
      _id = $v.id;
      _role = $v.role;
      _isActive = $v.isActive;
      _avatarUrl = $v.avatarUrl;
      _createdAt = $v.createdAt;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(UserResponse other) {
    _$v = other as _$UserResponse;
  }

  @override
  void update(void Function(UserResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  UserResponse build() => _build();

  _$UserResponse _build() {
    final _$result = _$v ??
        _$UserResponse._(
          email: BuiltValueNullFieldError.checkNotNull(
              email, r'UserResponse', 'email'),
          fullName: BuiltValueNullFieldError.checkNotNull(
              fullName, r'UserResponse', 'fullName'),
          id: BuiltValueNullFieldError.checkNotNull(id, r'UserResponse', 'id'),
          role: BuiltValueNullFieldError.checkNotNull(
              role, r'UserResponse', 'role'),
          isActive: BuiltValueNullFieldError.checkNotNull(
              isActive, r'UserResponse', 'isActive'),
          avatarUrl: avatarUrl,
          createdAt: BuiltValueNullFieldError.checkNotNull(
              createdAt, r'UserResponse', 'createdAt'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
