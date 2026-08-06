import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// 「关于」页：应用信息头部 + 说明 / 链接 / 法律与授权分组条目。
///
/// 条目由 [_AboutEntry] 数据驱动：后续新增链接/说明只需在
/// [_infoEntries] / [_linkEntries] / [_legalEntries] 里追加一条记录。
class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  PackageInfo? _packageInfo;

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _packageInfo = info);
    });
  }

  /// 说明区条目
  List<_AboutEntry> get _infoEntries => [
        const _AboutEntry(
          icon: Icons.info_outline,
          title: '适配版本',
          subtitle: 'v1.50.14',
          tappable: false,
        ),
        _linkEntry(
          Icons.menu_book_outlined,
          '使用说明',
          'https://blog.fnxag.eu.org/posts/gcc-next-guide/',
        ),
        // _AboutEntry(
        //   icon: Icons.api,
        //   title: '第三方API',
        //   subtitle: '查看当前第三方 API 状态与地址',
        //   onTap: _showThirdPartyApiDialog,
        // ),
      ];

  /// 链接区条目：新增链接只需追加一行 [_linkEntry]
  List<_AboutEntry> get _linkEntries => [
        _linkEntry(
          Icons.code,
          'GitHub 仓库',
          'https://github.com/FnxAg/grow_castle_calculator_next',
          display: 'FnxAg/grow_castle_calculator_next',
        ),
        _linkEntry(
          Icons.code,
          '原项目 GitHub 仓库',
          'https://github.com/FnxAg/GrowCastleCalculator',
          display: 'FnxAg/GrowCastleCalculator',
        ),
        _linkEntry(
          Icons.link,
          'QQ 群',
          'https://qm.qq.com/q/FMLqiMRbai',
          display: '913331981',
        )
      ];

  /// 法律与授权区条目
  List<_AboutEntry> get _legalEntries => [
        _AboutEntry(
          icon: Icons.description_outlined,
          title: '开源许可',
          onTap: () => showLicensePage(
            context: context,
            applicationName: _packageInfo?.appName ?? 'GCC Next',
            applicationIcon: Image.asset(
              'assets/images/app_icon.png',
              width: 72,
              height: 72,
              fit: BoxFit.cover,
            ),
          ),
        ),
        _AboutEntry(
          icon: Icons.verified_outlined,
          title: 'LICENSE',
          subtitle: '本应用遵循 GPL v3.0 开源协议',
          tappable: false,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('关于')),
      body: ListView(
        children: [
          _buildHeader(context),
          const _SectionHeader('说明'),
          for (final entry in _infoEntries) entry,
          const _SectionHeader('链接'),
          for (final entry in _linkEntries) entry,
          const _SectionHeader('授权'),
          for (final entry in _legalEntries) entry,
          _buildFooter(context),
        ],
      ),
    );
  }

  /// 头部：应用图标 + 名称 + 版本号 + 标语
  Widget _buildHeader(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final info = _packageInfo;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Image.asset(
              'assets/images/app_icon.png',
              width: 88,
              height: 88,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            info?.appName ?? 'GCC Next',
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          if (info != null) ...[
            const SizedBox(height: 4),
            Text(
              'v${info.version} (${info.buildNumber})',
              style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            'Grow Castle 辅助工具',
            style: textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  /// 底部：作者署名与提示
  Widget _buildFooter(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
      child: Column(
        children: [
          Text(
            'GCC Next · by FnxAg',
            style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
          // const SizedBox(height: 4),
          // Text(
          //   '数据仅供参考，请以游戏内实际为准',
          //   style: textTheme.bodySmall?.copyWith(color: scheme.outline),
          // ),
        ],
      ),
    );
  }

  // /// 第三方 API 状态弹窗
  // void _showThirdPartyApiDialog() {
  //   // 先释放焦点，与项目其他弹窗入口保持一致
  //   FocusManager.instance.primaryFocus?.unfocus();
  //   final store = Stores.appSettingsStore;
  //   showDialog<void>(
  //     context: context,
  //     builder: (context) => AlertDialog(
  //       title: const Text('第三方API'),
  //       content: ValueListenableBuilder<bool>(
  //         valueListenable: store.thirdPartyApiEnabledNotifier,
  //         builder: (context, enabled, _) => Text(
  //           enabled
  //               ? '已启用：\n${store.apiUrlNotifier.value}'
  //               : '当前未启用。\n可在「设置」页开启并配置 API 地址。',
  //         ),
  //       ),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Navigator.of(context).pop(),
  //           child: const Text('知道了'),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  /// 链接条目构造：点击用系统浏览器打开 [url]；[display] 可覆盖副标题展示文本
  _AboutEntry _linkEntry(IconData icon, String title, String url,
          {String? display}) =>
      _AboutEntry(
        icon: icon,
        title: title,
        subtitle: display ?? url,
        onTap: () => _launchUrl(url),
      );

  /// 用系统浏览器打开外部链接；失败时 SnackBar 提示
  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('无法打开链接：$url')),
      );
    }
  }
}

/// 分组标题
class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: scheme.primary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

/// 关于页条目行。
///
/// [tappable] 为 true（默认）时沿用「onTap 为 null → 置灰占位」的语义，
/// 接入动作后自动恢复可点；[tappable] 为 false 时条目保持正常配色、
/// 仅不可点击（无动作、无箭头），用于「仅展示」的条目（如版本号）。
class _AboutEntry extends StatelessWidget {
  const _AboutEntry({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.tappable = true,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool tappable;

  @override
  Widget build(BuildContext context) {
    final clickable = tappable && onTap != null;
    return ListTile(
      enabled: clickable || !tappable,
      leading: Icon(icon),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: clickable ? const Icon(Icons.chevron_right) : null,
      onTap: clickable ? onTap : null,
    );
  }
}
