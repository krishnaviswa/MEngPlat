// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'platform_analytics_series.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const PlatformAnalyticsSeriesGranularityEnum
    _$platformAnalyticsSeriesGranularityEnum_day =
    const PlatformAnalyticsSeriesGranularityEnum._('day');
const PlatformAnalyticsSeriesGranularityEnum
    _$platformAnalyticsSeriesGranularityEnum_week =
    const PlatformAnalyticsSeriesGranularityEnum._('week');

PlatformAnalyticsSeriesGranularityEnum
    _$platformAnalyticsSeriesGranularityEnumValueOf(String name) {
  switch (name) {
    case 'day':
      return _$platformAnalyticsSeriesGranularityEnum_day;
    case 'week':
      return _$platformAnalyticsSeriesGranularityEnum_week;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<PlatformAnalyticsSeriesGranularityEnum>
    _$platformAnalyticsSeriesGranularityEnumValues = BuiltSet<
        PlatformAnalyticsSeriesGranularityEnum>(const <PlatformAnalyticsSeriesGranularityEnum>[
  _$platformAnalyticsSeriesGranularityEnum_day,
  _$platformAnalyticsSeriesGranularityEnum_week,
]);

Serializer<PlatformAnalyticsSeriesGranularityEnum>
    _$platformAnalyticsSeriesGranularityEnumSerializer =
    _$PlatformAnalyticsSeriesGranularityEnumSerializer();

class _$PlatformAnalyticsSeriesGranularityEnumSerializer
    implements PrimitiveSerializer<PlatformAnalyticsSeriesGranularityEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'day': 'day',
    'week': 'week',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'day': 'day',
    'week': 'week',
  };

  @override
  final Iterable<Type> types = const <Type>[
    PlatformAnalyticsSeriesGranularityEnum
  ];
  @override
  final String wireName = 'PlatformAnalyticsSeriesGranularityEnum';

  @override
  Object serialize(Serializers serializers,
          PlatformAnalyticsSeriesGranularityEnum object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  PlatformAnalyticsSeriesGranularityEnum deserialize(
          Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      PlatformAnalyticsSeriesGranularityEnum.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

class _$PlatformAnalyticsSeries extends PlatformAnalyticsSeries {
  @override
  final PlatformAnalyticsSeriesGranularityEnum granularity;
  @override
  final int days;
  @override
  final BuiltMap<String, BuiltList<JsonObject>> series;

  factory _$PlatformAnalyticsSeries(
          [void Function(PlatformAnalyticsSeriesBuilder)? updates]) =>
      (PlatformAnalyticsSeriesBuilder()..update(updates))._build();

  _$PlatformAnalyticsSeries._(
      {required this.granularity, required this.days, required this.series})
      : super._();
  @override
  PlatformAnalyticsSeries rebuild(
          void Function(PlatformAnalyticsSeriesBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PlatformAnalyticsSeriesBuilder toBuilder() =>
      PlatformAnalyticsSeriesBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PlatformAnalyticsSeries &&
        granularity == other.granularity &&
        days == other.days &&
        series == other.series;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, granularity.hashCode);
    _$hash = $jc(_$hash, days.hashCode);
    _$hash = $jc(_$hash, series.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PlatformAnalyticsSeries')
          ..add('granularity', granularity)
          ..add('days', days)
          ..add('series', series))
        .toString();
  }
}

class PlatformAnalyticsSeriesBuilder
    implements
        Builder<PlatformAnalyticsSeries, PlatformAnalyticsSeriesBuilder> {
  _$PlatformAnalyticsSeries? _$v;

  PlatformAnalyticsSeriesGranularityEnum? _granularity;
  PlatformAnalyticsSeriesGranularityEnum? get granularity =>
      _$this._granularity;
  set granularity(PlatformAnalyticsSeriesGranularityEnum? granularity) =>
      _$this._granularity = granularity;

  int? _days;
  int? get days => _$this._days;
  set days(int? days) => _$this._days = days;

  MapBuilder<String, BuiltList<JsonObject>>? _series;
  MapBuilder<String, BuiltList<JsonObject>> get series =>
      _$this._series ??= MapBuilder<String, BuiltList<JsonObject>>();
  set series(MapBuilder<String, BuiltList<JsonObject>>? series) =>
      _$this._series = series;

  PlatformAnalyticsSeriesBuilder() {
    PlatformAnalyticsSeries._defaults(this);
  }

  PlatformAnalyticsSeriesBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _granularity = $v.granularity;
      _days = $v.days;
      _series = $v.series.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PlatformAnalyticsSeries other) {
    _$v = other as _$PlatformAnalyticsSeries;
  }

  @override
  void update(void Function(PlatformAnalyticsSeriesBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PlatformAnalyticsSeries build() => _build();

  _$PlatformAnalyticsSeries _build() {
    _$PlatformAnalyticsSeries _$result;
    try {
      _$result = _$v ??
          _$PlatformAnalyticsSeries._(
            granularity: BuiltValueNullFieldError.checkNotNull(
                granularity, r'PlatformAnalyticsSeries', 'granularity'),
            days: BuiltValueNullFieldError.checkNotNull(
                days, r'PlatformAnalyticsSeries', 'days'),
            series: series.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'series';
        series.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'PlatformAnalyticsSeries', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
