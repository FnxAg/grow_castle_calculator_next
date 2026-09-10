import 'dart:convert';
import 'dart:io';

import 'package:webdav_client_plus/webdav_client_plus.dart' as dav;

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

/// 备份文件的 WebDAV 客户端：webdav_client_plus 之上的薄适配层。
///
/// 协议实现（PUT/GET/PROPFIND、鉴权重试、缺失父目录的逐段 MKCOL、HTTP 日期
/// 解析）全部交给包，本层只负责三件事：
/// 1. 把配置的目录 URL 拆成 origin + 目录 path（路径由我们自己算，包按
///    SabreDAV 语义把绝对 path 解析回 origin，父目录也据此自动创建）；
/// 2. 把包的查询结果翻译成 [WebDavFileInfo]；
/// 3. 把异常翻译成面向用户的 [WebDavException]（中文提示 + 状态码）。
///
/// [url] 为备份目录地址（如 https://dav.example.com/dav/gcc_backup），
/// 结尾可有可无 `/`。
class WebDavBackupClient {
  WebDavBackupClient({
    required String url,
    required String username,
    required String password,
  })  : _dirPath = dirPathOf(url),
        _client = dav.WebdavClient.basicAuth(
          url: originOf(url),
          user: username,
          pwd: password,
        ) {
    _client.setHeaders({'accept-charset': 'utf-8'});
    _client.setConnectTimeout(_timeoutMs);
    _client.setSendTimeout(_timeoutMs);
    _client.setReceiveTimeout(_timeoutMs);
  }

  /// 单次请求超时（毫秒）；包内的设置方法接收毫秒 int
  static const int _timeoutMs = 15000;

  final String _dirPath;
  final dav.WebdavClient _client;

  /// 拼接"目录 path + 文件名"，忽略目录结尾多余的 `/`
  static String backupPath(String dirPath, String fileName) =>
      dirPath == '/' ? '/$fileName' : '$dirPath/$fileName';

  /// 从配置 URL 提取 origin（scheme://host:port）；路径/凭据一律丢弃
  static String originOf(String url) {
    final uri = Uri.parse(url.trim());
    return Uri(
      scheme: uri.scheme,
      host: uri.host,
      port: uri.hasPort ? uri.port : null,
    ).toString();
  }

  /// 从配置 URL 提取目录 path；URL 无路径时视为 WebDAV 根目录
  static String dirPathOf(String url) {
    final path = Uri.parse(url.trim()).path.replaceAll(RegExp(r'/+$'), '');
    return path.isEmpty ? '/' : path;
  }

  /// 上传覆盖云端文件；父目录不存在时由包在 PUT 前自动逐段 MKCOL
  Future<void> upload({
    required String fileName,
    required String content,
  }) async {
    try {
      await _client.write(backupPath(_dirPath, fileName), utf8.encode(content));
    } catch (error) {
      throw _translate(error);
    }
  }

  /// 下载云端文件为 UTF-8 文本；文件不存在（404）时抛对应 WebDavException
  Future<String> download({required String fileName}) async {
    try {
      final bytes = await _client.read(backupPath(_dirPath, fileName));
      return utf8.decode(bytes);
    } catch (error) {
      throw _translate(error);
    }
  }

  /// 探测云端文件：存在性 + 修改时间 + 大小。
  ///
  /// 用 readProps（PROPFIND Depth:0）拿 getlastmodified/getcontentlength；
  /// 服务器不支持 PROPFIND（405）或响应无可解析条目时降级为 HEAD 响应头。
  Future<WebDavFileInfo> fetchInfo({required String fileName}) async {
    final path = backupPath(_dirPath, fileName);
    try {
      final file = await _client.readProps(path);
      if (file != null) {
        return WebDavFileInfo(
          exists: true,
          lastModified: file.modified,
          contentLength: file.size,
        );
      }
    } catch (error) {
      if (error is dav.WebdavException) {
        if (error.statusCode == 404) {
          return const WebDavFileInfo(exists: false);
        }
        // 405：服务器不支持 PROPFIND，落到 HEAD 兜底；其余错误直接上报
        if (error.statusCode != 405) throw _translate(error);
      } else {
        throw _translate(error);
      }
    }
    return _fetchInfoByHead(path);
  }

  /// HEAD 兜底：部分服务器不支持 PROPFIND，用响应头拿修改时间与大小
  Future<WebDavFileInfo> _fetchInfoByHead(String path) async {
    try {
      final response = await _client.head(path);
      final status = response.statusCode ?? -1;
      if (status == 404) return const WebDavFileInfo(exists: false);
      if (status < 200 || status >= 300) {
        throw WebDavException(status, messageForStatus(status));
      }
      return WebDavFileInfo(
        exists: true,
        lastModified: parseLastModified(response.headers.value('last-modified')),
        contentLength: int.tryParse(
          response.headers.value('content-length') ?? '',
        ),
      );
    } catch (error) {
      throw _translate(error);
    }
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

  /// 状态码 → 面向用户的中文提示
  static String messageForStatus(int status) {
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

  /// 把包/传输层抛出的异常翻译为 [WebDavException]（幂等：已是本类型则原样返回）
  static WebDavException _translate(Object error) {
    if (error is WebDavException) return error;
    if (error is dav.WebdavException) {
      final status = error.statusCode ?? -1;
      return WebDavException(status, messageForStatus(status));
    }
    // 非协议错误（超时/无法连接/DNS/TLS）由 dio 抛出，统一归为网络层失败
    return WebDavException(-1, '无法连接服务器，请检查网络与 WebDAV 地址');
  }
}
