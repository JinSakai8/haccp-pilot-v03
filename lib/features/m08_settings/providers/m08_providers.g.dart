// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'm08_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(VenueSettingsController)
final venueSettingsControllerProvider = VenueSettingsControllerFamily._();

final class VenueSettingsControllerProvider
    extends
        $AsyncNotifierProvider<VenueSettingsController, Map<String, dynamic>?> {
  VenueSettingsControllerProvider._({
    required VenueSettingsControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'venueSettingsControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$venueSettingsControllerHash();

  @override
  String toString() {
    return r'venueSettingsControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  VenueSettingsController create() => VenueSettingsController();

  @override
  bool operator ==(Object other) {
    return other is VenueSettingsControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$venueSettingsControllerHash() =>
    r'1b57b68a7c7ae3a4e4738a684129fba9e1d363dc';

final class VenueSettingsControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          VenueSettingsController,
          AsyncValue<Map<String, dynamic>?>,
          Map<String, dynamic>?,
          FutureOr<Map<String, dynamic>?>,
          String
        > {
  VenueSettingsControllerFamily._()
    : super(
        retry: null,
        name: r'venueSettingsControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  VenueSettingsControllerProvider call(String venueId) =>
      VenueSettingsControllerProvider._(argument: venueId, from: this);

  @override
  String toString() => r'venueSettingsControllerProvider';
}

abstract class _$VenueSettingsController
    extends $AsyncNotifier<Map<String, dynamic>?> {
  late final _$args = ref.$arg as String;
  String get venueId => _$args;

  FutureOr<Map<String, dynamic>?> build(String venueId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<Map<String, dynamic>?>, Map<String, dynamic>?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<Map<String, dynamic>?>,
                Map<String, dynamic>?
              >,
              AsyncValue<Map<String, dynamic>?>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
