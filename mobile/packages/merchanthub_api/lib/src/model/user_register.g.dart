// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_register.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$UserRegister extends UserRegister {
  @override
  final String email;
  @override
  final String fullName;
  @override
  final String password;
  @override
  final UserRole? role;

  factory _$UserRegister([void Function(UserRegisterBuilder)? updates]) =>
      (UserRegisterBuilder()..update(updates))._build();

  _$UserRegister._(
      {required this.email,
      required this.fullName,
      required this.password,
      this.role})
      : super._();
  @override
  UserRegister rebuild(void Function(UserRegisterBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  UserRegisterBuilder toBuilder() => UserRegisterBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is UserRegister &&
        email == other.email &&
        fullName == other.fullName &&
        password == other.password &&
        role == other.role;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, email.hashCode);
    _$hash = $jc(_$hash, fullName.hashCode);
    _$hash = $jc(_$hash, password.hashCode);
    _$hash = $jc(_$hash, role.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'UserRegister')
          ..add('email', email)
          ..add('fullName', fullName)
          ..add('password', password)
          ..add('role', role))
        .toString();
  }
}

class UserRegisterBuilder
    implements Builder<UserRegister, UserRegisterBuilder> {
  _$UserRegister? _$v;

  String? _email;
  String? get email => _$this._email;
  set email(String? email) => _$this._email = email;

  String? _fullName;
  String? get fullName => _$this._fullName;
  set fullName(String? fullName) => _$this._fullName = fullName;

  String? _password;
  String? get password => _$this._password;
  set password(String? password) => _$this._password = password;

  UserRole? _role;
  UserRole? get role => _$this._role;
  set role(UserRole? role) => _$this._role = role;

  UserRegisterBuilder() {
    UserRegister._defaults(this);
  }

  UserRegisterBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _email = $v.email;
      _fullName = $v.fullName;
      _password = $v.password;
      _role = $v.role;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(UserRegister other) {
    _$v = other as _$UserRegister;
  }

  @override
  void update(void Function(UserRegisterBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  UserRegister build() => _build();

  _$UserRegister _build() {
    final _$result = _$v ??
        _$UserRegister._(
          email: BuiltValueNullFieldError.checkNotNull(
              email, r'UserRegister', 'email'),
          fullName: BuiltValueNullFieldError.checkNotNull(
              fullName, r'UserRegister', 'fullName'),
          password: BuiltValueNullFieldError.checkNotNull(
              password, r'UserRegister', 'password'),
          role: role,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
