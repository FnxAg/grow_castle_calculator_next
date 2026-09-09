import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:grow_castle_calculator_next/core/service/webdav_client.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('纯函数', () {
    test('isSuccess:2xx(含 207)为成功,其余失败', () {
      expect(WebDavClient.isSuccess(200), isTrue);
      expect(WebDavClient.isSuccess(201), isTrue);
      expect(WebDavClient.isSuccess(207), isTrue);
      expect(WebDavClient.isSuccess(404), isFalse);
      expect(WebDavClient.isSuccess(401), isFalse);
      expect(WebDavClient.isSuccess(500), isFalse);
    });

    test('joinFileUrl:忽略目录地址结尾多余的 /', () {
      expect(
        WebDavClient.joinFileUrl('https://dav.example.com/dav/dir', 'a.json'),
        'https://dav.example.com/dav/dir/a.json',
      );
      expect(
        WebDavClient.joinFileUrl('https://dav.example.com/dav/dir/', 'a.json'),
        'https://dav.example.com/dav/dir/a.json',
      );
    });

    group('lastModifiedFromPropfind:兼容各家 namespace 前缀', () {
      test('无前缀标签', () {
        final xml = '''
<?xml version="1.0"?>
<D:multistatus xmlns:D="DAV:">
  <D:response>
    <D:href>/dav/dir/a.json</D:href>
    <D:propstat>
      <D:prop>
        <getlastmodified>Mon, 09 Sep 2026 04:00:00 GMT</getlastmodified>
      </D:prop>
      <D:status>HTTP/1.1 200 OK</D:status>
    </D:propstat>
  </D:response>
</D:multistatus>''';
        final time = WebDavClient.lastModifiedFromPropfind(xml);
        expect(time, isNotNull);
        expect(time!.toUtc(), DateTime.utc(2026, 9, 9, 4));
      });

      test('d: 前缀(带 xmlns 属性)', () {
        final xml =
            '<d:multistatus><d:response><d:propstat><d:prop>'
            '<d:getlastmodified xmlns="DAV:">Tue, 08 Sep 2026 04:00:00 GMT'
            '</d:getlastmodified></d:prop></d:propstat></d:response></d:multistatus>';
        final time = WebDavClient.lastModifiedFromPropfind(xml);
        expect(time, DateTime.utc(2026, 9, 8, 4));
      });

      test('自定义前缀 lp1: 与 ISO8601 值', () {
        final xml =
            '<D:multistatus><D:response><D:propstat><D:prop>'
            '<lp1:getlastmodified>2026-09-09T04:00:00Z</lp1:getlastmodified>'
            '</D:prop></D:propstat></D:response></D:multistatus>';
        final time = WebDavClient.lastModifiedFromPropfind(xml);
        expect(time, DateTime.utc(2026, 9, 9, 4));
      });

      test('缺失或无法解析时返回 null', () {
        expect(WebDavClient.lastModifiedFromPropfind('<d:multistatus/>'), isNull);
        expect(
          WebDavClient.lastModifiedFromPropfind(
            '<d:prop><d:getcontentlength>5</d:getcontentlength></d:prop>',
          ),
          isNull,
        );
      });
    });
  });

  group('MockClient 集成', () {
    const dirUrl = 'https://dav.example.com/dav/gcc_backup';
    const fileUrl = '$dirUrl/gcc_next_backup.json';

    WebDavClient buildClient(
      MockClientHandler handler,
      List<http.Request> log,
    ) {
      return WebDavClient(
        url: dirUrl,
        username: 'user',
        password: 'pass',
        client: MockClient((request) {
          log.add(request);
          return handler(request);
        }),
      );
    }

    test('upload:PUT 成功并携带 Basic 认证头与内容', () async {
      final log = <http.Request>[];
      final client = buildClient(
        (request) async => http.Response('', 201, request: request),
        log,
      );
      await client.upload(fileName: kBackupFileName, content: '{"a":1}');

      expect(log, hasLength(1));
      expect(log.first.method, 'PUT');
      expect(log.first.url.toString(), fileUrl);
      expect(log.first.headers['Authorization'], 'Basic dXNlcjpwYXNz');
      expect(log.first.body, '{"a":1}');
    });

    test('upload:目录不存在(404)时先 MKCOL 目录再重试 PUT', () async {
      final log = <http.Request>[];
      var putCount = 0;
      final client = buildClient((request) async {
        if (request.method == 'PUT') {
          putCount++;
          return http.Response('', putCount == 1 ? 404 : 201,
              request: request);
        }
        if (request.method == 'MKCOL') {
          return http.Response('', 201, request: request);
        }
        return http.Response('', 405, request: request);
      }, log);
      await client.upload(fileName: kBackupFileName, content: 'x');

      expect(log.map((r) => r.method), ['PUT', 'MKCOL', 'PUT']);
      expect(log[1].url.toString(), dirUrl);
      expect(putCount, 2);
    });

    test('upload:401 抛出中文提示且带状态码', () async {
      final log = <http.Request>[];
      final client = buildClient(
        (request) async => http.Response('', 401, request: request),
        log,
      );
      expect(
        () => client.upload(fileName: kBackupFileName, content: 'x'),
        throwsA(isA<WebDavException>()
            .having((e) => e.statusCode, 'statusCode', 401)
            .having((e) => e.message, 'message', contains('账号'))),
      );
    });

    test('upload:网络异常映射为 statusCode -1', () async {
      final client = buildClient(
        (request) async => throw http.ClientException('connection refused'),
        [],
      );
      expect(
        () => client.upload(fileName: kBackupFileName, content: 'x'),
        throwsA(isA<WebDavException>()
            .having((e) => e.statusCode, 'statusCode', -1)
            .having((e) => e.message, 'message', contains('无法连接'))),
      );
    });

    test('download:返回 UTF-8 文本(不受 latin1 默认解码影响)', () async {
      final client = buildClient(
        (request) async => http.Response.bytes(
          utf8.encode('中文数据'),
          200,
          request: request,
        ),
        [],
      );
      expect(await client.download(fileName: kBackupFileName), '中文数据');
    });

    test('download:404 提示云端还没有备份文件', () async {
      final client = buildClient(
        (request) async => http.Response('', 404, request: request),
        [],
      );
      expect(
        () => client.download(fileName: kBackupFileName),
        throwsA(isA<WebDavException>()
            .having((e) => e.statusCode, 'statusCode', 404)
            .having((e) => e.message, 'message', contains('还没有'))),
      );
    });

    test('fetchInfo:PROPFIND 207 解析 getlastmodified', () async {
      final xml = '<d:multistatus><d:propstat><d:prop>'
          '<d:getlastmodified>Mon, 09 Sep 2026 04:00:00 GMT</d:getlastmodified>'
          '</d:prop></d:propstat></d:multistatus>';
      final client = buildClient(
        (request) async => http.Response(xml, 207, request: request),
        [],
      );
      final info = await client.fetchInfo(fileName: kBackupFileName);
      expect(info.exists, isTrue);
      expect(info.lastModified, DateTime.utc(2026, 9, 9, 4));
    });

    test('fetchInfo:404 → exists=false', () async {
      final client = buildClient(
        (request) async => http.Response('', 404, request: request),
        [],
      );
      final info = await client.fetchInfo(fileName: kBackupFileName);
      expect(info.exists, isFalse);
      expect(info.lastModified, isNull);
    });

    test('fetchInfo:PROPFIND 405 时降级 HEAD 拿 Last-Modified', () async {
      final log = <http.Request>[];
      final client = buildClient((request) async {
        if (request.method == 'PROPFIND') {
          return http.Response('', 405, request: request);
        }
        return http.Response('', 200, headers: {
          'last-modified': 'Wed, 09 Sep 2026 04:00:00 GMT',
          'content-length': '42',
        }, request: request);
      }, log);
      final info = await client.fetchInfo(fileName: kBackupFileName);
      expect(info.exists, isTrue);
      expect(info.lastModified, DateTime.utc(2026, 9, 9, 4));
      expect(info.contentLength, 42);
      expect(log.last.method, 'HEAD');
    });

    test('fetchInfo:PROPFIND 成功但缺时间 → HEAD 兜底补全', () async {
      final log = <http.Request>[];
      final client = buildClient((request) async {
        if (request.method == 'PROPFIND') {
          return http.Response('<d:multistatus/>', 207, request: request);
        }
        return http.Response('', 200, headers: {
          'last-modified': 'Thu, 10 Sep 2026 04:00:00 GMT',
        }, request: request);
      }, log);
      final info = await client.fetchInfo(fileName: kBackupFileName);
      expect(info.exists, isTrue);
      expect(info.lastModified, DateTime.utc(2026, 9, 10, 4));
      expect(log.last.method, 'HEAD');
    });
  });
}
