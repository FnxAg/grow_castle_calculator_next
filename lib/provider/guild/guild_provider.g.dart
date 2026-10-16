// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'guild_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 当前用户所在公会的总分

@ProviderFor(GuildTotalScore)
final guildTotalScoreProvider = GuildTotalScoreProvider._();

/// 当前用户所在公会的总分
final class GuildTotalScoreProvider
    extends $NotifierProvider<GuildTotalScore, int?> {
  /// 当前用户所在公会的总分
  GuildTotalScoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'guildTotalScoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$guildTotalScoreHash();

  @$internal
  @override
  GuildTotalScore create() => GuildTotalScore();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int?>(value),
    );
  }
}

String _$guildTotalScoreHash() => r'da39fd6d760a1da1d3d1339bf634e7350eb2c37f';

/// 当前用户所在公会的总分

abstract class _$GuildTotalScore extends $Notifier<int?> {
  int? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<int?, int?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int?, int?>,
              int?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
