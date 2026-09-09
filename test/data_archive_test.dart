import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:grow_castle_calculator_next/core/service/data_archive.dart';

/// 构造一份接近真实结构的 box 快照（形状仿 UserData.toMap / GameTrackRecord.toMap）
Map<String, dynamic> _sampleUser(int id) => {
      'username': 'user$id',
      'version': 1,
      'guild': '公会$id',
      'info': {
        'cardIds': [1, 2],
        // 嵌套 int-key map：模拟 JSON 字符串化后由 UserData.fromMap 兜底解析的路径
        'applyFlags': {1: true, 2: false},
        'textValues': {101: '文本'},
        'numberValues': {},
      },
      'data': {
        'unitGold': {7: 1234.5},
        'totalGold': 999.0,
        'wave': 88,
        'seasonWave': 0,
        'gp': 1.5,
        'gpCN': 0.0,
        'infiniteColony': 0,
        'gameSpeed': 1,
        'chronoClass': 0,
        'horn': false,
        'goldenHorn': true,
        'devilHornSkip': 1,
        'isGoldAutoBattle': true,
        'gabTime': 2.0,
        'gabBonus': 3.0,
        'tabTime': 0.0,
        'icCooldown': 0,
        'icGold': 0,
        'equipWheel': false,
        'equipWhip': false,
        'seasonColony': false,
        'goldenTree': false,
      },
      'setting': {'onlineQuery': false},
    };

