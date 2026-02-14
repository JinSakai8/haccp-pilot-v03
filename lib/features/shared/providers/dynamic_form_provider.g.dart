// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dynamic_form_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(DynamicFormNotifier)
final dynamicFormProvider = DynamicFormNotifierFamily._();

final class DynamicFormNotifierProvider
    extends $NotifierProvider<DynamicFormNotifier, DynamicFormState> {
  DynamicFormNotifierProvider._({
    required DynamicFormNotifierFamily super.from,
    required (String, FormDefinition) super.argument,
  }) : super(
         retry: null,
         name: r'dynamicFormProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$dynamicFormNotifierHash();

  @override
  String toString() {
    return r'dynamicFormProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  DynamicFormNotifier create() => DynamicFormNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DynamicFormState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DynamicFormState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is DynamicFormNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$dynamicFormNotifierHash() =>
    r'd1e3e90de7274266ae6b510027334d9a7eafcd81';

final class DynamicFormNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          DynamicFormNotifier,
          DynamicFormState,
          DynamicFormState,
          DynamicFormState,
          (String, FormDefinition)
        > {
  DynamicFormNotifierFamily._()
    : super(
        retry: null,
        name: r'dynamicFormProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  DynamicFormNotifierProvider call(String formId, FormDefinition definition) =>
      DynamicFormNotifierProvider._(argument: (formId, definition), from: this);

  @override
  String toString() => r'dynamicFormProvider';
}

abstract class _$DynamicFormNotifier extends $Notifier<DynamicFormState> {
  late final _$args = ref.$arg as (String, FormDefinition);
  String get formId => _$args.$1;
  FormDefinition get definition => _$args.$2;

  DynamicFormState build(String formId, FormDefinition definition);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<DynamicFormState, DynamicFormState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DynamicFormState, DynamicFormState>,
              DynamicFormState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args.$1, _$args.$2));
  }
}
