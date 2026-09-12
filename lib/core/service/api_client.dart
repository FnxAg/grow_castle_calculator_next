import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:grow_castle_calculator_next/data/res/store.dart';
import 'package:grow_castle_calculator_next/data/store/app_settings.dart';

/// 统一的 HTTP 客户端（dio）：集中管理超时、响应解码与出站 header。
///
/// - 响应按 [ResponseType.plain] 取回 UTF-8 文本（等价于原先的
///   `utf8.decode(bodyBytes)`，不依赖响应头里的 charset），JSON 解析由调用方负责；
/// - 状态码不做校验（[BaseOptions.validateStatus] 全放行），404 等由调用方按语义处理；
/// - 除默认第三方 API 外不下发任何自定义 header，UA 沿用平台默认值。
class ApiClient {
  ApiClient._();

  /// 单次请求超时：连接与接收（两次数据到达之间）各自计时；
  /// 调用方另有 `.timeout()` 兜底总时长。
  static const Duration timeout = Duration(seconds: 10);

  static final Dio _dio = Dio(
    BaseOptions(
      responseType: ResponseType.plain,
      connectTimeout: timeout,
      receiveTimeout: timeout,
      // 非 2xx 不抛异常：状态码由调用方判断（404 有「无数据」语义）
      validateStatus: (_) => true,
    ),
  );

  /// 发起 GET 请求；响应体为 UTF-8 文本，非 2xx 不抛异常。
  static Future<Response<String>> get(Uri uri, {Options? options}) =>
      _dio.getUri<String>(uri, options: options);

  /// 默认第三方 API 的请求选项：附带 `User`（当前用户）与 `User-Agent`
  /// （[userAgent]）。
  ///
  /// [baseUrl] 非默认第三方 API 地址（用户自建）时返回 null——
  /// 此时请求不携带这两个 header。
  static Future<Options?> thirdPartyOptions(String baseUrl) async {
    if (!_isDefaultApiUrl(baseUrl)) {
      return null;
    }
    return Options(headers: {
      'User': _headerSafeName(Stores.infoStore.getCurrentUsername()),
      'User-Agent': await userAgent(),
    });
  }

  /// `GCCnext` + 应用版本号（如 `GCCnext1.5.4`）；取不到版本号时退化为 `GCCnext`。
  static Future<String> userAgent() async => '$_uaPrefix ${await _appVersion()}';

  static const String _uaPrefix = 'GCCnext';

  /// 应用版本号（`PackageInfo` 只查一次；失败不缓存，下次调用重试）
  static String? _version;

  static Future<String> _appVersion() async {
    final cached = _version;
    if (cached != null) {
      return cached;
    }
    try {
      return _version = (await PackageInfo.fromPlatform()).version;
    } catch (_) {
      // 版本号拿不到不影响请求：按无版本号处理
      return '';
    }
  }

  /// 是否默认第三方 API 地址（忽略首尾空格、末尾斜杠与大小写）
  static bool _isDefaultApiUrl(String baseUrl) =>
      _normalizeUrl(baseUrl) == _normalizeUrl(AppSettingsStore.defaultApiUrl);

  static String _normalizeUrl(String url) =>
      url.trim().replaceAll(RegExp(r'/+$'), '').toLowerCase();

  /// HTTP header 只允许 ASCII（非 ASCII 会被 dart:io 直接拒绝并导致请求失败），
  /// 用户名含非 ASCII 字符时按 percent-encoding 传输，服务端需按 URL 规则解码。
  static String _headerSafeName(String name) =>
      name.codeUnits.any((unit) => unit > 0x7F) ? Uri.encodeComponent(name) : name;
}
