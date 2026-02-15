// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard_badges_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(DashboardBadges)
final dashboardBadgesProvider = DashboardBadgesProvider._();

final class DashboardBadgesProvider
    extends $AsyncNotifierProvider<DashboardBadges, Map<String, String?>> {
  DashboardBadgesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dashboardBadgesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dashboardBadgesHash();

  @$internal
  @override
  DashboardBadges create() => DashboardBadges();
}

String _$dashboardBadgesHash() => r'b37688cbca3f0d786697432e1e1fe5e174bbc1e7';

abstract class _$DashboardBadges extends $AsyncNotifier<Map<String, String?>> {
  FutureOr<Map<String, String?>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<Map<String, String?>>, Map<String, String?>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<Map<String, String?>>,
                Map<String, String?>
              >,
              AsyncValue<Map<String, String?>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
