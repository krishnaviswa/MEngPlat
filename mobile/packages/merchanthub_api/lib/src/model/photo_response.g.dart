// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'photo_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$PhotoResponse extends PhotoResponse {
  @override
  final String id;
  @override
  final String url;
  @override
  final String? caption;
  @override
  final String photoType;
  @override
  final AIAnalysisResponse? aiAnalysis;

  factory _$PhotoResponse([void Function(PhotoResponseBuilder)? updates]) =>
      (PhotoResponseBuilder()..update(updates))._build();

  _$PhotoResponse._(
      {required this.id,
      required this.url,
      this.caption,
      required this.photoType,
      this.aiAnalysis})
      : super._();
  @override
  PhotoResponse rebuild(void Function(PhotoResponseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PhotoResponseBuilder toBuilder() => PhotoResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PhotoResponse &&
        id == other.id &&
        url == other.url &&
        caption == other.caption &&
        photoType == other.photoType &&
        aiAnalysis == other.aiAnalysis;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, url.hashCode);
    _$hash = $jc(_$hash, caption.hashCode);
    _$hash = $jc(_$hash, photoType.hashCode);
    _$hash = $jc(_$hash, aiAnalysis.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PhotoResponse')
          ..add('id', id)
          ..add('url', url)
          ..add('caption', caption)
          ..add('photoType', photoType)
          ..add('aiAnalysis', aiAnalysis))
        .toString();
  }
}

class PhotoResponseBuilder
    implements Builder<PhotoResponse, PhotoResponseBuilder> {
  _$PhotoResponse? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _url;
  String? get url => _$this._url;
  set url(String? url) => _$this._url = url;

  String? _caption;
  String? get caption => _$this._caption;
  set caption(String? caption) => _$this._caption = caption;

  String? _photoType;
  String? get photoType => _$this._photoType;
  set photoType(String? photoType) => _$this._photoType = photoType;

  AIAnalysisResponseBuilder? _aiAnalysis;
  AIAnalysisResponseBuilder get aiAnalysis =>
      _$this._aiAnalysis ??= AIAnalysisResponseBuilder();
  set aiAnalysis(AIAnalysisResponseBuilder? aiAnalysis) =>
      _$this._aiAnalysis = aiAnalysis;

  PhotoResponseBuilder() {
    PhotoResponse._defaults(this);
  }

  PhotoResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _url = $v.url;
      _caption = $v.caption;
      _photoType = $v.photoType;
      _aiAnalysis = $v.aiAnalysis?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PhotoResponse other) {
    _$v = other as _$PhotoResponse;
  }

  @override
  void update(void Function(PhotoResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PhotoResponse build() => _build();

  _$PhotoResponse _build() {
    _$PhotoResponse _$result;
    try {
      _$result = _$v ??
          _$PhotoResponse._(
            id: BuiltValueNullFieldError.checkNotNull(
                id, r'PhotoResponse', 'id'),
            url: BuiltValueNullFieldError.checkNotNull(
                url, r'PhotoResponse', 'url'),
            caption: caption,
            photoType: BuiltValueNullFieldError.checkNotNull(
                photoType, r'PhotoResponse', 'photoType'),
            aiAnalysis: _aiAnalysis?.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'aiAnalysis';
        _aiAnalysis?.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'PhotoResponse', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
