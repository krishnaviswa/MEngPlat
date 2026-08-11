// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile_update.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$UserProfileUpdate extends UserProfileUpdate {
  @override
  final String? fullName;
  @override
  final String? avatarUrl;

  factory _$UserProfileUpdate(
          [void Function(UserProfileUpdateBuilder)? updates]) =>
      (UserProfileUpdateBuilder()..update(updates))._build();

  _$UserProfileUpdate._({this.fullName, this.avatarUrl}) : super._();
  @override
  UserProfileUpdate rebuild(void Function(UserProfileUpdateBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  UserProfileUpdateBuilder toBuilder() =>
      UserProfileUpdateBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is UserProfileUpdate &&
        fullName == other.fullName &&
        avatarUrl == other.avatarUrl;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, fullName.hashCode);
    _$hash = $jc(_$hash, avatarUrl.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'UserProfileUpdate')
          ..add('fullName', fullName)
          ..add('avatarUrl', avatarUrl))
        .toString();
  }
}

class UserProfileUpdateBuilder
    implements Builder<UserProfileUpdate, UserProfileUpdateBuilder> {
  _$UserProfileUpdate? _$v;

  String? _fullName;
  String? get fullName => _$this._fullName;
  set fullName(String? fullName) => _$this._fullName = fullName;

  String? _avatarUrl;
  String? get avatarUrl => _$this._avatarUrl;
  set avatarUrl(String? avatarUrl) => _$this._avatarUrl = avatarUrl;

  UserProfileUpdateBuilder() {
    UserProfileUpdate._defaults(this);
  }

  UserProfileUpdateBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _fullName = $v.fullName;
      _avatarUrl = $v.avatarUrl;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(UserProfileUpdate other) {
    _$v = other as _$UserProfileUpdate;
  }

  @override
  void update(void Function(UserProfileUpdateBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  UserProfileUpdate build() => _build();

  _$UserProfileUpdate _build() {
    final _$result = _$v ??
        _$UserProfileUpdate._(
          fullName: fullName,
          avatarUrl: avatarUrl,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
