// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'monitoring_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(measurementsRepository)
final measurementsRepositoryProvider = MeasurementsRepositoryProvider._();

final class MeasurementsRepositoryProvider
    extends
        $FunctionalProvider<
          MeasurementsRepository,
          MeasurementsRepository,
          MeasurementsRepository
        >
    with $Provider<MeasurementsRepository> {
  MeasurementsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'measurementsRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$measurementsRepositoryHash();

  @$internal
  @override
  $ProviderElement<MeasurementsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  MeasurementsRepository create(Ref ref) {
    return measurementsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MeasurementsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MeasurementsRepository>(value),
    );
  }
}

String _$measurementsRepositoryHash() =>
    r'229fb164c05f35f4623d55017339c2c21aff926c';

@ProviderFor(activeSensors)
final activeSensorsProvider = ActiveSensorsFamily._();

final class ActiveSensorsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Sensor>>,
          List<Sensor>,
          FutureOr<List<Sensor>>
        >
    with $FutureModifier<List<Sensor>>, $FutureProvider<List<Sensor>> {
  ActiveSensorsProvider._({
    required ActiveSensorsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'activeSensorsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$activeSensorsHash();

  @override
  String toString() {
    return r'activeSensorsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<Sensor>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Sensor>> create(Ref ref) {
    final argument = this.argument as String;
    return activeSensors(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ActiveSensorsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$activeSensorsHash() => r'866468eec35d374d50c28c11d406090ce66cdd49';

final class ActiveSensorsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<Sensor>>, String> {
  ActiveSensorsFamily._()
    : super(
        retry: null,
        name: r'activeSensorsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ActiveSensorsProvider call(String zoneId) =>
      ActiveSensorsProvider._(argument: zoneId, from: this);

  @override
  String toString() => r'activeSensorsProvider';
}

@ProviderFor(latestMeasurements)
final latestMeasurementsProvider = LatestMeasurementsFamily._();

final class LatestMeasurementsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<TemperatureLog>>,
          List<TemperatureLog>,
          Stream<List<TemperatureLog>>
        >
    with
        $FutureModifier<List<TemperatureLog>>,
        $StreamProvider<List<TemperatureLog>> {
  LatestMeasurementsProvider._({
    required LatestMeasurementsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'latestMeasurementsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$latestMeasurementsHash();

  @override
  String toString() {
    return r'latestMeasurementsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<TemperatureLog>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<TemperatureLog>> create(Ref ref) {
    final argument = this.argument as String;
    return latestMeasurements(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is LatestMeasurementsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$latestMeasurementsHash() =>
    r'00f9ca7e784f3599fe8be3cbde2aba6748a5e7be';

final class LatestMeasurementsFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<TemperatureLog>>, String> {
  LatestMeasurementsFamily._()
    : super(
        retry: null,
        name: r'latestMeasurementsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  LatestMeasurementsProvider call(String zoneId) =>
      LatestMeasurementsProvider._(argument: zoneId, from: this);

  @override
  String toString() => r'latestMeasurementsProvider';
}

@ProviderFor(sensorHistory)
final sensorHistoryProvider = SensorHistoryFamily._();

final class SensorHistoryProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<TemperatureLog>>,
          List<TemperatureLog>,
          FutureOr<List<TemperatureLog>>
        >
    with
        $FutureModifier<List<TemperatureLog>>,
        $FutureProvider<List<TemperatureLog>> {
  SensorHistoryProvider._({
    required SensorHistoryFamily super.from,
    required (String, Duration) super.argument,
  }) : super(
         retry: null,
         name: r'sensorHistoryProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$sensorHistoryHash();

  @override
  String toString() {
    return r'sensorHistoryProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<TemperatureLog>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<TemperatureLog>> create(Ref ref) {
    final argument = this.argument as (String, Duration);
    return sensorHistory(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is SensorHistoryProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$sensorHistoryHash() => r'5e80c13d6ac027ea0964caccce1aee3c7e87c5e1';

final class SensorHistoryFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<TemperatureLog>>,
          (String, Duration)
        > {
  SensorHistoryFamily._()
    : super(
        retry: null,
        name: r'sensorHistoryProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  SensorHistoryProvider call(String sensorId, Duration range) =>
      SensorHistoryProvider._(argument: (sensorId, range), from: this);

  @override
  String toString() => r'sensorHistoryProvider';
}

@ProviderFor(alarms)
final alarmsProvider = AlarmsFamily._();

final class AlarmsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<AlarmListItem>>,
          List<AlarmListItem>,
          FutureOr<List<AlarmListItem>>
        >
    with
        $FutureModifier<List<AlarmListItem>>,
        $FutureProvider<List<AlarmListItem>> {
  AlarmsProvider._({
    required AlarmsFamily super.from,
    required (String, {bool activeOnly}) super.argument,
  }) : super(
         retry: null,
         name: r'alarmsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$alarmsHash();

  @override
  String toString() {
    return r'alarmsProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<AlarmListItem>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<AlarmListItem>> create(Ref ref) {
    final argument = this.argument as (String, {bool activeOnly});
    return alarms(ref, argument.$1, activeOnly: argument.activeOnly);
  }

  @override
  bool operator ==(Object other) {
    return other is AlarmsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$alarmsHash() => r'c0c8b1ab9ae8c08b7e4f8c53bebd9b73b0ca9682';

final class AlarmsFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<AlarmListItem>>,
          (String, {bool activeOnly})
        > {
  AlarmsFamily._()
    : super(
        retry: null,
        name: r'alarmsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  AlarmsProvider call(String zoneId, {bool activeOnly = true}) =>
      AlarmsProvider._(argument: (zoneId, activeOnly: activeOnly), from: this);

  @override
  String toString() => r'alarmsProvider';
}

@ProviderFor(AlarmAction)
final alarmActionProvider = AlarmActionProvider._();

final class AlarmActionProvider
    extends $AsyncNotifierProvider<AlarmAction, void> {
  AlarmActionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'alarmActionProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$alarmActionHash();

  @$internal
  @override
  AlarmAction create() => AlarmAction();
}

String _$alarmActionHash() => r'0887386fb813134494600fa1990cdf5e43cae5bd';

abstract class _$AlarmAction extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(AnnotationAction)
final annotationActionProvider = AnnotationActionProvider._();

final class AnnotationActionProvider
    extends $AsyncNotifierProvider<AnnotationAction, void> {
  AnnotationActionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'annotationActionProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$annotationActionHash();

  @$internal
  @override
  AnnotationAction create() => AnnotationAction();
}

String _$annotationActionHash() => r'7a7d4b6f34fedeba470e8577f5efae61609ada1c';

abstract class _$AnnotationAction extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
