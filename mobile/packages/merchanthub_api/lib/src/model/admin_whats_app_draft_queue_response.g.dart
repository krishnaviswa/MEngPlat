// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_whats_app_draft_queue_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$AdminWhatsAppDraftQueueResponse
    extends AdminWhatsAppDraftQueueResponse {
  @override
  final BuiltList<AdminWhatsAppDraftResponse> items;
  @override
  final int total;
  @override
  final int page;
  @override
  final int pageSize;

  factory _$AdminWhatsAppDraftQueueResponse(
          [void Function(AdminWhatsAppDraftQueueResponseBuilder)? updates]) =>
      (AdminWhatsAppDraftQueueResponseBuilder()..update(updates))._build();

  _$AdminWhatsAppDraftQueueResponse._(
      {required this.items,
      required this.total,
      required this.page,
      required this.pageSize})
      : super._();
  @override
  AdminWhatsAppDraftQueueResponse rebuild(
          void Function(AdminWhatsAppDraftQueueResponseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  AdminWhatsAppDraftQueueResponseBuilder toBuilder() =>
      AdminWhatsAppDraftQueueResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is AdminWhatsAppDraftQueueResponse &&
        items == other.items &&
        total == other.total &&
        page == other.page &&
        pageSize == other.pageSize;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, items.hashCode);
    _$hash = $jc(_$hash, total.hashCode);
    _$hash = $jc(_$hash, page.hashCode);
    _$hash = $jc(_$hash, pageSize.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'AdminWhatsAppDraftQueueResponse')
          ..add('items', items)
          ..add('total', total)
          ..add('page', page)
          ..add('pageSize', pageSize))
        .toString();
  }
}

class AdminWhatsAppDraftQueueResponseBuilder
    implements
        Builder<AdminWhatsAppDraftQueueResponse,
            AdminWhatsAppDraftQueueResponseBuilder> {
  _$AdminWhatsAppDraftQueueResponse? _$v;

  ListBuilder<AdminWhatsAppDraftResponse>? _items;
  ListBuilder<AdminWhatsAppDraftResponse> get items =>
      _$this._items ??= ListBuilder<AdminWhatsAppDraftResponse>();
  set items(ListBuilder<AdminWhatsAppDraftResponse>? items) =>
      _$this._items = items;

  int? _total;
  int? get total => _$this._total;
  set total(int? total) => _$this._total = total;

  int? _page;
  int? get page => _$this._page;
  set page(int? page) => _$this._page = page;

  int? _pageSize;
  int? get pageSize => _$this._pageSize;
  set pageSize(int? pageSize) => _$this._pageSize = pageSize;

  AdminWhatsAppDraftQueueResponseBuilder() {
    AdminWhatsAppDraftQueueResponse._defaults(this);
  }

  AdminWhatsAppDraftQueueResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _items = $v.items.toBuilder();
      _total = $v.total;
      _page = $v.page;
      _pageSize = $v.pageSize;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(AdminWhatsAppDraftQueueResponse other) {
    _$v = other as _$AdminWhatsAppDraftQueueResponse;
  }

  @override
  void update(void Function(AdminWhatsAppDraftQueueResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  AdminWhatsAppDraftQueueResponse build() => _build();

  _$AdminWhatsAppDraftQueueResponse _build() {
    _$AdminWhatsAppDraftQueueResponse _$result;
    try {
      _$result = _$v ??
          _$AdminWhatsAppDraftQueueResponse._(
            items: items.build(),
            total: BuiltValueNullFieldError.checkNotNull(
                total, r'AdminWhatsAppDraftQueueResponse', 'total'),
            page: BuiltValueNullFieldError.checkNotNull(
                page, r'AdminWhatsAppDraftQueueResponse', 'page'),
            pageSize: BuiltValueNullFieldError.checkNotNull(
                pageSize, r'AdminWhatsAppDraftQueueResponse', 'pageSize'),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'items';
        items.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'AdminWhatsAppDraftQueueResponse', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
