// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reports_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(reportsRepository)
final reportsRepositoryProvider = ReportsRepositoryProvider._();

final class ReportsRepositoryProvider
    extends
        $FunctionalProvider<
          ReportsRepository,
          ReportsRepository,
          ReportsRepository
        >
    with $Provider<ReportsRepository> {
  ReportsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'reportsRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$reportsRepositoryHash();

  @$internal
  @override
  $ProviderElement<ReportsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ReportsRepository create(Ref ref) {
    return reportsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ReportsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ReportsRepository>(value),
    );
  }
}

String _$reportsRepositoryHash() => r'4187aa122dff91073634e54794e2a6e38c01771a';

@ProviderFor(pdfService)
final pdfServiceProvider = PdfServiceProvider._();

final class PdfServiceProvider
    extends $FunctionalProvider<PdfService, PdfService, PdfService>
    with $Provider<PdfService> {
  PdfServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pdfServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pdfServiceHash();

  @$internal
  @override
  $ProviderElement<PdfService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PdfService create(Ref ref) {
    return pdfService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PdfService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PdfService>(value),
    );
  }
}

String _$pdfServiceHash() => r'f2b7a77d6228127f2804a1ec5c3ac316b1bb0d5f';

@ProviderFor(driveService)
final driveServiceProvider = DriveServiceProvider._();

final class DriveServiceProvider
    extends $FunctionalProvider<DriveService, DriveService, DriveService>
    with $Provider<DriveService> {
  DriveServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'driveServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$driveServiceHash();

  @$internal
  @override
  $ProviderElement<DriveService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DriveService create(Ref ref) {
    return driveService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DriveService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DriveService>(value),
    );
  }
}

String _$driveServiceHash() => r'561f56047378f39f5c98d15cd830ebd66c2d8739';

@ProviderFor(ReportsNotifier)
final reportsProvider = ReportsNotifierProvider._();

final class ReportsNotifierProvider
    extends $AsyncNotifierProvider<ReportsNotifier, ReportData?> {
  ReportsNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'reportsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$reportsNotifierHash();

  @$internal
  @override
  ReportsNotifier create() => ReportsNotifier();
}

String _$reportsNotifierHash() => r'5e275a54ee1d16067a68d1cdceb621fa639bc740';

abstract class _$ReportsNotifier extends $AsyncNotifier<ReportData?> {
  FutureOr<ReportData?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<ReportData?>, ReportData?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<ReportData?>, ReportData?>,
              AsyncValue<ReportData?>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
