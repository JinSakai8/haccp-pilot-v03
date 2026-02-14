// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gmp_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(GmpFormSubmission)
final gmpFormSubmissionProvider = GmpFormSubmissionProvider._();

final class GmpFormSubmissionProvider
    extends $AsyncNotifierProvider<GmpFormSubmission, void> {
  GmpFormSubmissionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'gmpFormSubmissionProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$gmpFormSubmissionHash();

  @$internal
  @override
  GmpFormSubmission create() => GmpFormSubmission();
}

String _$gmpFormSubmissionHash() => r'869f90461b670c71213ed2fe4ae87659758ca172';

abstract class _$GmpFormSubmission extends $AsyncNotifier<void> {
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

@ProviderFor(gmpHistory)
final gmpHistoryProvider = GmpHistoryProvider._();

final class GmpHistoryProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Map<String, dynamic>>>,
          List<Map<String, dynamic>>,
          FutureOr<List<Map<String, dynamic>>>
        >
    with
        $FutureModifier<List<Map<String, dynamic>>>,
        $FutureProvider<List<Map<String, dynamic>>> {
  GmpHistoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'gmpHistoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$gmpHistoryHash();

  @$internal
  @override
  $FutureProviderElement<List<Map<String, dynamic>>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Map<String, dynamic>>> create(Ref ref) {
    return gmpHistory(ref);
  }
}

String _$gmpHistoryHash() => r'2a94e7201c159e1ce432eac3cb261b86fb4d8988';
