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

String _$gmpFormSubmissionHash() => r'70d580cca9a0d14502c63f6eee512540f77d3dc6';

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
final gmpHistoryProvider = GmpHistoryFamily._();

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
  GmpHistoryProvider._({
    required GmpHistoryFamily super.from,
    required ({DateTime? fromDate, DateTime? toDate, String? formId})
    super.argument,
  }) : super(
         retry: null,
         name: r'gmpHistoryProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$gmpHistoryHash();

  @override
  String toString() {
    return r'gmpHistoryProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<Map<String, dynamic>>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Map<String, dynamic>>> create(Ref ref) {
    final argument =
        this.argument
            as ({DateTime? fromDate, DateTime? toDate, String? formId});
    return gmpHistory(
      ref,
      fromDate: argument.fromDate,
      toDate: argument.toDate,
      formId: argument.formId,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is GmpHistoryProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$gmpHistoryHash() => r'7d9b566098e4c73a5ff90dea021188a647b7e9b5';

final class GmpHistoryFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<Map<String, dynamic>>>,
          ({DateTime? fromDate, DateTime? toDate, String? formId})
        > {
  GmpHistoryFamily._()
    : super(
        retry: null,
        name: r'gmpHistoryProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  GmpHistoryProvider call({
    DateTime? fromDate,
    DateTime? toDate,
    String? formId,
  }) => GmpHistoryProvider._(
    argument: (fromDate: fromDate, toDate: toDate, formId: formId),
    from: this,
  );

  @override
  String toString() => r'gmpHistoryProvider';
}
