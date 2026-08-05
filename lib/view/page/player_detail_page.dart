import 'package:flutter/material.dart';
import 'package:grow_castle_calculator_next/core/extension/num.dart';
import 'package:grow_castle_calculator_next/core/service/api.dart';
import 'package:grow_castle_calculator_next/data/res/store.dart';

/// 玩家详情页：并行调用官方 API（[PlayerApiService.query]）与第三方 API
/// （每小时波速历史）获取该玩家数据并展示。
/// 与当前用户无关——任意榜单/公会成员中的玩家都可点击进入查看。
class PlayerDetailPage extends StatefulWidget {
  const PlayerDetailPage({super.key, required this.playerName});

  final String playerName;

  @override
  State<PlayerDetailPage> createState() => _PlayerDetailPageState();
}

class _PlayerDetailPageState extends State<PlayerDetailPage> {
  bool _loading = true;
  String? _error;
  PlayerQueryResult? _result;

  /// 第三方 API 的每赛季每小时波速快照（null 表示未加载/失败，区块不展示）
  List<SeasonWphGroup>? _wphHistory;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// 官方 API 与第三方 API 并行查询（均不缓存，每次进入重新抓取）；
  /// 第三方历史失败或为空时静默忽略，不阻塞官方数据展示。
  /// 第三方 API 开关关闭时跳过波速历史查询。
  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final thirdPartyEnabled =
        Stores.appSettingsStore.thirdPartyApiEnabledNotifier.value;
    final (result, history) = thirdPartyEnabled
        ? await (
            PlayerApiService.query(widget.playerName),
            PlayerApiService.queryPlayerWphHistory(
              widget.playerName,
              Stores.appSettingsStore.apiUrlNotifier.value,
            ),
          ).wait
        : (await PlayerApiService.query(widget.playerName), null);

    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result is PlayerQueryResult) {
        _result = result;
        if (history is List<SeasonWphGroup>) {
          _wphHistory = history;
        }
      } else if (result is QueryError) {
        _error = _errorMessage(result);
      }
    });
  }

  String _errorMessage(QueryError error) {
    return switch (error) {
      NameNotFound() => '未找到「${widget.playerName}」的赛季数据',
      TimeoutError() => '查询超时，请稍后重试',
      NetworkError(:final message) => message,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.playerName),
        // backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _buildError();
    }
    final r = _result!;
    // 封禁检测：无波数且无查询日期视为已封禁
    if (r.wave == 0 && r.queryDate.isEmpty) {
      return _buildBanned();
    }
    return _buildResult(r);
  }

  /// 查询失败提示 + 重试
  Widget _buildError() {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 36.0, color: scheme.error),
            const SizedBox(height: 12.0),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16.0),
            FilledButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }

  /// 已封禁提示
  Widget _buildBanned() {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.block, size: 36.0, color: scheme.error),
          const SizedBox(height: 12.0),
          Text(
            '玩家「${widget.playerName}」已被封禁',
            textAlign: TextAlign.center,
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildResult(PlayerQueryResult r) {
    final scheme = Theme.of(context).colorScheme;
    final lastOnline =
        PlayerApiService.formatLastOnline(r.queryDate, DateTime.now());
    return ListView(
      children: [
        _buildRow(Icons.local_fire_department, '总波数', r.wave.format()),
        _buildRow(Icons.eco, '赛季波数', r.seasonalScore.format()),
        _buildRow(Icons.schedule, '上次在线', lastOnline),
        // 第三方 API：赛季标题 + 每小时波速胶囊流（无数据/失败时整个区块不展示）
        if (_wphHistory != null && _wphHistory!.isNotEmpty) ...[
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 4.0),
            child: Text(
              '每小时波速（第三方API）',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
          ),
          for (final group in _wphHistory!) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 0),
              child: Text(
                '赛季 ${group.season}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 4.0),
              // 固定高度、行内拉伸铺满：右侧无空白
              child: _wphGrid(group.wphs),
            ),
          ],
        ],
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            '数据为游戏内最新赛季数据，仅展示不写入本地存档',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.0, color: scheme.onSurfaceVariant),
          ),
        ),
      ],
    );
  }

  /// 波速网格：按可用宽度均分为每行 N 格（格子不小于 48 宽），
  /// 格子 [Expanded] 拉伸铺满整行、右侧无空白；高度固定 28；
  /// 末行格子数量不足时自动补满剩余宽度；缺失值显示「—」
  Widget _wphGrid(List<int?> wphs) {
    final scheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        const minCell = 48.0;
        const spacing = 6.0;
        // 每行格子数：保证格子不小于最小宽度
        final perRow =
            ((constraints.maxWidth + spacing) / (minCell + spacing)).floor();
        final rows = <List<int?>>[];
        for (var i = 0; i < wphs.length; i += perRow) {
          final end = i + perRow < wphs.length ? i + perRow : wphs.length;
          rows.add(wphs.sublist(i, end));
        }
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var r = 0; r < rows.length; r++)
              Padding(
                padding: EdgeInsets.only(
                  bottom: r == rows.length - 1 ? 0 : spacing,
                ),
                child: Row(
                  children: [
                    for (var i = 0; i < rows[r].length; i++) ...[
                      if (i > 0) const SizedBox(width: spacing),
                      Expanded(
                        child: Container(
                          height: 28.0,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: scheme.primaryContainer,
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Text(
                            rows[r][i]?.toString() ?? '—',
                            style: TextStyle(
                              fontSize: 12.0,
                              fontWeight: FontWeight.w600,
                              color: scheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildRow(IconData icon, String label, String value) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(icon, size: 20.0, color: scheme.primary),
      title: Text(label),
      trailing: Text(
        value,
        style: TextStyle(
          fontSize: 16.0,
          fontWeight: FontWeight.bold,
          color: scheme.primary,
        ),
      ),
    );
  }
}
