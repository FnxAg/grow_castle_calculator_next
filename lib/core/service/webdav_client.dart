import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

/// WebDAV 云端备份文件名
const String kBackupFileName = 'gcc_next_backup.json';

/// WebDAV 远程文件元信息
class WebDavFileInfo {
  const WebDavFileInfo({
    required this.exists,
    this.lastModified,
    this.contentLength,
  });

  final bool exists;
  final DateTime? lastModified;
  final int? contentLength;
}

/// WebDAV 异常：message 为面向用户的中文提示
class WebDavException implements Exception {
  WebDavException(this.statusCode, this.message);

  /// HTTP 状态码；-1 表示网络层错误（超时/无法连接）
  final int statusCode;
  final String message;

  @override
  String toString() => message;
}

/// 只覆盖单个固定路径文件的极薄 WebDAV 客户端。
///
/// 需求仅 4 个动词：MKCOL（确保目录存在）/ PUT（上传覆盖）/ GET（下载）/
/// PROPFIND Depth:0（探测存在性与修改时间），因此不引入 dio/webdav_client 等
/// 依赖链，直接用 package:http 手写（与 api.dart / update_checker.dart 一致）。
/// 客户端用 [http.Client] 注入，测试可通过 http/testing.dart 的 MockClient 断言。
///
/// [url] 为备份目录地址（如 https://dav.example.com/dav/gcc_backup），
/// 上传时拼接文件名；结尾可有可无 `/`。
class WebDavClient {
  WebDavClient({
    required String url,
    required String username,
    required String password,
    http.Client? client,
  })  : _baseUrl = url.replaceAll(RegExp(r'/+$'), ''),
        _client = client ?? http.Client() {
    final credentials = base64Encode(utf8.encode('$username:$password'));
    _authHeader = 'Basic $credentials';
  }

  static const Duration _timeout = Duration(seconds: 15);

  final String _baseUrl;
  final http.Client _client;
  late final String _authHeader;

  /// 拼接"目录地址 + 文件名"，忽略目录地址结尾多余的 `/`
  static String joinFileUrl(String dirUrl, String fileName) {
    final base = dirUrl.replaceAll(RegExp(r'/+$'), '');
    return '$base/$fileName';
  }

  /// 上传覆盖云端文件（目录不存在时先逐段 MKCOL 再重试一次）
  Future<void> upload({
    required String fileName,
    required String content,
  }) async {
    final uri = Uri.parse(joinFileUrl(_baseUrl, fileName));
    final body = utf8.encode(content);

    var response = await _send('PUT', uri, body: body);
    if (!isSuccess(response.statusCode) &&
        (response.statusCode == 404 || response.statusCode == 409)) {
      // 目录不存在（404/409）：确保目录后重试一次
      await _ensureCollection(_baseUrl);
      response = await _send('PUT', uri, body: body);
    }
    if (!isSuccess(response.statusCode)) {
      throw WebDavException(
        response.statusCode,
        _messageForStatus(response.statusCode),
      );
    }
  }

  /// 下载云端文件为 UTF-8 文本；文件不存在（404）时抛出对应 WebDavException
  Future<String> download({required String fileName}) async {
    final uri = Uri.parse(joinFileUrl(_baseUrl, fileName));
    final response = await _send('GET', uri);
    if (!isSuccess(response.statusCode)) {
      throw WebDavException(
        response.statusCode,
        _messageForStatus(response.statusCode),
      );
    }
    return utf8.decode(response.bodyBytes);
  }

