// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'topic_item.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const TopicItemSentimentEnum _$topicItemSentimentEnum_positive =
    const TopicItemSentimentEnum._('positive');
const TopicItemSentimentEnum _$topicItemSentimentEnum_negative =
    const TopicItemSentimentEnum._('negative');
const TopicItemSentimentEnum _$topicItemSentimentEnum_mixed =
    const TopicItemSentimentEnum._('mixed');

TopicItemSentimentEnum _$topicItemSentimentEnumValueOf(String name) {
  switch (name) {
    case 'positive':
      return _$topicItemSentimentEnum_positive;
    case 'negative':
      return _$topicItemSentimentEnum_negative;
    case 'mixed':
      return _$topicItemSentimentEnum_mixed;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<TopicItemSentimentEnum> _$topicItemSentimentEnumValues =
    BuiltSet<TopicItemSentimentEnum>(const <TopicItemSentimentEnum>[
  _$topicItemSentimentEnum_positive,
  _$topicItemSentimentEnum_negative,
  _$topicItemSentimentEnum_mixed,
]);

Serializer<TopicItemSentimentEnum> _$topicItemSentimentEnumSerializer =
    _$TopicItemSentimentEnumSerializer();

class _$TopicItemSentimentEnumSerializer
    implements PrimitiveSerializer<TopicItemSentimentEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'positive': 'positive',
    'negative': 'negative',
    'mixed': 'mixed',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'positive': 'positive',
    'negative': 'negative',
    'mixed': 'mixed',
  };

  @override
  final Iterable<Type> types = const <Type>[TopicItemSentimentEnum];
  @override
  final String wireName = 'TopicItemSentimentEnum';

  @override
  Object serialize(Serializers serializers, TopicItemSentimentEnum object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  TopicItemSentimentEnum deserialize(Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      TopicItemSentimentEnum.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

class _$TopicItem extends TopicItem {
  @override
  final String label;
  @override
  final int count;
  @override
  final TopicItemSentimentEnum sentiment;
  @override
  final String exampleQuote;

  factory _$TopicItem([void Function(TopicItemBuilder)? updates]) =>
      (TopicItemBuilder()..update(updates))._build();

  _$TopicItem._(
      {required this.label,
      required this.count,
      required this.sentiment,
      required this.exampleQuote})
      : super._();
  @override
  TopicItem rebuild(void Function(TopicItemBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  TopicItemBuilder toBuilder() => TopicItemBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is TopicItem &&
        label == other.label &&
        count == other.count &&
        sentiment == other.sentiment &&
        exampleQuote == other.exampleQuote;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, label.hashCode);
    _$hash = $jc(_$hash, count.hashCode);
    _$hash = $jc(_$hash, sentiment.hashCode);
    _$hash = $jc(_$hash, exampleQuote.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'TopicItem')
          ..add('label', label)
          ..add('count', count)
          ..add('sentiment', sentiment)
          ..add('exampleQuote', exampleQuote))
        .toString();
  }
}

class TopicItemBuilder implements Builder<TopicItem, TopicItemBuilder> {
  _$TopicItem? _$v;

  String? _label;
  String? get label => _$this._label;
  set label(String? label) => _$this._label = label;

  int? _count;
  int? get count => _$this._count;
  set count(int? count) => _$this._count = count;

  TopicItemSentimentEnum? _sentiment;
  TopicItemSentimentEnum? get sentiment => _$this._sentiment;
  set sentiment(TopicItemSentimentEnum? sentiment) =>
      _$this._sentiment = sentiment;

  String? _exampleQuote;
  String? get exampleQuote => _$this._exampleQuote;
  set exampleQuote(String? exampleQuote) => _$this._exampleQuote = exampleQuote;

  TopicItemBuilder() {
    TopicItem._defaults(this);
  }

  TopicItemBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _label = $v.label;
      _count = $v.count;
      _sentiment = $v.sentiment;
      _exampleQuote = $v.exampleQuote;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(TopicItem other) {
    _$v = other as _$TopicItem;
  }

  @override
  void update(void Function(TopicItemBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  TopicItem build() => _build();

  _$TopicItem _build() {
    final _$result = _$v ??
        _$TopicItem._(
          label: BuiltValueNullFieldError.checkNotNull(
              label, r'TopicItem', 'label'),
          count: BuiltValueNullFieldError.checkNotNull(
              count, r'TopicItem', 'count'),
          sentiment: BuiltValueNullFieldError.checkNotNull(
              sentiment, r'TopicItem', 'sentiment'),
          exampleQuote: BuiltValueNullFieldError.checkNotNull(
              exampleQuote, r'TopicItem', 'exampleQuote'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
