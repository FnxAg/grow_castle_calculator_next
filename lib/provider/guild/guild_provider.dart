/// 公会数据的 Riverpod 状态层
library;

import 'package:grow_castle_calculator_next/core/service/api.dart';
import 'package:grow_castle_calculator_next/provider/userdata/user_data_selectors.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'guild_provider.g.dart';

/// 当前用户所在公会的总分
@Riverpod(keepAlive: true)
class GuildTotalScore extends _$GuildTotalScore {
  @override
  int? build() {
    ref.watch(currentUserGuildProvider);
    return null;
  }

  /// 成员列表加载完成后回填
  void publishFromMembers(List<GuildMember> members) {
    state = members.fold<int>(0, (sum, member) => sum + member.score);
  }
}
