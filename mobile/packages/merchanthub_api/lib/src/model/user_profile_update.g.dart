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

  factory _$UserProfileUpdate(
          [void Function(UserProfileUpdateBuilder)? updates]) =>
      (UserProfileUpdateBuilder()..update(updates))._build();

  _$UserProfileUpdate._(
      {this.fullName,
      this.avatarUrl,
      this.phone,
      this.addressLine1,
      this.addressLine2,
      this.city,
      this.state,
      this.postalCode,
      this.country,
      this.nationalIdType,
      this.nationalIdNumber})
      : super._();
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
        avatarUrl == other.avatarUrl &&
        phone == other.phone &&
        addressLine1 == other.addressLine1 &&
        addressLine2 == other.addressLine2 &&
        city == other.city &&
        state == other.state &&
        postalCode == other.postalCode &&
        country == other.country &&
        nationalIdType == other.nationalIdType &&
        nationalIdNumber == other.nationalIdNumber;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, fullName.hashCode);
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
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'UserProfileUpdate')
          ..add('fullName', fullName)
          ..add('avatarUrl', avatarUrl)
          ..add('phone', phone)
          ..add('addressLine1', addressLine1)
          ..add('addressLine2', addressLine2)
          ..add('city', city)
          ..add('state', state)
          ..add('postalCode', postalCode)
          ..add('country', country)
          ..add('nationalIdType', nationalIdType)
          ..add('nationalIdNumber', nationalIdNumber))
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

  UserProfileUpdateBuilder() {
    UserProfileUpdate._defaults(this);
  }

  UserProfileUpdateBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _fullName = $v.fullName;
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
          phone: phone,
          addressLine1: addressLine1,
          addressLine2: addressLine2,
          city: city,
          state: state,
          postalCode: postalCode,
          country: country,
          nationalIdType: nationalIdType,
          nationalIdNumber: nationalIdNumber,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
