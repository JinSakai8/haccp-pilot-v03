// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ghp_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(GhpFormSubmission)
final ghpFormSubmissionProvider = GhpFormSubmissionProvider._();

final class GhpFormSubmissionProvider
    extends $AsyncNotifierProvider<GhpFormSubmission, void> {
  GhpFormSubmissionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ghpFormSubmissionProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ghpFormSubmissionHash();

  @$internal
  @override
  GhpFormSubmission create() => GhpFormSubmission();
}

String _$ghpFormSubmissionHash() => r'1700d54de01fac57b0831677404b82fbe46d56ba';

abstract class _$GhpFormSubmission extends $AsyncNotifier<void> {
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

@ProviderFor(ghpHistory)
final ghpHistoryProvider = GhpHistoryProvider._();

final class GhpHistoryProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Map<String, dynamic>>>,
          List<Map<String, dynamic>>,
          FutureOr<List<Map<String, dynamic>>>
        >
    with
        $FutureModifier<List<Map<String, dynamic>>>,
        $FutureProvider<List<Map<String, dynamic>>> {
  GhpHistoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ghpHistoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ghpHistoryHash();

  @$internal
  @override
  $FutureProviderElement<List<Map<String, dynamic>>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Map<String, dynamic>>> create(Ref ref) {
    return ghpHistory(ref);
  }
}

String _$ghpHistoryHash() => r'4cdf86b07b10596aecc3b2c2eaa5a28e94cf6333';
