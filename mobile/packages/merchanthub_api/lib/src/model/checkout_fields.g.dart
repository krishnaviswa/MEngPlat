// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'checkout_fields.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$CheckoutFields extends CheckoutFields {
  @override
  final String keyId;
  @override
  final String orderId;
  @override
  final int amount;
  @override
  final String currency;
  @override
  final String name;
  @override
  final String description;
  @override
  final BuiltMap<String, String>? prefill;

  factory _$CheckoutFields([void Function(CheckoutFieldsBuilder)? updates]) =>
      (CheckoutFieldsBuilder()..update(updates))._build();

  _$CheckoutFields._(
      {required this.keyId,
      required this.orderId,
      required this.amount,
      required this.currency,
      required this.name,
      required this.description,
      this.prefill})
      : super._();
  @override
  CheckoutFields rebuild(void Function(CheckoutFieldsBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  CheckoutFieldsBuilder toBuilder() => CheckoutFieldsBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CheckoutFields &&
        keyId == other.keyId &&
        orderId == other.orderId &&
        amount == other.amount &&
        currency == other.currency &&
        name == other.name &&
        description == other.description &&
        prefill == other.prefill;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, keyId.hashCode);
    _$hash = $jc(_$hash, orderId.hashCode);
    _$hash = $jc(_$hash, amount.hashCode);
    _$hash = $jc(_$hash, currency.hashCode);
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jc(_$hash, description.hashCode);
    _$hash = $jc(_$hash, prefill.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'CheckoutFields')
          ..add('keyId', keyId)
          ..add('orderId', orderId)
          ..add('amount', amount)
          ..add('currency', currency)
          ..add('name', name)
          ..add('description', description)
          ..add('prefill', prefill))
        .toString();
  }
}

class CheckoutFieldsBuilder
    implements Builder<CheckoutFields, CheckoutFieldsBuilder> {
  _$CheckoutFields? _$v;

  String? _keyId;
  String? get keyId => _$this._keyId;
  set keyId(String? keyId) => _$this._keyId = keyId;

  String? _orderId;
  String? get orderId => _$this._orderId;
  set orderId(String? orderId) => _$this._orderId = orderId;

  int? _amount;
  int? get amount => _$this._amount;
  set amount(int? amount) => _$this._amount = amount;

  String? _currency;
  String? get currency => _$this._currency;
  set currency(String? currency) => _$this._currency = currency;

  String? _name;
  String? get name => _$this._name;
  set name(String? name) => _$this._name = name;

  String? _description;
  String? get description => _$this._description;
  set description(String? description) => _$this._description = description;

  MapBuilder<String, String>? _prefill;
  MapBuilder<String, String> get prefill =>
      _$this._prefill ??= MapBuilder<String, String>();
  set prefill(MapBuilder<String, String>? prefill) => _$this._prefill = prefill;

  CheckoutFieldsBuilder() {
    CheckoutFields._defaults(this);
  }

  CheckoutFieldsBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _keyId = $v.keyId;
      _orderId = $v.orderId;
      _amount = $v.amount;
      _currency = $v.currency;
      _name = $v.name;
      _description = $v.description;
      _prefill = $v.prefill?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(CheckoutFields other) {
    _$v = other as _$CheckoutFields;
  }

  @override
  void update(void Function(CheckoutFieldsBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  CheckoutFields build() => _build();

  _$CheckoutFields _build() {
    _$CheckoutFields _$result;
    try {
      _$result = _$v ??
          _$CheckoutFields._(
            keyId: BuiltValueNullFieldError.checkNotNull(
                keyId, r'CheckoutFields', 'keyId'),
            orderId: BuiltValueNullFieldError.checkNotNull(
                orderId, r'CheckoutFields', 'orderId'),
            amount: BuiltValueNullFieldError.checkNotNull(
                amount, r'CheckoutFields', 'amount'),
            currency: BuiltValueNullFieldError.checkNotNull(
                currency, r'CheckoutFields', 'currency'),
            name: BuiltValueNullFieldError.checkNotNull(
                name, r'CheckoutFields', 'name'),
            description: BuiltValueNullFieldError.checkNotNull(
                description, r'CheckoutFields', 'description'),
            prefill: _prefill?.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'prefill';
        _prefill?.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'CheckoutFields', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
