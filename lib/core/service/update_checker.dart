import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// GitHub 最新发布信息（检查更新用）。
class ReleaseInfo {
  const ReleaseInfo({
    required this.tagName,
    required this.htmlUrl,
    this.name,
    this.body,
  });

  /// 版本标签，如 v1.0.1
  final String tagName;

  /// 发布页地址（浏览器打开）
  final String htmlUrl;

  /// 发布标题
  final String? name;

  /// 发布说明（markdown 文本）
  final String? body;
}

/// 检查更新：查询 GitHub 最新发布，主地址失败时依次尝试镜像。
class UpdateChecker {
  UpdateChecker._();

  static const Duration _timeout = Duration(seconds: 8);

  /// GitHub 仓库（owner/name）：发版检查地址基于它拼装，发版仓库变更时改这里
  static const String repo = 'FnxAg/grow_castle_calculator_next';

  /// 主检查地址：GitHub Releases API 的 latest 端点（不含 prerelease/draft）
  static const String _primaryApiUrl =
      'https://api.github.com/repos/$repo/releases/latest';

  /// 备用镜像（GitHub API 前缀代理）：主地址不可达时依次尝试，
  /// 失效/新增镜像直接增删这里的条目即可
  static const List<String> _apiMirrors = [
    'https://mirror.ghproxy.com/',
    'https://ghfast.top/',
    'https://gh-proxy.com/',
    'https://ghproxy.net/',
  ];

  /// 查询最新发布信息；所有地址都失败时返回 null（由调用方提示网络错误）
  static Future<ReleaseInfo?> fetchLatestRelease() async {
    for (final url in [
      _primaryApiUrl,
      for (final mirror in _apiMirrors) '$mirror$_primaryApiUrl',
    ]) {
      final info = await _tryFetch(url);
      if (info != null) return info;
    }
    return null;
  }

  static Future<ReleaseInfo?> _tryFetch(String url) async {
    try {
      final response = await http.get(
        Uri.parse(url),
        // GitHub API 对无 User-Agent 的请求返回 403
        headers: const {'User-Agent': 'grow_castle_calculator_next'},
      ).timeout(_timeout);
      if (response.statusCode != 200) return null;
      final body = json.decode(utf8.decode(response.bodyBytes));
      if (body is! Map<String, dynamic>) return null;
      final tagName = body['tag_name']?.toString();
      final htmlUrl = body['html_url']?.toString();
      if (tagName == null || htmlUrl == null) return null;
      return ReleaseInfo(
        tagName: tagName,
        htmlUrl: htmlUrl,
        name: body['name']?.toString(),
        body: body['body']?.toString(),
      );
    } on TimeoutException {
      return null;
    } on http.ClientException {
      return null;
    } catch (_) {
      // 解析失败/其他异常：视为该地址不可用，换下一个
      return null;
    }
  }

  /// 比较版本号（兼容 v 前缀与 1.2.3 / 1.2.3+4 形式，忽略构建号）。
  /// 返回 >0 表示 [a] 更新，<0 表示 [a] 更旧，0 表示相同。
  static int compareVersions(String a, String b) {
    final pa = _versionParts(a);
    final pb = _versionParts(b);
    final len = pa.length > pb.length ? pa.length : pb.length;
    for (var i = 0; i < len; i++) {
      final x = i < pa.length ? pa[i] : 0;
      final y = i < pb.length ? pb[i] : 0;
      if (x != y) return x - y;
    }
    return 0;
  }

  static List<int> _versionParts(String version) {
    final core = version.trim().replaceFirst(RegExp(r'^[vV]'), '');
    final withoutBuild = core.split('+').first;
    return [for (final part in withoutBuild.split('.')) int.tryParse(part) ?? 0];
  }
}
