// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'business_create.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$BusinessCreate extends BusinessCreate {
  @override
  final String name;
  @override
  final String? description;
  @override
  final String address;
  @override
  final String city;
  @override
  final String? state;
  @override
  final String? postalCode;
  @override
  final String? country;
  @override
  final num? latitude;
  @override
  final num? longitude;
  @override
  final String? phone;
  @override
  final String? email;
  @override
  final String? website;
  @override
  final JsonObject? businessHours;
  @override
  final BuiltList<String>? categoryIds;

  factory _$BusinessCreate([void Function(BusinessCreateBuilder)? updates]) =>
      (BusinessCreateBuilder()..update(updates))._build();

  _$BusinessCreate._(
      {required this.name,
      this.description,
      required this.address,
      required this.city,
      this.state,
      this.postalCode,
      this.country,
      this.latitude,
      this.longitude,
      this.phone,
      this.email,
      this.website,
      this.businessHours,
      this.categoryIds})
      : super._();
  @override
  BusinessCreate rebuild(void Function(BusinessCreateBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  BusinessCreateBuilder toBuilder() => BusinessCreateBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is BusinessCreate &&
        name == other.name &&
        description == other.description &&
        address == other.address &&
        city == other.city &&
        state == other.state &&
        postalCode == other.postalCode &&
        country == other.country &&
        latitude == other.latitude &&
        longitude == other.longitude &&
        phone == other.phone &&
        email == other.email &&
        website == other.website &&
        businessHours == other.businessHours &&
        categoryIds == other.categoryIds;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jc(_$hash, description.hashCode);
    _$hash = $jc(_$hash, address.hashCode);
    _$hash = $jc(_$hash, city.hashCode);
    _$hash = $jc(_$hash, state.hashCode);
    _$hash = $jc(_$hash, postalCode.hashCode);
    _$hash = $jc(_$hash, country.hashCode);
    _$hash = $jc(_$hash, latitude.hashCode);
    _$hash = $jc(_$hash, longitude.hashCode);
    _$hash = $jc(_$hash, phone.hashCode);
    _$hash = $jc(_$hash, email.hashCode);
    _$hash = $jc(_$hash, website.hashCode);
    _$hash = $jc(_$hash, businessHours.hashCode);
    _$hash = $jc(_$hash, categoryIds.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'BusinessCreate')
          ..add('name', name)
          ..add('description', description)
          ..add('address', address)
          ..add('city', city)
          ..add('state', state)
          ..add('postalCode', postalCode)
          ..add('country', country)
          ..add('latitude', latitude)
          ..add('longitude', longitude)
          ..add('phone', phone)
          ..add('email', email)
          ..add('website', website)
          ..add('businessHours', businessHours)
          ..add('categoryIds', categoryIds))
        .toString();
  }
}

class BusinessCreateBuilder
    implements Builder<BusinessCreate, BusinessCreateBuilder> {
  _$BusinessCreate? _$v;

  String? _name;
  String? get name => _$this._name;
  set name(String? name) => _$this._name = name;

  String? _description;
  String? get description => _$this._description;
  set description(String? description) => _$this._description = description;

  String? _address;
  String? get address => _$this._address;
  set address(String? address) => _$this._address = address;

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

  num? _latitude;
  num? get latitude => _$this._latitude;
  set latitude(num? latitude) => _$this._latitude = latitude;

  num? _longitude;
  num? get longitude => _$this._longitude;
  set longitude(num? longitude) => _$this._longitude = longitude;

  String? _phone;
  String? get phone => _$this._phone;
  set phone(String? phone) => _$this._phone = phone;

  String? _email;
  String? get email => _$this._email;
  set email(String? email) => _$this._email = email;

  String? _website;
  String? get website => _$this._website;
  set website(String? website) => _$this._website = website;

  JsonObject? _businessHours;
  JsonObject? get businessHours => _$this._businessHours;
  set businessHours(JsonObject? businessHours) =>
      _$this._businessHours = businessHours;

  ListBuilder<String>? _categoryIds;
  ListBuilder<String> get categoryIds =>
      _$this._categoryIds ??= ListBuilder<String>();
  set categoryIds(ListBuilder<String>? categoryIds) =>
      _$this._categoryIds = categoryIds;

  BusinessCreateBuilder() {
    BusinessCreate._defaults(this);
  }

  BusinessCreateBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _name = $v.name;
      _description = $v.description;
      _address = $v.address;
      _city = $v.city;
      _state = $v.state;
      _postalCode = $v.postalCode;
      _country = $v.country;
      _latitude = $v.latitude;
      _longitude = $v.longitude;
      _phone = $v.phone;
      _email = $v.email;
      _website = $v.website;
      _businessHours = $v.businessHours;
      _categoryIds = $v.categoryIds?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(BusinessCreate other) {
    _$v = other as _$BusinessCreate;
  }

  @override
  void update(void Function(BusinessCreateBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  BusinessCreate build() => _build();

  _$BusinessCreate _build() {
    _$BusinessCreate _$result;
    try {
      _$result = _$v ??
          _$BusinessCreate._(
            name: BuiltValueNullFieldError.checkNotNull(
                name, r'BusinessCreate', 'name'),
            description: description,
            address: BuiltValueNullFieldError.checkNotNull(
                address, r'BusinessCreate', 'address'),
            city: BuiltValueNullFieldError.checkNotNull(
                city, r'BusinessCreate', 'city'),
            state: state,
            postalCode: postalCode,
            country: country,
            latitude: latitude,
            longitude: longitude,
            phone: phone,
            email: email,
            website: website,
            businessHours: businessHours,
            categoryIds: _categoryIds?.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'categoryIds';
        _categoryIds?.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'BusinessCreate', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
