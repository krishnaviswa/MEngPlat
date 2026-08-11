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
  final String? phone;
  @override
  final String? addressLine1;
  @override
  final String? addressLine2;
  @override
  final String? city;
  @override
  final String? state;
  @override
  final String? postalCode;
  @override
  final String? country;
  @override
  final NationalIdType? nationalIdType;
  @override
  final String? nationalIdNumber;
  @override
  final String? authProvider;
  @override
  final bool? totpEnabled;
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
      this.phone,
      this.addressLine1,
      this.addressLine2,
      this.city,
      this.state,
      this.postalCode,
      this.country,
      this.nationalIdType,
      this.nationalIdNumber,
      this.authProvider,
      this.totpEnabled,
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
        phone == other.phone &&
        addressLine1 == other.addressLine1 &&
        addressLine2 == other.addressLine2 &&
        city == other.city &&
        state == other.state &&
        postalCode == other.postalCode &&
        country == other.country &&
        nationalIdType == other.nationalIdType &&
        nationalIdNumber == other.nationalIdNumber &&
        authProvider == other.authProvider &&
        totpEnabled == other.totpEnabled &&
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
    _$hash = $jc(_$hash, phone.hashCode);
    _$hash = $jc(_$hash, addressLine1.hashCode);
    _$hash = $jc(_$hash, addressLine2.hashCode);
    _$hash = $jc(_$hash, city.hashCode);
    _$hash = $jc(_$hash, state.hashCode);
    _$hash = $jc(_$hash, postalCode.hashCode);
    _$hash = $jc(_$hash, country.hashCode);
    _$hash = $jc(_$hash, nationalIdType.hashCode);
    _$hash = $jc(_$hash, nationalIdNumber.hashCode);
    _$hash = $jc(_$hash, authProvider.hashCode);
    _$hash = $jc(_$hash, totpEnabled.hashCode);
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
          ..add('phone', phone)
          ..add('addressLine1', addressLine1)
          ..add('addressLine2', addressLine2)
          ..add('city', city)
          ..add('state', state)
          ..add('postalCode', postalCode)
          ..add('country', country)
          ..add('nationalIdType', nationalIdType)
          ..add('nationalIdNumber', nationalIdNumber)
          ..add('authProvider', authProvider)
          ..add('totpEnabled', totpEnabled)
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

  String? _phone;
  String? get phone => _$this._phone;
  set phone(String? phone) => _$this._phone = phone;

  String? _addressLine1;
  String? get addressLine1 => _$this._addressLine1;
  set addressLine1(String? addressLine1) => _$this._addressLine1 = addressLine1;

  String? _addressLine2;
  String? get addressLine2 => _$this._addressLine2;
  set addressLine2(String? addressLine2) => _$this._addressLine2 = addressLine2;

  String? _city;
  String? get city => _$this._city;
  set city(String? city) => _$this._city = city;

  String? _state;
  String? get state => _$this._state;
  set state(String? state) => _$this._state = state;

  String? _postalCode;
  String? get postalCode => _$this._postalCode;
  set postalCode(String? postalCode) => _$this._postalCode = postalCode;

  String? _country;
  String? get country => _$this._country;
  set country(String? country) => _$this._country = country;

  NationalIdType? _nationalIdType;
  NationalIdType? get nationalIdType => _$this._nationalIdType;
  set nationalIdType(NationalIdType? nationalIdType) =>
      _$this._nationalIdType = nationalIdType;

  String? _nationalIdNumber;
  String? get nationalIdNumber => _$this._nationalIdNumber;
  set nationalIdNumber(String? nationalIdNumber) =>
      _$this._nationalIdNumber = nationalIdNumber;

  String? _authProvider;
  String? get authProvider => _$this._authProvider;
  set authProvider(String? authProvider) => _$this._authProvider = authProvider;

  bool? _totpEnabled;
  bool? get totpEnabled => _$this._totpEnabled;
  set totpEnabled(bool? totpEnabled) => _$this._totpEnabled = totpEnabled;

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
      _phone = $v.phone;
      _addressLine1 = $v.addressLine1;
      _addressLine2 = $v.addressLine2;
      _city = $v.city;
      _state = $v.state;
      _postalCode = $v.postalCode;
      _country = $v.country;
      _nationalIdType = $v.nationalIdType;
      _nationalIdNumber = $v.nationalIdNumber;
      _authProvider = $v.authProvider;
      _totpEnabled = $v.totpEnabled;
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
          phone: phone,
          addressLine1: addressLine1,
          addressLine2: addressLine2,
          city: city,
          state: state,
          postalCode: postalCode,
          country: country,
          nationalIdType: nationalIdType,
          nationalIdNumber: nationalIdNumber,
          authProvider: authProvider,
          totpEnabled: totpEnabled,
          createdAt: BuiltValueNullFieldError.checkNotNull(
              createdAt, r'UserResponse', 'createdAt'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
