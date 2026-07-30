import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:app_flutter/data/database_initializer.dart';
import 'package:app_flutter/data/data_sources/sqlite_data_source.dart';
import 'package:app_flutter/domain/geo_location.dart';
import 'package:app_flutter/domain/validation.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('GeoLocation CRUD via SQLite', () {
    late Database db;
    late SqliteDataSource dataSource;

    const nodeId = 'test-node-1';

    setUp(() async {
      db = await DatabaseInitializer.create(
        dbPath: inMemoryDatabasePath,
        seed: false,
      );
      dataSource = SqliteDataSource(db);
    });

    tearDown(() async {
      await db.close();
    });

    Map<String, dynamic> _nestFetched(Map<String, dynamic> flat) {
      final nested = <String, dynamic>{};
      for (final entry in flat.entries) {
        final key = entry.key as String;
        final dotIdx = key.indexOf('.');
        if (dotIdx == -1) {
          nested[key] = entry.value;
        } else {
          final parent = key.substring(0, dotIdx);
          final child = key.substring(dotIdx + 1);
          final sub = (nested[parent] ??= <String, dynamic>{}) as Map;
          sub[child] = entry.value;
        }
      }
      return nested;
    }

    test('fetch geo-location properties with timestamp and valid-until', () async {
      final properties = {
        'ietf-geo-location:geo-location': {
          'timestamp': '2024-01-15T10:30:00Z',
          'valid-until': '2024-12-31T23:59:59Z',
        },
      };

      await db.insert('properties', {
        'node_id': nodeId,
        'parent_node_id': null,
        'data_json': jsonEncode(properties),
      });

      final fetched = await dataSource.fetchProperties(nodeId);
      expect(fetched, isNotEmpty);

      final nested = _nestFetched(fetched);
      final geo = GeoLocation.fromMap(nested);
      expect(geo.timestamp, equals('2024-01-15T10:30:00Z'));
      expect(geo.validUntil, equals('2024-12-31T23:59:59Z'));
    });

    test('save properties with only timestamp, verify via direct DB read', () async {
      await dataSource.saveProperties(nodeId, {
        'ietf-geo-location:geo-location': {
          'timestamp': '2024-06-01T12:00:00Z',
        },
      });

      final rows = await db.query('properties',
          where: 'node_id = ?', whereArgs: [nodeId]);
      expect(rows, isNotEmpty);

      final decoded = jsonDecode(rows.first['data_json'] as String)
          as Map<String, dynamic>;
      final geo = GeoLocation.fromMap(decoded);

      expect(geo.timestamp, equals('2024-06-01T12:00:00Z'));
      expect(geo.validUntil, isNull);
    });

    test('save properties with both timestamp and valid-until, verify via direct DB read', () async {
      await dataSource.saveProperties(nodeId, {
        'ietf-geo-location:geo-location': {
          'timestamp': '2024-03-15T08:00:00Z',
          'valid-until': '2024-09-15T20:00:00Z',
        },
      });

      final rows = await db.query('properties',
          where: 'node_id = ?', whereArgs: [nodeId]);
      expect(rows, isNotEmpty);

      final decoded = jsonDecode(rows.first['data_json'] as String)
          as Map<String, dynamic>;
      final geo = GeoLocation.fromMap(decoded);

      expect(geo.timestamp, equals('2024-03-15T08:00:00Z'));
      expect(geo.validUntil, equals('2024-09-15T20:00:00Z'));
    });

    test('omit valid-until from properties, verify via direct DB read', () async {
      await dataSource.saveProperties(nodeId, {
        'ietf-geo-location:geo-location': {
          'timestamp': '2024-07-01T00:00:00Z',
        },
      });

      final rows = await db.query('properties',
          where: 'node_id = ?', whereArgs: [nodeId]);
      expect(rows, isNotEmpty);

      final decoded = jsonDecode(rows.first['data_json'] as String)
          as Map<String, dynamic>;
      final geo = GeoLocation.fromMap(decoded);

      expect(geo.timestamp, equals('2024-07-01T00:00:00Z'));
      expect(geo.validUntil, isNull);
    });
  });

  group('GeoLocation validation', () {
    test('valid ISO 8601 passes validation', () {
      expect(validateIso8601('2024-01-15T10:30:00Z'), isNull);
    });

    test('valid ISO 8601 with milliseconds passes validation', () {
      expect(validateIso8601('2024-01-15T10:30:00.123Z'), isNull);
    });

    test('valid ISO 8601 with timezone offset passes validation', () {
      expect(validateIso8601('2024-01-15T10:30:00+05:30'), isNull);
    });

    test('null input returns null', () {
      expect(validateIso8601(null), isNull);
    });

    test('empty input returns null', () {
      expect(validateIso8601(''), isNull);
    });

    test('invalid ISO 8601 string is rejected', () {
      expect(validateIso8601('not-a-date'), isA<String>());
    });

    test('date without time part is rejected', () {
      expect(validateIso8601('2024-01-15'), isA<String>());
    });

    test('completely garbled string is rejected', () {
      expect(validateIso8601('INVALID_TIMESTAMP_12345'), isA<String>());
    });
  });

  group('GeoLocation fromMap / toMap roundtrip', () {
    test('full roundtrip with both fields', () {
      final original = GeoLocation(
        timestamp: '2024-01-15T10:30:00Z',
        validUntil: '2024-12-31T23:59:59Z',
      );

      final map = original.toMap();
      final reconstructed = GeoLocation.fromMap(map);

      expect(reconstructed.timestamp, equals(original.timestamp));
      expect(reconstructed.validUntil, equals(original.validUntil));
    });

    test('roundtrip with only timestamp', () {
      final original = GeoLocation(
        timestamp: '2024-06-01T12:00:00Z',
      );

      final map = original.toMap();
      final reconstructed = GeoLocation.fromMap(map);

      expect(reconstructed.timestamp, equals(original.timestamp));
      expect(reconstructed.validUntil, isNull);
    });

    test('fromMap with nested ietf-geo-location:geo-location key', () {
      final nested = {
        'ietf-geo-location:geo-location': {
          'timestamp': '2024-01-15T10:30:00Z',
          'valid-until': '2025-01-15T10:30:00Z',
        },
      };

      final geo = GeoLocation.fromMap(nested);
      expect(geo.timestamp, equals('2024-01-15T10:30:00Z'));
      expect(geo.validUntil, equals('2025-01-15T10:30:00Z'));
    });

    test('fromMap with flat map (no nesting)', () {
      final flat = {
        'timestamp': '2024-02-01T00:00:00Z',
        'valid-until': '2024-08-01T00:00:00Z',
      };

      final geo = GeoLocation.fromMap(flat);
      expect(geo.timestamp, equals('2024-02-01T00:00:00Z'));
      expect(geo.validUntil, equals('2024-08-01T00:00:00Z'));
    });

    test('toMap excludes null fields', () {
      final geo = GeoLocation(timestamp: '2024-01-01T00:00:00Z');
      final map = geo.toMap();

      expect(map.containsKey('timestamp'), isTrue);
      expect(map.containsKey('valid-until'), isFalse);
    });
  });
}
