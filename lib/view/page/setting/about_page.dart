import 'package:flutter/gestures.dart';
import 'package:grow_castle_calculator_next/l10n/app_localizations.dart';
import 'package:grow_castle_calculator_next/utils/platform_utils.dart';
import 'package:material_ui/material_ui.dart';
import 'package:grow_castle_calculator_next/view/widget/section_header.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

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
  List<_AboutEntry> get _infoEntries {
    final l10n = AppLocalizations.of(context);
    return [
      _AboutEntry(
        icon: Icons.info_outline,
        title: l10n.aboutAdaptedVersion,
        subtitle: 'v1.51.5',
        tappable: false,
      ),
      _linkEntry(
        Icons.menu_book_outlined,
        l10n.aboutGuide,
        'https://ariyara.cc/posts/gcc-next-guide/',
      ),
      _AboutEntry(
        icon: Icons.api,
        title: l10n.aboutThirdPartyApiInfo,
        subtitle: l10n.aboutThirdPartyApiInfoSubtitle,
        onTap: () => showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l10n.settingsThirdPartyApi),
            content: Text(l10n.dialogThirdPartyApiBody),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.actionGotIt),
              ),
            ],
          ),
        ),
      ),
      // _AboutEntry(
      //   icon: Icons.api,
      //   title: '第三方API',
      //   subtitle: '查看当前第三方 API 状态与地址',
      //   onTap: _showThirdPartyApiDialog,
      // ),
    ];
  }

  List<_AboutEntry> get _linkEntries {
    final l10n = AppLocalizations.of(context);
    return [
      _linkEntry(
        Icons.code,
        l10n.aboutGithubRepo,
        'https://github.com/FnxAg/grow_castle_calculator_next',
        display: 'FnxAg/grow_castle_calculator_next',
      ),
      _linkEntry(
        Icons.code,
        l10n.aboutOriginalGithubRepo,
        'https://github.com/FnxAg/GrowCastleCalculator',
        display: 'FnxAg/GrowCastleCalculator',
      ),
      _linkEntry(
        Icons.link,
        l10n.aboutQqGroup,
        'https://qm.qq.com/q/FMLqiMRbai',
        display: '913331981',
      ),
      _AboutEntry(
        icon: Icons.email,
        title: l10n.aboutDeveloperEmail,
        subtitle: 'fnxag@qq.com',
        tappable: false,
      ),
    ];
  }

  /// 授权区条目
  List<_AboutEntry> get _legalEntries {
    final l10n = AppLocalizations.of(context);
    return [
      _AboutEntry(
        icon: Icons.description_outlined,
        title: l10n.aboutOpenSourceLicenses,
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
        subtitle: l10n.aboutLicenseNotice,
        tappable: false,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsAbout)),
      body: ListView(
        children: [
          _buildHeader(context),
          SectionHeader(l10n.sectionInfo),
          for (final entry in _infoEntries) entry,
          SectionHeader(l10n.sectionLinks),
          for (final entry in _linkEntries) entry,
          SectionHeader(l10n.sectionLicenses),
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
          Text(
            info?.appName ?? 'GCC Next',
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          if (info != null) ...[
            const SizedBox(height: 4),
            Text(
              'v${info.version}${isMobile ? ' (${info.buildNumber})' : ''}',
              style: textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            AppLocalizations.of(context).aboutTagline,
            style: textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
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
          Text.rich(
            TextSpan(
              children: [
                const TextSpan(text: 'GCC Next · by '),
                TextSpan(
                  text: 'FnxAg',
                  style: const TextStyle(color: Colors.blueAccent),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      _launchUrl('https://github.com/FnxAg');
                    },
                ),
              ],
            ),
            style: textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
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

  _AboutEntry _linkEntry(
    IconData icon,
    String title,
    String url, {
    String? display,
  }) => _AboutEntry(
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
        SnackBar(
          content: Text(AppLocalizations.of(context).snackCannotOpenLink(url)),
        ),
      );
    }
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
