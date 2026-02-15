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

String _$hrControllerHash() => r'767d5e00dd21e89e1e4cd9111b654a23e156269c';

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
