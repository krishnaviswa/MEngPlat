// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'business_summary.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$BusinessSummary extends BusinessSummary {
  @override
  final String id;
  @override
  final String name;
  @override
  final String slug;
  @override
  final String? city;
  @override
  final BusinessStatus status;

  factory _$BusinessSummary([void Function(BusinessSummaryBuilder)? updates]) =>
      (BusinessSummaryBuilder()..update(updates))._build();

  _$BusinessSummary._(
      {required this.id,
      required this.name,
      required this.slug,
      this.city,
      required this.status})
      : super._();
  @override
  BusinessSummary rebuild(void Function(BusinessSummaryBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  BusinessSummaryBuilder toBuilder() => BusinessSummaryBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is BusinessSummary &&
        id == other.id &&
        name == other.name &&
        slug == other.slug &&
        city == other.city &&
        status == other.status;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jc(_$hash, slug.hashCode);
    _$hash = $jc(_$hash, city.hashCode);
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'BusinessSummary')
          ..add('id', id)
          ..add('name', name)
          ..add('slug', slug)
          ..add('city', city)
          ..add('status', status))
        .toString();
  }
}

class BusinessSummaryBuilder
    implements Builder<BusinessSummary, BusinessSummaryBuilder> {
  _$BusinessSummary? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _name;
  String? get name => _$this._name;
  set name(String? name) => _$this._name = name;

  String? _slug;
  String? get slug => _$this._slug;
  set slug(String? slug) => _$this._slug = slug;

  String? _city;
  String? get city => _$this._city;
  set city(String? city) => _$this._city = city;

  BusinessStatus? _status;
  BusinessStatus? get status => _$this._status;
  set status(BusinessStatus? status) => _$this._status = status;

  BusinessSummaryBuilder() {
    BusinessSummary._defaults(this);
  }

  BusinessSummaryBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _name = $v.name;
      _slug = $v.slug;
      _city = $v.city;
      _status = $v.status;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(BusinessSummary other) {
    _$v = other as _$BusinessSummary;
  }

  @override
  void update(void Function(BusinessSummaryBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  BusinessSummary build() => _build();

  _$BusinessSummary _build() {
    final _$result = _$v ??
        _$BusinessSummary._(
          id: BuiltValueNullFieldError.checkNotNull(
              id, r'BusinessSummary', 'id'),
          name: BuiltValueNullFieldError.checkNotNull(
              name, r'BusinessSummary', 'name'),
          slug: BuiltValueNullFieldError.checkNotNull(
              slug, r'BusinessSummary', 'slug'),
          city: city,
          status: BuiltValueNullFieldError.checkNotNull(
              status, r'BusinessSummary', 'status'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
