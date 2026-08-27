import 'package:hive_flutter/hive_flutter.dart';

class GameTrackUnit {
  const GameTrackUnit({required this.name, required this.level});

  final String name;
  final int level;

  factory GameTrackUnit.fromMap(Map<dynamic, dynamic> map) {
    return GameTrackUnit(
      name: map['name']?.toString() ?? '',
      level: _asInt(map['level']),
    );
  }

  Map<String, dynamic> toMap() => {'name': name, 'level': level};
}

class GameTrackRecord {
  const GameTrackRecord({
    required this.id,
    required this.recordedAt,
    required this.wave,
    required this.totalGold,
    required this.gp,
    required this.gpCN,
    required this.units,
  });

  final String id;
  final DateTime recordedAt;
  final int wave;
  final double totalGold;
  final double gp;
  final double gpCN;
  final List<GameTrackUnit> units;

  factory GameTrackRecord.fromMap(Map<dynamic, dynamic> map) {
    final rawUnits = map['units'];
    return GameTrackRecord(
      id: map['id']?.toString() ?? '',
      recordedAt: DateTime.tryParse(map['recordedAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      wave: _asInt(map['wave']),
      totalGold: _asDouble(map['totalGold']),
      gp: _asDouble(map['gp']),
      gpCN: _asDouble(map['gpCN']),
      units: rawUnits is List
          ? rawUnits
              .whereType<Map>()
              .map(GameTrackUnit.fromMap)
              .toList(growable: false)
          : const [],
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'recordedAt': recordedAt.toIso8601String(),
        'wave': wave,
        'totalGold': totalGold,
        'gp': gp,
        'gpCN': gpCN,
        'units': units.map((unit) => unit.toMap()).toList(),
      };
}

class GameTrackStore {
  static const String boxName = 'game_track';
  static const String _recordsPrefix = 'user_';

  final Box _box = Hive.box(boxName);

  List<GameTrackRecord> getRecords(int userId) {
    final raw = _box.get('$_recordsPrefix$userId');
    final records = raw is List
        ? raw
            .whereType<Map>()
            .map(GameTrackRecord.fromMap)
            .where((record) => record.id.isNotEmpty)
            .toList()
        : <GameTrackRecord>[];
    records.sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
    return records;
  }

  bool canRecord(int userId, DateTime now, Duration interval) {
    final records = getRecords(userId);
    return records.isEmpty || now.difference(records.last.recordedAt) >= interval;
  }

  Future<void> addRecord(int userId, GameTrackRecord record) async {
    final records = getRecords(userId)..add(record);
    records.sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
    await _save(userId, records);
  }

  Future<void> deleteRecord(int userId, String recordId) async {
    final records = getRecords(userId)
      ..removeWhere((record) => record.id == recordId);
    await _save(userId, records);
  }

  Future<void> restoreRecord(int userId, GameTrackRecord record) async {
    final records = getRecords(userId)
      ..removeWhere((item) => item.id == record.id)
      ..add(record);
    records.sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
    await _save(userId, records);
  }

  Future<void> removeUser(int userId) async {
    await _box.delete('$_recordsPrefix$userId');
  }

  Future<void> _save(int userId, List<GameTrackRecord> records) {
    return _box.put(
      '$_recordsPrefix$userId',
      records.map((record) => record.toMap()).toList(),
    );
  }
}

int _asInt(Object? value) => value is num
    ? value.toInt()
    : int.tryParse(value?.toString() ?? '') ?? 0;

double _asDouble(Object? value) => value is num
    ? value.toDouble()
    : double.tryParse(value?.toString() ?? '') ?? 0;
