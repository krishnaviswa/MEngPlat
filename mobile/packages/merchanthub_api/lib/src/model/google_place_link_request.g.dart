// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'google_place_link_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$GooglePlaceLinkRequest extends GooglePlaceLinkRequest {
  @override
  final String placeId;
  @override
  final String? name;
  @override
  final String? address;

  factory _$GooglePlaceLinkRequest(
          [void Function(GooglePlaceLinkRequestBuilder)? updates]) =>
      (GooglePlaceLinkRequestBuilder()..update(updates))._build();

  _$GooglePlaceLinkRequest._({required this.placeId, this.name, this.address})
      : super._();
  @override
  GooglePlaceLinkRequest rebuild(
          void Function(GooglePlaceLinkRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  GooglePlaceLinkRequestBuilder toBuilder() =>
      GooglePlaceLinkRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is GooglePlaceLinkRequest &&
        placeId == other.placeId &&
        name == other.name &&
        address == other.address;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, placeId.hashCode);
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jc(_$hash, address.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'GooglePlaceLinkRequest')
          ..add('placeId', placeId)
          ..add('name', name)
          ..add('address', address))
        .toString();
  }
}

class GooglePlaceLinkRequestBuilder
    implements Builder<GooglePlaceLinkRequest, GooglePlaceLinkRequestBuilder> {
  _$GooglePlaceLinkRequest? _$v;

  String? _placeId;
  String? get placeId => _$this._placeId;
  set placeId(String? placeId) => _$this._placeId = placeId;

  String? _name;
  String? get name => _$this._name;
  set name(String? name) => _$this._name = name;

  String? _address;
  String? get address => _$this._address;
  set address(String? address) => _$this._address = address;

  GooglePlaceLinkRequestBuilder() {
    GooglePlaceLinkRequest._defaults(this);
  }

  GooglePlaceLinkRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _placeId = $v.placeId;
      _name = $v.name;
      _address = $v.address;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(GooglePlaceLinkRequest other) {
    _$v = other as _$GooglePlaceLinkRequest;
  }

  @override
  void update(void Function(GooglePlaceLinkRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  GooglePlaceLinkRequest build() => _build();

  _$GooglePlaceLinkRequest _build() {
    final _$result = _$v ??
        _$GooglePlaceLinkRequest._(
          placeId: BuiltValueNullFieldError.checkNotNull(
              placeId, r'GooglePlaceLinkRequest', 'placeId'),
          name: name,
          address: address,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
