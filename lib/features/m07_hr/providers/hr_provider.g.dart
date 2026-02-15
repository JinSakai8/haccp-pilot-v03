// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hr_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for HR Repository

@ProviderFor(hrRepository)
final hrRepositoryProvider = HrRepositoryProvider._();

/// Provider for HR Repository

final class HrRepositoryProvider
    extends $FunctionalProvider<HrRepository, HrRepository, HrRepository>
    with $Provider<HrRepository> {
  /// Provider for HR Repository
  HrRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'hrRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$hrRepositoryHash();

  @$internal
  @override
  $ProviderElement<HrRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  HrRepository create(Ref ref) {
    return hrRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HrRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HrRepository>(value),
    );
  }
}

String _$hrRepositoryHash() => r'5069c47c21f347bf2dd8fbb0d99cb33b17a45e20';

/// Provider to fetch all employees

@ProviderFor(hrEmployees)
final hrEmployeesProvider = HrEmployeesProvider._();

/// Provider to fetch all employees

final class HrEmployeesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Employee>>,
          List<Employee>,
          FutureOr<List<Employee>>
        >
    with $FutureModifier<List<Employee>>, $FutureProvider<List<Employee>> {
  /// Provider to fetch all employees
  HrEmployeesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'hrEmployeesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$hrEmployeesHash();

  @$internal
  @override
  $FutureProviderElement<List<Employee>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Employee>> create(Ref ref) {
    return hrEmployees(ref);
  }
}

String _$hrEmployeesHash() => r'78c21d7142cb800bea4599d130ce41ff3e510d10';

/// Provider to fetch available zones

@ProviderFor(hrZones)
final hrZonesProvider = HrZonesProvider._();

/// Provider to fetch available zones

final class HrZonesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Zone>>,
          List<Zone>,
          FutureOr<List<Zone>>
        >
    with $FutureModifier<List<Zone>>, $FutureProvider<List<Zone>> {
  /// Provider to fetch available zones
  HrZonesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'hrZonesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$hrZonesHash();

  @$internal
  @override
  $FutureProviderElement<List<Zone>> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<Zone>> create(Ref ref) {
    return hrZones(ref);
  }
}

String _$hrZonesHash() => r'd0f4628a02495109295dcd3ffdd673f0fd79a24f';

/// AsyncNotifier for HR actions (create, update, delete)

@ProviderFor(HrController)
final hrControllerProvider = HrControllerProvider._();

/// AsyncNotifier for HR actions (create, update, delete)
final class HrControllerProvider
    extends $AsyncNotifierProvider<HrController, void> {
  /// AsyncNotifier for HR actions (create, update, delete)
  HrControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'hrControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$hrControllerHash();

  @$internal
  @override
  HrController create() => HrController();
}

String _$hrControllerHash() => r'bf7fa511297746e4b9c70308faba460c721acf91';

/// AsyncNotifier for HR actions (create, update, delete)

abstract class _$HrController extends $AsyncNotifier<void> {
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
