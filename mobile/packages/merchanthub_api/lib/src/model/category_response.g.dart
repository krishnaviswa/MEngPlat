// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$CategoryResponse extends CategoryResponse {
  @override
  final String id;
  @override
  final String name;
  @override
  final String slug;
  @override
  final String? description;
  @override
  final String? icon;

  factory _$CategoryResponse(
          [void Function(CategoryResponseBuilder)? updates]) =>
      (CategoryResponseBuilder()..update(updates))._build();

  _$CategoryResponse._(
      {required this.id,
      required this.name,
      required this.slug,
      this.description,
      this.icon})
      : super._();
  @override
  CategoryResponse rebuild(void Function(CategoryResponseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  CategoryResponseBuilder toBuilder() =>
      CategoryResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CategoryResponse &&
        id == other.id &&
        name == other.name &&
        slug == other.slug &&
        description == other.description &&
        icon == other.icon;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jc(_$hash, slug.hashCode);
    _$hash = $jc(_$hash, description.hashCode);
    _$hash = $jc(_$hash, icon.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'CategoryResponse')
          ..add('id', id)
          ..add('name', name)
          ..add('slug', slug)
          ..add('description', description)
          ..add('icon', icon))
        .toString();
  }
}

class CategoryResponseBuilder
    implements Builder<CategoryResponse, CategoryResponseBuilder> {
  _$CategoryResponse? _$v;

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

  String? _icon;
  String? get icon => _$this._icon;
  set icon(String? icon) => _$this._icon = icon;

  CategoryResponseBuilder() {
    CategoryResponse._defaults(this);
  }

  CategoryResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _name = $v.name;
      _slug = $v.slug;
      _description = $v.description;
      _icon = $v.icon;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(CategoryResponse other) {
    _$v = other as _$CategoryResponse;
  }

  @override
  void update(void Function(CategoryResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  CategoryResponse build() => _build();

  _$CategoryResponse _build() {
    final _$result = _$v ??
        _$CategoryResponse._(
          id: BuiltValueNullFieldError.checkNotNull(
              id, r'CategoryResponse', 'id'),
          name: BuiltValueNullFieldError.checkNotNull(
              name, r'CategoryResponse', 'name'),
          slug: BuiltValueNullFieldError.checkNotNull(
              slug, r'CategoryResponse', 'slug'),
          description: description,
          icon: icon,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