  /// 探测云端文件：存在性 + 修改时间 + 大小。
  ///
  /// 用 PROPFIND Depth:0 拿 getlastmodified；服务器不支持 PROPFIND 或响应
  /// 缺修改时间时降级为 HEAD 请求的 Last-Modified 头。
  Future<WebDavFileInfo> fetchInfo({required String fileName}) async {
    final uri = Uri.parse(joinFileUrl(_baseUrl, fileName));

    WebDavFileInfo? result;
    try {
      final response = await _send(
        'PROPFIND',
        uri,
        headers: const {'Depth': '0', 'Content-Type': 'application/xml'},
      );
      if (response.statusCode == 404) {
        return const WebDavFileInfo(exists: false);
      }
      if (isSuccess(response.statusCode)) {
        final lastModified = lastModifiedFromPropfind(response.body);
        if (lastModified != null) {
          return WebDavFileInfo(exists: true, lastModified: lastModified);
        }
        result = const WebDavFileInfo(exists: true);
      }
    } on WebDavException catch (e) {
      if (e.statusCode != 404 && e.statusCode != 405) rethrow;
    }

    // PROPFIND 缺失修改时间/不支持（405）：HEAD 兜底
    final head = await _send('HEAD', uri);
    if (head.statusCode == 404) {
      return const WebDavFileInfo(exists: false);
    }
    if (!isSuccess(head.statusCode)) {
      throw WebDavException(
        head.statusCode,
        _messageForStatus(head.statusCode),
      );
    }
    return WebDavFileInfo(
      exists: result?.exists ?? true,
      lastModified: parseLastModified(head.headers['last-modified']),
      contentLength: int.tryParse(head.headers['content-length'] ?? ''),
    );
  }

  /// 从 PROPFIND 的 XML 响应体解析修改时间；无法解析时返回 null。
  /// 各家服务器的 getlastmodified 标签 namespace 前缀不同（无前缀 / d: / lp1:），
  /// 前缀整体可选，用正则匹配。
  static DateTime? lastModifiedFromPropfind(String xmlBody) {
    final match = RegExp(
      r'<([\w-]*:)?getlastmodified\b[^>]*>\s*([^<]+?)\s*</([\w-]*:)?getlastmodified>',
      caseSensitive: false,
    ).firstMatch(xmlBody);
    if (match == null) return null;
    return parseLastModified(match.group(2)!.trim());
  }

  /// 解析 HTTP 日期（RFC1123，如 "Mon, 09 Sep 2026 04:00:00 GMT"）；
  /// 个别服务器返回 ISO8601 一并兼容；解析失败返回 null
  static DateTime? parseLastModified(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      return HttpDate.parse(raw);
    } on HttpException {
      return DateTime.tryParse(raw);
    } on FormatException {
      return DateTime.tryParse(raw);
    }
  }

  static bool isSuccess(int statusCode) => statusCode >= 200 && statusCode < 300;

  static String _messageForStatus(int status) {
    switch (status) {
      case 401:
        return '账号或密码错误（HTTP 401）';
      case 403:
        return '没有访问权限（HTTP 403）';
      case 404:
        return '云端还没有备份文件';
      case 405:
        return '服务器不支持该操作（HTTP 405）';
      default:
        return '服务器返回错误（HTTP $status）';
    }
  }

  Future<http.Response> _send(
    String method,
    Uri uri, {
    Map<String, String>? headers,
    List<int>? body,
  }) async {
    try {
      final request = http.Request(method, uri);
      request.headers['Authorization'] = _authHeader;
      request.headers['Accept'] = 'application/xml, text/xml, */*';
      if (headers != null) {
        request.headers.addAll(headers);
      }
      if (body != null) {
        request.bodyBytes = body;
      }
      final streamed = await _client.send(request).timeout(_timeout);
      return await http.Response.fromStream(streamed).timeout(_timeout);
    } on WebDavException {
      rethrow;
    } catch (e) {
      throw WebDavException(-1, '无法连接服务器，请检查网络与 WebDAV 地址');
    }
  }

  /// 确保目录存在：MKCOL 目录本身，409（父级缺失）时沿路径逐段创建
  Future<void> _ensureCollection(String dirUrl) async {
    final uri = Uri.parse(dirUrl);
    try {
      final response = await _send('MKCOL', uri);
      // 200/201/301/302/405（已存在/不支持重定向）都视为目录可用
      if (isSuccess(response.statusCode) ||
          response.statusCode == 301 ||
          response.statusCode == 302 ||
          response.statusCode == 405) {
        return;
      }
      if (response.statusCode != 409) {
        throw WebDavException(
          response.statusCode,
          _messageForStatus(response.statusCode),
        );
      }
    } on WebDavException catch (e) {
      if (e.statusCode != 409) rethrow;
    }

    // 409：父目录缺失，从根开始逐段 MKCOL
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    for (var i = 1; i <= segments.length; i++) {
      final prefix = uri.replace(path: '/${segments.take(i).join('/')}');
      await _send('MKCOL', prefix);
    }
  }
}
