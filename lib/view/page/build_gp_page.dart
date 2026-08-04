import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:grow_castle_calculator_next/core/extension/num.dart';
import 'package:grow_castle_calculator_next/core/service/api.dart';
import 'package:grow_castle_calculator_next/core/service/ranking_cache.dart';
import 'package:grow_castle_calculator_next/data/res/store.dart';
import 'package:grow_castle_calculator_next/view/widget/pill_chip.dart';

/// 阵容经济计算页：卡片列表（名称/等级输入）与底部汇总条。
///
/// 作为抽屉页面由 [HomeTab] 挂载；输入框控制器与焦点按卡片 id 缓存在
/// State 中，切换用户时 HomeTab 通过更换 key 重建本页，控制器随之释放。
class FormationCalcPage extends StatefulWidget {
  const FormationCalcPage({super.key});

  @override
  State<FormationCalcPage> createState() => _FormationCalcPageState();
}

class _FormationCalcPageState extends State<FormationCalcPage> {
  final Map<int, FocusNode> _numberFocusNodes = {};
  final Map<int, FocusNode> _textFocusNodes = {};
  final Map<int, TextEditingController> _numberControllers = {};
  final Map<int, TextEditingController> _textControllers = {};

  FocusNode _focusNodeFor(int id, Map<int, FocusNode> cache) {
    return cache.putIfAbsent(id, () => FocusNode());
  }

  TextEditingController _numberControllerFor(int id) {
    return _numberControllers.putIfAbsent(id, () {
      final c = TextEditingController(text: Stores.infoStore.getNumberValue(id));
      c.addListener(() {
        Stores.infoStore.setNumberValue(id, c.text);
      });
      return c;
    });
  }

  TextEditingController _textControllerFor(int id) {
    return _textControllers.putIfAbsent(id, () {
      final c = TextEditingController(text: Stores.infoStore.getTextValue(id));
      c.addListener(() {
        Stores.infoStore.setTextValue(id, c.text);
      });
      return c;
    });
  }

  @override
  void dispose() {
    for (final node in _numberFocusNodes.values) {
      node.dispose();
    }
    for (final node in _textFocusNodes.values) {
      node.dispose();
    }
    for (final c in _numberControllers.values) {
      c.dispose();
    }
    for (final c in _textControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _removeCard(int id) {
    _numberFocusNodes.remove(id)?.dispose();
    _textFocusNodes.remove(id)?.dispose();
    _numberControllers.remove(id)?.dispose();
    _textControllers.remove(id)?.dispose();
    // 列表重建由 store 的 cardIdsNotifier 驱动
    Stores.infoStore.removeCard(id);
  }

  /// 5 秒冷却，避免用户连续点击联网查询按钮导致多次请求
  static const Duration _queryCooldown = Duration(seconds: 5);
  DateTime? _lastQueryAt;
  bool _querying = false;

  /// 玩家赛季榜排名（前 300 内才显示，不在榜单则隐藏）
  int? _playerRank;

  @override
  void initState() {
    super.initState();
    _loadPlayerRank();
  }

  /// 从玩家赛季榜缓存/接口获取当前用户的排名（大小写不敏感匹配）
  Future<void> _loadPlayerRank() async {
    final result = await RankingCache.playerRanking();
    if (!mounted) return;
    final currentUser = Stores.infoStore.getCurrentUsername();
    setState(() {
      _playerRank = null;
      if (result is List<PlayerRankInfo>) {
        for (final p in result) {
          if (p.name.toLowerCase() == currentUser.toLowerCase()) {
            _playerRank = p.rank;
            break;
          }
        }
      }
    });
  }

  /// 联网查询当前用户的波数与赛季波数，成功写入 store，失败弹 SnackBar
  Future<void> _queryOnline() async {
    final now = DateTime.now();
    final last = _lastQueryAt;
    if (last != null && now.difference(last) < _queryCooldown) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('查询过于频繁，请稍后后再试')),
      );
      return;
    }
    // 先记录时间再发起请求：查询进行中也同样受冷却保护
    _lastQueryAt = now;
    setState(() => _querying = true);

    final name = Stores.infoStore.getCurrentUsername();
    final result = await PlayerApiService.query(name);

    if (!mounted) return;
    setState(() => _querying = false);

