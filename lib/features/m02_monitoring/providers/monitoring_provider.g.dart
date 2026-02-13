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
final latestMeasurementsProvider = LatestMeasurementsProvider._();

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
  LatestMeasurementsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'latestMeasurementsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$latestMeasurementsHash();

  @$internal
  @override
  $StreamProviderElement<List<TemperatureLog>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<TemperatureLog>> create(Ref ref) {
    return latestMeasurements(ref);
  }
}

String _$latestMeasurementsHash() =>
    r'85331ccea6ddb34dfb310d4e2550c65e9a0b4d44';