void main() {
  final fixedNow = DateTime.utc(2026, 9, 9, 4, 5, 6);

  Map<Object?, dynamic> sampleBoxes() => {
        'user_data': {
          0: _sampleUser(0),
          1: _sampleUser(1),
        },
        'user_meta': {'currentUserId': 0, 'nextUserId': 2},
        'app_meta': {
          'themeMode': 'light',
          'apiUrl': 'https://example.com/gcapi',
          'webdavUrl': 'https://dav.example.com/dir',
          'webdavPassword': 'secret',
          'item_comparer': '{"baseAttack":"1000"}',
        },
        'item_rules': {'rules': '[{"id":"r1","hint":"红白加强"}]'},
        'game_track': {
          'user_0': [
            {
              'id': 't1',
              'recordedAt': '2026-09-09T03:00:00.000Z',
              'wave': 10,
              'totalGold': 100.0,
              'gp': 1.0,
              'gpCN': 0.0,
              'units': [
                {'name': '小红帽', 'level': 100, 'enabled': true},
              ],
            },
          ],
          'user_1': [
            {'id': 't2', 'recordedAt': '2026-09-09T03:01:00.000Z', 'wave': 20},
          ],
        },
      };

  Map<String, dynamic> encodeSample({DateTime? now, String? appVersion}) {
    final boxes = sampleBoxes();
    return DataArchive.encode(
      userDataBox: boxes['user_data']! as Map<Object?, dynamic>,
      userMetaBox: boxes['user_meta']! as Map<Object?, dynamic>,
      appMetaBox: boxes['app_meta']! as Map<Object?, dynamic>,
      itemRulesBox: boxes['item_rules']! as Map<Object?, dynamic>,
      gameTrackBox: boxes['game_track']! as Map<Object?, dynamic>,
      now: now,
      appVersion: appVersion,
    );
  }

  group('encode', () {
    test('结构完整:含版本/时间戳与五节数据', () {
      final archive = encodeSample(now: fixedNow, appVersion: '1.5.4');
      expect(archive['formatVersion'], DataArchive.formatVersion);
      expect(archive['exportedAt'], fixedNow.toIso8601String());
      expect(archive['appVersion'], '1.5.4');

      final data = archive['data'] as Map<String, dynamic>;
      expect(data.keys, containsAll(['userData', 'userMeta', 'appMeta', 'itemRules', 'gameTrack']));
    });

    test('user_data 的 int key 显式字符串化', () {
      final archive = encodeSample(now: fixedNow);
      final userData = (archive['data'] as Map<String, dynamic>)['userData']
          as Map<String, dynamic>;
      expect(userData.keys, containsAll(['0', '1']));
      // 非 int key / 非 Map 值被跳过
      final data = (archive['data'] as Map<String, dynamic>)['userData'];
      (data as Map<String, dynamic>)['garbage'] = 'x';
      final dropped = DataArchive.encode(
        userDataBox: {0: _sampleUser(0), 'garbage': 'x'},
        userMetaBox: const {},
        appMetaBox: const {},
        itemRulesBox: const {},
        gameTrackBox: const {},
        now: fixedNow,
      );
      final droppedUser = (dropped['data'] as Map<String, dynamic>)['userData']
          as Map<String, dynamic>;
      expect(droppedUser.keys, ['0']);
    });

    test('app_meta 剔除 webdav* 键(凭据不进备份文件)', () {
      final archive = encodeSample(now: fixedNow);
      final appMeta = (archive['data'] as Map<String, dynamic>)['appMeta']
          as Map<String, dynamic>;
      expect(appMeta['themeMode'], 'light');
      expect(appMeta['item_comparer'], isNotNull);
      expect(appMeta.keys.where((k) => k.startsWith('webdav')), isEmpty);
    });

    test('整档可 jsonEncode 且嵌套 int-key map 正常字符串化', () {
      final archive = encodeSample(now: fixedNow);
      final text = jsonEncode(archive);
      final root = jsonDecode(text) as Map<String, dynamic>;
      expect(root['formatVersion'], DataArchive.formatVersion);
    });
  });

  group('decode', () {
    test('encode → decode 往返:顶层 key 还原、内容原样', () {
      final text = jsonEncode(encodeSample(now: fixedNow, appVersion: '1.5.4'));
      final contents = DataArchive.decode(text);

      expect(contents.formatVersion, DataArchive.formatVersion);
      expect(contents.exportedAt, fixedNow);
      expect(contents.appVersion, '1.5.4');
      expect(contents.userCount, 2);

      final user0 = contents.userData![0] as Map<String, dynamic>;
      expect(user0['username'], 'user0');
      expect(
        ((user0['data'] as Map<String, dynamic>)['unitGold']
            as Map<String, dynamic>)['7'],
        1234.5,
      );

      expect(contents.userMeta!['nextUserId'], 2);
      expect(contents.appMeta!['webdavUrl'], isNull);
      expect(contents.appMeta!['themeMode'], 'light');
      expect(
        (contents.gameTrack!['user_0'] as List).length,
        1,
      );
      expect(contents.trackRecordCount, 2);
    });

    test('user_meta.nextUserId 防御 clamp:不得小于现有最大用户 key + 1', () {
      final boxes = sampleBoxes();
      (boxes['user_meta']! as Map<String, dynamic>)['nextUserId'] = 1;
      final text = jsonEncode(DataArchive.encode(
        userDataBox: boxes['user_data']! as Map<Object?, dynamic>,
        userMetaBox: boxes['user_meta']! as Map<Object?, dynamic>,
        appMetaBox: const {},
        itemRulesBox: const {},
        gameTrackBox: const {},
        now: fixedNow,
      ));
      final contents = DataArchive.decode(text);
      // 最大用户 key 为 1 → nextUserId 至少为 2
      expect(contents.userMeta!['nextUserId'], 2);
    });

    test('userMeta 缺失时不抛异常且返回 null(恢复保留本地)', () {
      final text = jsonEncode({
        'formatVersion': 1,
        'exportedAt': '2026-09-09T00:00:00.000Z',
        'data': {
          'userData': {
            // 仅字符串 key(手工构造,绕过 encode 的字符串化)
            '0': {'username': 'u', 'version': 1},
          },
        },
      });
      final contents = DataArchive.decode(text);
      expect(contents.userMeta, isNull);
      expect(contents.appMeta, isNull);
      expect(contents.itemRules, isNull);
      expect(contents.gameTrack, isNull);
      expect(contents.userCount, 1);
      expect(contents.trackRecordCount, 0);
    });

    test('格式版本过新:抛"请先升级"提示', () {
      final text = jsonEncode({'formatVersion': 99, 'data': {}});
      expect(
        () => DataArchive.decode(text),
        throwsA(isA<DataArchiveException>().having(
          (e) => e.message,
          'message',
          contains('升级'),
        )),
      );
    });

    test('损坏输入:抛 DataArchiveException 而非崩溃', () {
      for (final bad in ['', '{not json', '[]', '42', '{"data": {}}']) {
        expect(
          () => DataArchive.decode(bad),
          throwsA(isA<DataArchiveException>()),
          reason: '输入: $bad',
        );
      }
    });

    test('user_data 中 key 无法解析为 int / 值非 Map:跳过', () {
      final text = jsonEncode({
        'formatVersion': 1,
        'data': {
          'userData': {
            '0': {'username': 'u', 'version': 1},
            'abc': {'username': 'bad', 'version': 1},
            '2': 'not-a-map',
          },
        },
      });
      final contents = DataArchive.decode(text);
      expect(contents.userCount, 1);
      expect(contents.userData!.containsKey(0), isTrue);
    });
  });
}
