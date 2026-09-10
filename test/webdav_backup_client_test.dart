import 'package:flutter_test/flutter_test.dart';
import 'package:grow_castle_calculator_next/core/service/webdav_backup_client.dart';

/// WebDavBackupClient 的自有纯逻辑测试。
///
/// 协议实现（PUT/GET/PROPFIND、父目录自动 MKCOL、鉴权重试）由
/// webdav_client_plus 承担，故这里只测本层翻译逻辑：状态码到中文文案、
/// 配置 URL 的拆解、以及 HEAD 兜底用的 HTTP 日期解析。
void main() {
  group('messageForStatus:状态码到面向用户的提示', () {
    test('401 提示账号密码', () {
      expect(WebDavBackupClient.messageForStatus(401), contains('账号'));
    });

    test('403 提示访问权限', () {
      expect(WebDavBackupClient.messageForStatus(403), contains('权限'));
    });

    test('404 提示云端尚无备份', () {
      expect(WebDavBackupClient.messageForStatus(404), contains('还没有'));
    });

    test('405 提示服务器不支持', () {
      expect(WebDavBackupClient.messageForStatus(405), contains('不支持'));
    });

    test('其余状态码回显数字', () {
      expect(WebDavBackupClient.messageForStatus(507), contains('507'));
    });
  });

  group('backupPath:目录 path 与文件名拼接', () {
    test('根目录', () {
      expect(
        WebDavBackupClient.backupPath('/', kBackupFileName),
        '/$kBackupFileName',
      );
    });

    test('多段目录', () {
      expect(
        WebDavBackupClient.backupPath('/dav/gcc_backup', kBackupFileName),
        '/dav/gcc_backup/$kBackupFileName',
      );
    });
  });

  group('originOf/dirPathOf:配置 URL 拆成 origin + 目录 path', () {
    test('带路径与结尾斜杠', () {
      const url = 'https://dav.example.com/dav/gcc_backup/';
      expect(WebDavBackupClient.originOf(url), 'https://dav.example.com');
      expect(WebDavBackupClient.dirPathOf(url), '/dav/gcc_backup');
    });

    test('带端口时保留端口', () {
      const url = 'http://192.168.1.5:8080/dav/x';
      expect(WebDavBackupClient.originOf(url), 'http://192.168.1.5:8080');
      expect(WebDavBackupClient.dirPathOf(url), '/dav/x');
    });

    test('无路径视为 WebDAV 根目录', () {
      for (final url in ['https://dav.example.com', 'https://dav.example.com/']) {
        expect(WebDavBackupClient.originOf(url), 'https://dav.example.com');
        expect(WebDavBackupClient.dirPathOf(url), '/');
      }
    });

    test('去掉两端空白', () {
      expect(
        WebDavBackupClient.dirPathOf('  https://dav.example.com/dav/x/  '),
        '/dav/x',
      );
    });
  });

  group('parseLastModified:HEAD 兜底的响应头解析', () {
    test('RFC1123', () {
      expect(
        WebDavBackupClient.parseLastModified('Wed, 09 Sep 2026 04:00:00 GMT'),
        DateTime.utc(2026, 9, 9, 4),
      );
    });

    test('ISO8601 兼容', () {
      expect(
        WebDavBackupClient.parseLastModified('2026-09-09T04:00:00Z'),
        DateTime.utc(2026, 9, 9, 4),
      );
    });

    test('缺失或空返回 null', () {
      expect(WebDavBackupClient.parseLastModified(null), isNull);
      expect(WebDavBackupClient.parseLastModified(''), isNull);
    });

    test('无法解析返回 null', () {
      expect(WebDavBackupClient.parseLastModified('not a date'), isNull);
    });
  });
}
