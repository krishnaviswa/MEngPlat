// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category_create.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$CategoryCreate extends CategoryCreate {
  @override
  final String name;
  @override
  final String slug;
  @override
  final String? description;
  @override
  final String? icon;

  factory _$CategoryCreate([void Function(CategoryCreateBuilder)? updates]) =>
      (CategoryCreateBuilder()..update(updates))._build();

  _$CategoryCreate._(
      {required this.name, required this.slug, this.description, this.icon})
      : super._();
  @override
  CategoryCreate rebuild(void Function(CategoryCreateBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  CategoryCreateBuilder toBuilder() => CategoryCreateBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CategoryCreate &&
        name == other.name &&
        slug == other.slug &&
        description == other.description &&
        icon == other.icon;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jc(_$hash, slug.hashCode);
    _$hash = $jc(_$hash, description.hashCode);
    _$hash = $jc(_$hash, icon.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'CategoryCreate')
          ..add('name', name)
          ..add('slug', slug)
          ..add('description', description)
          ..add('icon', icon))
        .toString();
  }
}

class CategoryCreateBuilder
    implements Builder<CategoryCreate, CategoryCreateBuilder> {
  _$CategoryCreate? _$v;

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

  CategoryCreateBuilder() {
    CategoryCreate._defaults(this);
  }

  CategoryCreateBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _name = $v.name;
      _slug = $v.slug;
      _description = $v.description;
      _icon = $v.icon;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(CategoryCreate other) {
    _$v = other as _$CategoryCreate;
  }

  @override
  void update(void Function(CategoryCreateBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  CategoryCreate build() => _build();

  _$CategoryCreate _build() {
    final _$result = _$v ??
        _$CategoryCreate._(
          name: BuiltValueNullFieldError.checkNotNull(
              name, r'CategoryCreate', 'name'),
          slug: BuiltValueNullFieldError.checkNotNull(
              slug, r'CategoryCreate', 'slug'),
          description: description,
          icon: icon,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