    if (result is PlayerQueryResult) {
      // 格式化一次并固定，切换页面/重建时保持上次查询的状态不变
      String lastOnline =
          PlayerApiService.formatLastOnline(result.queryDate, DateTime.now());
      
      // 封禁检测
      if (result.wave == 0 && result.queryDate.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('用户「$name」已被封禁')),
        );
        lastOnline = 'Banned';
        return;
      }

      Stores.infoStore.applyOnlineQuery(
        result.wave,
        result.seasonalScore,
        lastOnline: lastOnline,
      );
      // 查询成功：顺带后台预取公开榜单（TTL 缓存，15 分钟内不重复请求），
      // 供公会页/后续排行榜页直接使用
      RankingCache.playerRanking();
      RankingCache.hellRanking();
      if (Stores.infoStore.getCurrentUserGuild().isNotEmpty) {
        RankingCache.guildRanking();
      }
      // 查询后刷新玩家排名展示
      _loadPlayerRank();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('数据获取成功：用户「$name」, 波数 ${result.wave.format()}, 赛季波数 ${result.seasonalScore.format()}')),
      );
    } else if (result is QueryError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('查询失败：${_queryErrorMessage(name, result)}')),
      );
    }
  }

  String _queryErrorMessage(String name, QueryError error) {
    return switch (error) {
      NameNotFound() => '未找到「$name」的赛季数据',
      TimeoutError() => '查询超时，请稍后重试',
      NetworkError(:final message) => message,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 卡片列表监听 store 的结构变化（新增/删除/排序），自动重建
        Expanded(
          child: ValueListenableBuilder<int>(
            valueListenable: Stores.infoStore.cardIdsNotifier,
            builder: (context, _, _) {
              final cardIds = Stores.infoStore.getCardIds();
              if (cardIds.isEmpty) {
                return const Center(
                  child: Text(
                    '暂无条目，点击右上角 + 添加',
                    style: TextStyle(color: Colors.grey),
                  ),
                );
              }
              return ReorderableListView.builder(
                itemCount: cardIds.length,
                proxyDecorator: (child, index, animation) {
                  return AnimatedBuilder(
                    animation: animation,
                    builder: (context, child) {
                      final double elevation = 4.0 * animation.value;
                      return Material(
                        elevation: elevation,
                        shadowColor: Colors.black26,
                        borderRadius: BorderRadius.circular(8.0),
                        child: IgnorePointer(child: child),
                      );
                    },
                    child: child,
                  );
                },
                onReorderItem: (oldIndex, newIndex) {
                  // 拖拽前先清除焦点，避免 TextField 的 FocusNode
                  // 在 widget 临时脱离树时产生不一致状态导致崩溃
                  FocusManager.instance.primaryFocus?.unfocus();
                  Stores.infoStore.reorderCard(oldIndex, newIndex);
                },
                itemBuilder: (context, index) {
                  return _buildCard(cardIds[index], index);
                },
                buildDefaultDragHandles: false,
                scrollDirection: .vertical,
              );
            },
          ),
        ),
        _buildSummaryBar(),
      ],
    );
  }

  /// 底部总金币汇总条，输入等级时实时更新
  Widget _buildSummaryBar() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.emoji_events, size: 20.0, color: colorScheme.primary),
              const SizedBox(width: 8.0),
              const Text('总波数'),
              const SizedBox(width: 8.0),
              SizedBox(
                height: 20.0,
                width: 20.0,
                child: IconButton(
                  icon: Icon(Icons.edit), 
                  iconSize: 20.0,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  color: Theme.of(context).colorScheme.primary, 
                  tooltip: '修改总波数',
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) {
                        final waveController = TextEditingController();
                        return AlertDialog(
                          title: const Text('设置波数'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextField(
                                controller: waveController,
                                autofocus: true,
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                decoration: const InputDecoration(
                                  labelText: '总波数',
                                  helperText: '0-9',
                                ),
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: const Text('取消'),
                            ),
                            TextButton(
                              onPressed: () {
                                final wave = int.tryParse(waveController.text) ?? 1;
                                Stores.infoStore.setUserWave(wave);
                                Navigator.of(context).pop();
                              },
                              child: const Text('保存'),
                            ),
                          ],
                        );
                      },
                    );
                  }
                ),
              ),
              const SizedBox(width: 4.0),
              SizedBox(
                height: 20.0,
                width: 20.0,
                child: switch (Stores.infoStore.getCurrentUserId()) {
                  0 => const SizedBox.shrink(),
                  _ =>
                IconButton(
                  icon: _querying
                      ? const SizedBox(
                          width: 14.0,
                          height: 14.0,
                          child: CircularProgressIndicator(strokeWidth: 2.0),
                        )
                      : const Icon(Icons.cloud_sync),
                  iconSize: 20.0,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  color: Theme.of(context).colorScheme.primary,
                  tooltip: '联网查询波数',
                  onPressed: _querying ? null : _queryOnline,
                ),}
              ),
              const Spacer(),
              ValueListenableBuilder<int>(
                valueListenable: Stores.infoStore.waveNotifier,
                builder: (context, wave, _) {
                  return Text(
                    wave.format(),
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  );
                },
              ),
            ]
          ),
          Row(
            children: [
              Icon(Icons.eco, size: 20.0, color: colorScheme.primary),
              const SizedBox(width: 8.0),
              const Text('赛季波数'),
              const SizedBox(width: 8.0),
              SizedBox(
                height: 20.0,
                width: 20.0,
                child: IconButton(
                  icon: Icon(Icons.edit), 
                  iconSize: 20.0,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  color: Theme.of(context).colorScheme.primary, 
                  tooltip: '修改赛季波数',
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) {
                        final seasonWaveController = TextEditingController();
                        return AlertDialog(
                          title: const Text('设置赛季波数'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextField(
                                controller: seasonWaveController,
                                autofocus: true,
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                decoration: const InputDecoration(
                                  labelText: '赛季波数',
                                  helperText: '0-9',
                                ),
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: const Text('取消'),
                            ),
                            TextButton(
                              onPressed: () {
                                final seasonWave = int.tryParse(seasonWaveController.text) ?? 0;
                                Stores.infoStore.setCurrentUserSeasonWave(seasonWave);
                                Navigator.of(context).pop();
                              },
                              child: const Text('保存'),
                            ),
                          ],
                        );
                      },
                    );
                  }
                ),
              ),
              const Spacer(),
              // 玩家赛季榜排名（前 300 内才显示）
              if (_playerRank != null) ...[
                PillChip(
                  text: Text(
                    '#$_playerRank',
                    style: const TextStyle(
                      fontSize: 11.0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  icon: Icons.eco,
                ),
                const SizedBox(width: 8.0),
              ],
              ValueListenableBuilder<int>(
                valueListenable: Stores.infoStore.seasonWaveNotifier,
                builder: (context, seasonWave, _) {
                  return Text(
                    seasonWave.format(),
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  );
                },
              ),
            ]
          ),
          Row(
            children: [
              Icon(Icons.monetization_on_outlined,
                  size: 20.0, color: colorScheme.primary),
              const SizedBox(width: 8.0),
              const Text('总金币'),
              const Spacer(),
              ValueListenableBuilder<double>(
                valueListenable: Stores.infoStore.totalGoldNotifier,
                builder: (context, gold, _) {
                  return Text(
                    gold.formatCompact(fractionDigits: 2, english: false),
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  );
                },
              ),
            ],
          ),
          Row(
            children: [
              Icon(Icons.star, size: 20.0, color: colorScheme.primary),
              const SizedBox(width: 8.0),
              const Text('GP'),
              const Spacer(),
              ValueListenableBuilder<double>(
                valueListenable: Stores.infoStore.gpNotifier,
                builder: (context, gp, _) {
                  return Text(
                    gp.format(fractionDigits: 3),
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  );
                },
              ),
            ],
          ),
          Row(
            children: [
              Icon(Icons.local_fire_department, size: 20.0, color: colorScheme.primary),
              const SizedBox(width: 8.0),
              const Text('指数'),
              const Spacer(),
              ValueListenableBuilder<double>(
                valueListenable: Stores.infoStore.gpCNNotifier,
                builder: (context, gpCN, _) {
                  return Text(
                    gpCN.format(fractionDigits: 3),
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  );
                },
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _textFieldForTextInput(int id) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        border: Border(
          left: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2.0
            )
          ),
      ),
      child: TextField(
        // readOnly: switch (id) {
        //   1 || 2 => true,
        //   _ => !Stores.infoStore.getApplyFlag(id),
        // },
        controller: _textControllerFor(id),
        keyboardType: TextInputType.text,
        textInputAction: TextInputAction.done,
        obscureText: false,
        maxLines: 1,
        focusNode: _focusNodeFor(id, _textFocusNodes),
        decoration: InputDecoration(
          border: InputBorder.none,
          labelText: '名称${id == 1 ? ' - 城堡专属' : id == 2 ? ' - 城弓专属' : ''}',
          focusedBorder: InputBorder.none,
          // hintText: '输入数字',
          filled: true,
          // fillColor: Theme.of(context).colorScheme.primaryContainer,
          disabledBorder: InputBorder.none,
          enabled: Stores.infoStore.getApplyFlag(id),
        ),
      ),
    );
  }

  Widget _textFieldForNumberInput(int id) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        border: Border(
          left: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2.0
            )
          ),
      ),
      child: TextField(
        // readOnly: !(_applyFlags[id] ?? true),
        controller: _numberControllerFor(id),
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.done,
        obscureText: false,
        maxLines: 1,
        // maxLength: 10,
        // maxLengthEnforcement: MaxLengthEnforcement.enforced,
        focusNode: _focusNodeFor(id, _numberFocusNodes),
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
        ],
        decoration: InputDecoration(
          border: InputBorder.none,
          labelText: '等级',
          focusedBorder: InputBorder.none,
          // hintText: '输入数字',
          filled: true,
          // fillColor: Theme.of(context).colorScheme.primaryContainer,
          disabledBorder: InputBorder.none,
          enabled: Stores.infoStore.getApplyFlag(id),
        ),
      ),
    );
  }

  Widget _buildCard(int id, int index) {
    return Dismissible( // 左划删除
      key: ValueKey(id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        if (id == 1 || id == 2) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('该条目不可删除，请选择禁用该条目')),
          );
          return false; // 否决滑动，卡片弹回原位
        }
        return true;
      },
      onDismissed: (direction) {
        _removeCard(id);
      },
      child: Listener(
        onPointerDown: (_) {
          // 必须在拖拽代理创建之前清除焦点，否则持有焦点
          // 的 TextField 被移入 Overlay 时会导致崩溃
          FocusManager.instance.primaryFocus?.unfocus();
        },
        child: ListTile(
          // 显式拖拽句柄：避免在 TextField 区域长按触发重排
          leading: ReorderableDragStartListener(
            index: index,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 24),
              child: Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(4.0),
                ),
                child: Text(
                  (index + 1).toString(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16.0,
                  ),
                ),
              ),
            ),
          ),
          // 两个输入框作为主体
          title: Row(
            children: [
              Expanded(flex: 9, child: _textFieldForTextInput(id)),
              const SizedBox(width: 8.0),
              Expanded(flex: 9, child: _textFieldForNumberInput(id)),
            ],
          ),
          // 弹出菜单
          trailing: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 24),
            child: PopupMenuButton(
              padding: EdgeInsets.zero,
              iconSize: 20,
              itemBuilder: (context) => [
                PopupMenuItem(
                  child: Row(
                    children: [
                      Icon(
                        Stores.infoStore.getApplyFlag(id) ? Icons.done : Icons.block,
                        color: Stores.infoStore.getApplyFlag(id) ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 8.0),
                      Text(Stores.infoStore.getApplyFlag(id) ? '已应用' : '未应用'),
                    ],
                  ),
                  onTap: () {
                    setState(() {
                      Stores.infoStore.setApplyFlag(id, !Stores.infoStore.getApplyFlag(id));
                    });
                  },
                ),
                // 清除表单
                PopupMenuItem(
                  child: const Row(
                    children: [
                      Icon(Icons.clear),
                      SizedBox(width: 8.0),
                      Text('清空'),
                    ],
                  ),
                  onTap: () {
                    setState(() {
                      _numberControllerFor(id).clear();
                      // if (id != 1 && id != 2) _textControllerFor(id).clear();
                      _textControllerFor(id).clear();
                    });
                  },
                ),
                PopupMenuItem(
                  enabled: id != 1 && id != 2,
                  child: const Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8.0),
                      Text('删除', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                  onTap: () {
                    _removeCard(id);
                  },
                ),
              ],
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 8.0),
        ),
      ),
    );
  }
}
