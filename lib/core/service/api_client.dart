import 'package:dio/dio.dart';
import 'package:grow_castle_calculator_next/data/store/app_settings.dart';
import 'package:package_info_plus/package_info_plus.dart';

class ApiClient {
  ApiClient._();

  static const Duration timeout = Duration(seconds: 10);

  static final Dio _dio = Dio(
    BaseOptions(
      responseType: ResponseType.plain,
      connectTimeout: timeout,
      receiveTimeout: timeout,
      validateStatus: (_) => true,
    ),
  );

  static Future<Response<String>> get(Uri uri, {Options? options}) =>
      _dio.getUri<String>(uri, options: options);

  static Future<Options?> thirdPartyOptions(
    String baseUrl, {
    required String username,
  }) async {
    if (!_isDefaultApiUrl(baseUrl)) {
      return null;
    }
    return Options(
      headers: {
        'User': _headerSafeName(username),
        'User-Agent': await userAgent(),
      },
    );
  }

  static Future<String> userAgent() async =>
      '$_uaPrefix/${await _appVersion()}';

  static const String _uaPrefix = 'GCCnext';

  static String? _version;

  static Future<String> _appVersion() async {
    final cached = _version;
    if (cached != null) {
      return cached;
    }
    try {
      return _version = (await PackageInfo.fromPlatform()).version;
    } catch (_) {
      return '';
    }
  }

  static bool _isDefaultApiUrl(String baseUrl) =>
      _normalizeUrl(baseUrl) == _normalizeUrl(AppSettingsStore.defaultApiUrl);

  static String _normalizeUrl(String url) =>
      url.trim().replaceAll(RegExp(r'/+$'), '').toLowerCase();

  static String _headerSafeName(String name) =>
      name.codeUnits.any((unit) => unit > 0x7F)
      ? Uri.encodeComponent(name)
      : name;
}
