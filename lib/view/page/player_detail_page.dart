import 'package:flutter/material.dart';
import 'package:grow_castle_calculator_next/core/extension/num.dart';
import 'package:grow_castle_calculator_next/core/service/api.dart';

/// 玩家详情页：调用 [PlayerApiService.query] 获取该玩家的赛季数据并展示。
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

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// 查询该玩家的赛季数据（个人实时数据，不缓存，每次进入重新抓取）
  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await PlayerApiService.query(widget.playerName);

    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result is PlayerQueryResult) {
        _result = result;
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
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
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
