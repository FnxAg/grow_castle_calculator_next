import 'package:flutter_test/flutter_test.dart';
import 'package:grow_castle_calculator_next/core/service/backup_service.dart';

void main() {
  group('shouldCatchUp:启动/回前台超过间隔补传判定', () {
    final now = DateTime.utc(2026, 9, 9, 12);

    test('从未成功过 → 需要补传', () {
      expect(BackupService.shouldCatchUp(null, now, 24), isTrue);
    });

    test('距上次成功未超过间隔 → 不补传', () {
      final last = now.subtract(const Duration(hours: 23, minutes: 59));
      expect(
        BackupService.shouldCatchUp(
          last.millisecondsSinceEpoch,
          now,
          24,
        ),
        isFalse,
      );
    });

    test('距上次成功正好等于间隔 → 补传', () {
      final last = now.subtract(const Duration(hours: 24));
      expect(
        BackupService.shouldCatchUp(
          last.millisecondsSinceEpoch,
          now,
          24,
        ),
        isTrue,
      );
    });

    test('已超过间隔 → 补传', () {
      final last = now.subtract(const Duration(hours: 25));
      expect(
        BackupService.shouldCatchUp(
          last.millisecondsSinceEpoch,
          now,
          24,
        ),
        isTrue,
      );
    });

    test('自定义间隔（1 小时）', () {
      final last = now.subtract(const Duration(minutes: 90));
      expect(
        BackupService.shouldCatchUp(last.millisecondsSinceEpoch, now, 1),
        isTrue,
      );
      final recent = now.subtract(const Duration(minutes: 30));
      expect(
        BackupService.shouldCatchUp(recent.millisecondsSinceEpoch, now, 1),
        isFalse,
      );
    });
  });
}
