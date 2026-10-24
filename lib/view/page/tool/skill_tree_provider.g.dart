// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'skill_tree_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SkillTreeNotifier)
final skillTreeProvider = SkillTreeNotifierProvider._();

final class SkillTreeNotifierProvider
    extends $NotifierProvider<SkillTreeNotifier, SkillTreeState> {
  SkillTreeNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'skillTreeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$skillTreeNotifierHash();

  @$internal
  @override
  SkillTreeNotifier create() => SkillTreeNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SkillTreeState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SkillTreeState>(value),
    );
  }
}

String _$skillTreeNotifierHash() => r'9a330eade3ec84815d04ee67d6b4f213e140df0c';

abstract class _$SkillTreeNotifier extends $Notifier<SkillTreeState> {
  SkillTreeState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<SkillTreeState, SkillTreeState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SkillTreeState, SkillTreeState>,
              SkillTreeState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
