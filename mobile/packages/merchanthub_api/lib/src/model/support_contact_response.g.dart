// GENERATED CODE - DO NOT MODIFY BY HAND
part of 'support_contact_response.dart';

class _$SupportContactResponse extends SupportContactResponse {
  @override
  final String email;
  @override
  final String? supportPath;

  factory _$SupportContactResponse(
          [void Function(SupportContactResponseBuilder)? updates]) =>
      (SupportContactResponseBuilder()..update(updates))._build();

  _$SupportContactResponse._({required this.email, this.supportPath}) : super._();

  @override
  SupportContactResponse rebuild(void Function(SupportContactResponseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  SupportContactResponseBuilder toBuilder() => SupportContactResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is SupportContactResponse && email == other.email && supportPath == other.supportPath;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, email.hashCode);
    _$hash = $jc(_$hash, supportPath.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'SupportContactResponse')..add('email', email)).toString();
  }
}

class SupportContactResponseBuilder
    implements Builder<SupportContactResponse, SupportContactResponseBuilder> {
  _$SupportContactResponse? _$v;
  String? _email;
  String? get email => _$this._email;
  set email(String? email) => _$this._email = email;
  String? _supportPath;
  String? get supportPath => _$this._supportPath;
  set supportPath(String? supportPath) => _$this._supportPath = supportPath;

  SupportContactResponseBuilder() {
    SupportContactResponse._defaults(this);
  }

  SupportContactResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _email = $v.email;
      _supportPath = $v.supportPath;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(SupportContactResponse other) {
    _$v = other as _$SupportContactResponse;
  }

  @override
  void update(void Function(SupportContactResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  SupportContactResponse build() => _build();

  _$SupportContactResponse _build() {
    final _$result = _$v ??
        _$SupportContactResponse._(
          email: BuiltValueNullFieldError.checkNotNull(email, r'SupportContactResponse', 'email'),
          supportPath: supportPath,
        );
    replace(_$result);
    return _$result;
  }
}
