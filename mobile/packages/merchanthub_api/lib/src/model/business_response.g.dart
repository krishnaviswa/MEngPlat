// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'business_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$BusinessResponse extends BusinessResponse {
  @override
  final String id;
  @override
  final String name;
  @override
  final String slug;
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
  final String country;
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
  final String? logoUrl;
  @override
  final String? storefrontUrl;
  @override
  final JsonObject? businessHours;
  @override
  final BusinessStatus status;
  @override
  final num averageRating;
  @override
  final int reviewCount;
  @override
  final String? aiMerchantSummary;
  @override
  final BuiltList<CategoryResponse>? categories;

  factory _$BusinessResponse(
          [void Function(BusinessResponseBuilder)? updates]) =>
      (BusinessResponseBuilder()..update(updates))._build();

  _$BusinessResponse._(
      {required this.id,
      required this.name,
      required this.slug,
      this.description,
      required this.address,
      required this.city,
      this.state,
      this.postalCode,
      required this.country,
      this.latitude,
      this.longitude,
      this.phone,
      this.email,
      this.website,
      this.logoUrl,
      this.storefrontUrl,
      this.businessHours,
      required this.status,
      required this.averageRating,
      required this.reviewCount,
      this.aiMerchantSummary,
      this.categories})
      : super._();
  @override
  BusinessResponse rebuild(void Function(BusinessResponseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  BusinessResponseBuilder toBuilder() =>
      BusinessResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is BusinessResponse &&
        id == other.id &&
        name == other.name &&
        slug == other.slug &&
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
        logoUrl == other.logoUrl &&
        storefrontUrl == other.storefrontUrl &&
        businessHours == other.businessHours &&
        status == other.status &&
        averageRating == other.averageRating &&
        reviewCount == other.reviewCount &&
        aiMerchantSummary == other.aiMerchantSummary &&
        categories == other.categories;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jc(_$hash, slug.hashCode);
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
    _$hash = $jc(_$hash, logoUrl.hashCode);
    _$hash = $jc(_$hash, storefrontUrl.hashCode);
    _$hash = $jc(_$hash, businessHours.hashCode);
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jc(_$hash, averageRating.hashCode);
    _$hash = $jc(_$hash, reviewCount.hashCode);
    _$hash = $jc(_$hash, aiMerchantSummary.hashCode);
    _$hash = $jc(_$hash, categories.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'BusinessResponse')
          ..add('id', id)
          ..add('name', name)
          ..add('slug', slug)
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
          ..add('logoUrl', logoUrl)
          ..add('storefrontUrl', storefrontUrl)
          ..add('businessHours', businessHours)
          ..add('status', status)
          ..add('averageRating', averageRating)
          ..add('reviewCount', reviewCount)
          ..add('aiMerchantSummary', aiMerchantSummary)
          ..add('categories', categories))
        .toString();
  }
}

class BusinessResponseBuilder
    implements Builder<BusinessResponse, BusinessResponseBuilder> {
  _$BusinessResponse? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _name;
  String? get name => _$this._name;
  set name(String? name) => _$this._name = name;

  String? _slug;
  String? get slug => _$this._slug;
  set slug(String? slug) => _$this._slug = slug;

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

  String? _logoUrl;
  String? get logoUrl => _$this._logoUrl;
  set logoUrl(String? logoUrl) => _$this._logoUrl = logoUrl;

  String? _storefrontUrl;
  String? get storefrontUrl => _$this._storefrontUrl;
  set storefrontUrl(String? storefrontUrl) =>
      _$this._storefrontUrl = storefrontUrl;

  JsonObject? _businessHours;
  JsonObject? get businessHours => _$this._businessHours;
  set businessHours(JsonObject? businessHours) =>
      _$this._businessHours = businessHours;

  BusinessStatus? _status;
  BusinessStatus? get status => _$this._status;
  set status(BusinessStatus? status) => _$this._status = status;

  num? _averageRating;
  num? get averageRating => _$this._averageRating;
  set averageRating(num? averageRating) =>
      _$this._averageRating = averageRating;

  int? _reviewCount;
  int? get reviewCount => _$this._reviewCount;
  set reviewCount(int? reviewCount) => _$this._reviewCount = reviewCount;

  String? _aiMerchantSummary;
  String? get aiMerchantSummary => _$this._aiMerchantSummary;
  set aiMerchantSummary(String? aiMerchantSummary) =>
      _$this._aiMerchantSummary = aiMerchantSummary;

  ListBuilder<CategoryResponse>? _categories;
  ListBuilder<CategoryResponse> get categories =>
      _$this._categories ??= ListBuilder<CategoryResponse>();
  set categories(ListBuilder<CategoryResponse>? categories) =>
      _$this._categories = categories;

  BusinessResponseBuilder() {
    BusinessResponse._defaults(this);
  }

  BusinessResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _name = $v.name;
      _slug = $v.slug;
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
      _logoUrl = $v.logoUrl;
      _storefrontUrl = $v.storefrontUrl;
      _businessHours = $v.businessHours;
      _status = $v.status;
      _averageRating = $v.averageRating;
      _reviewCount = $v.reviewCount;
      _aiMerchantSummary = $v.aiMerchantSummary;
      _categories = $v.categories?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(BusinessResponse other) {
    _$v = other as _$BusinessResponse;
  }

  @override
  void update(void Function(BusinessResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  BusinessResponse build() => _build();

  _$BusinessResponse _build() {
    _$BusinessResponse _$result;
    try {
      _$result = _$v ??
          _$BusinessResponse._(
            id: BuiltValueNullFieldError.checkNotNull(
                id, r'BusinessResponse', 'id'),
            name: BuiltValueNullFieldError.checkNotNull(
                name, r'BusinessResponse', 'name'),
            slug: BuiltValueNullFieldError.checkNotNull(
                slug, r'BusinessResponse', 'slug'),
            description: description,
            address: BuiltValueNullFieldError.checkNotNull(
                address, r'BusinessResponse', 'address'),
            city: BuiltValueNullFieldError.checkNotNull(
                city, r'BusinessResponse', 'city'),
            state: state,
            postalCode: postalCode,
            country: BuiltValueNullFieldError.checkNotNull(
                country, r'BusinessResponse', 'country'),
            latitude: latitude,
            longitude: longitude,
            phone: phone,
            email: email,
            website: website,
            logoUrl: logoUrl,
            storefrontUrl: storefrontUrl,
            businessHours: businessHours,
            status: BuiltValueNullFieldError.checkNotNull(
                status, r'BusinessResponse', 'status'),
            averageRating: BuiltValueNullFieldError.checkNotNull(
                averageRating, r'BusinessResponse', 'averageRating'),
            reviewCount: BuiltValueNullFieldError.checkNotNull(
                reviewCount, r'BusinessResponse', 'reviewCount'),
            aiMerchantSummary: aiMerchantSummary,
            categories: _categories?.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'categories';
        _categories?.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'BusinessResponse', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
