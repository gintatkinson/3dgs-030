import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:app_flutter/data/database_initializer.dart';
import 'package:app_flutter/data/data_sources/sqlite_data_source.dart';
import 'package:app_flutter/domain/reference_frame.dart';
import 'package:app_flutter/domain/validation.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('ReferenceFrame CRUD via SQLite', () {
    late Database db;
    late SqliteDataSource dataSource;

    const nodeId = 'test-ref-frame-node';

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

    // (a) Default reference frame for Earth
    test('default reference frame defaults astronomicalBody to earth', () async {
      await db.insert('properties', {
        'node_id': nodeId,
        'parent_node_id': null,
        'data_json': jsonEncode({
          'ietf-3dgs:reference-frame': <String, dynamic>{},
        }),
      });

      final rows = await db.query('properties',
          where: 'node_id = ?', whereArgs: [nodeId]);
      expect(rows, isNotEmpty);

      final decoded = jsonDecode(rows.first['data_json'] as String)
          as Map<String, dynamic>;
      final refMap = decoded['ietf-3dgs:reference-frame']
          as Map<String, dynamic>? ?? <String, dynamic>{};
      final frame = ReferenceFrame.fromMap(refMap);

      expect(frame.astronomicalBody, equals('earth'));
      expect(frame.alternateSystem, isNull);
    });

    // (b) Specify non-Earth body
    test('specify non-Earth astronomical body stored correctly', () async {
      await dataSource.saveProperties(nodeId, {
        'ietf-3dgs:reference-frame': {
          'astronomical_body': 'mars',
        },
      });

      final fetched = await dataSource.fetchProperties(nodeId);
      final nested = _nestFetched(fetched);
      final refMap = nested['ietf-3dgs:reference-frame'] as Map<String, dynamic>? ?? <String, dynamic>{};
      final frame = ReferenceFrame.fromMap(refMap);

      expect(frame.astronomicalBody, equals('mars'));
      expect(frame.alternateSystem, isNull);
    });

    // (c) Enable alternate reference system
    test('enable alternate reference system stored correctly', () async {
      await dataSource.saveProperties(nodeId, {
        'ietf-3dgs:reference-frame': {
          'alternate_system': 'virtual-reality-grid-7',
          'astronomical_body': 'earth',
        },
      });

      final fetched = await dataSource.fetchProperties(nodeId);
      final nested = _nestFetched(fetched);
      final refMap = nested['ietf-3dgs:reference-frame'] as Map<String, dynamic>? ?? <String, dynamic>{};
      final frame = ReferenceFrame.fromMap(refMap);

      expect(frame.alternateSystem, equals('virtual-reality-grid-7'));
      expect(frame.astronomicalBody, equals('earth'));
    });

    // (d) Alternate system absent when feature disabled
    test('alternate system absent when feature disabled', () async {
      await dataSource.saveProperties(nodeId, {
        'ietf-3dgs:reference-frame': {
          'astronomical_body': 'moon',
        },
      });

      final fetched = await dataSource.fetchProperties(nodeId);
      final nested = _nestFetched(fetched);
      final refMap = nested['ietf-3dgs:reference-frame'] as Map<String, dynamic>? ?? <String, dynamic>{};
      final frame = ReferenceFrame.fromMap(refMap);

      expect(frame.alternateSystem, isNull);
      expect(frame.astronomicalBody, equals('moon'));
    });

    // (e) Invalid astronomical body pattern
    test('invalid astronomical body with control characters rejected by validation', () async {
      const invalidBody = 'mars\x01invalid';

      final error = validateAstronomicalBody(invalidBody);
      expect(error, isA<String>());

      final valid = validateAstronomicalBody('mars');
      expect(valid, isNull);
    });

    // (f) Uppercase auto-conversion
    test('uppercase astronomical body normalized to lowercase', () async {
      await dataSource.saveProperties(nodeId, {
        'ietf-3dgs:reference-frame': {
          'astronomical_body': 'EARTH',
        },
      });

      final fetched = await dataSource.fetchProperties(nodeId);
      final nested = _nestFetched(fetched);
      final refMap = nested['ietf-3dgs:reference-frame'] as Map<String, dynamic>? ?? <String, dynamic>{};
      final frame = ReferenceFrame.fromMap(refMap);

      expect(frame.astronomicalBody, equals('earth'));
    });

    test('uppercase MARS normalized to mars', () async {
      await dataSource.saveProperties(nodeId, {
        'ietf-3dgs:reference-frame': {
          'astronomical_body': 'MARS',
        },
      });

      final fetched = await dataSource.fetchProperties(nodeId);
      final nested = _nestFetched(fetched);
      final refMap = nested['ietf-3dgs:reference-frame'] as Map<String, dynamic>? ?? <String, dynamic>{};
      final frame = ReferenceFrame.fromMap(refMap);

      expect(frame.astronomicalBody, equals('mars'));
    });

    test('JSON serialization roundtrip through SQLite', () async {
      final original = ReferenceFrame(
        alternateSystem: 'utc-grid-42',
        astronomicalBody: 'jupiter',
      );

      final properties = {
        'ietf-3dgs:reference-frame': original.toMap(),
      };

      await db.insert('properties', {
        'node_id': nodeId,
        'parent_node_id': null,
        'data_json': jsonEncode(properties),
      });

      final rows = await db.query('properties',
          where: 'node_id = ?', whereArgs: [nodeId]);
      final decoded = jsonDecode(rows.first['data_json'] as String)
          as Map<String, dynamic>;
      final refMap = decoded['ietf-3dgs:reference-frame'] as Map<String, dynamic>? ?? <String, dynamic>{};
      final reconstructed = ReferenceFrame.fromMap(refMap);

      expect(reconstructed.alternateSystem, equals(original.alternateSystem));
      expect(reconstructed.astronomicalBody, equals(original.astronomicalBody));
    });
  });

  group('ReferenceFrame validation', () {
    test('validateAstronomicalBody accepts valid lowercase name', () {
      expect(validateAstronomicalBody('earth'), isNull);
      expect(validateAstronomicalBody('mars'), isNull);
      expect(validateAstronomicalBody('jupiter'), isNull);
    });

    test('validateAstronomicalBody accepts hyphenated names', () {
      expect(validateAstronomicalBody('alpha-centauri'), isNull);
    });

    test('validateAstronomicalBody accepts names with spaces', () {
      expect(validateAstronomicalBody('proxima centauri'), isNull);
    });

    test('validateAstronomicalBody rejects control characters', () {
      expect(validateAstronomicalBody('bad\x01body'), isA<String>());
      expect(validateAstronomicalBody('bad\x02chars'), isA<String>());
    });

    test('validateAstronomicalBody returns null for empty input', () {
      expect(validateAstronomicalBody(''), isNull);
    });

    test('validateAstronomicalBody returns null for null input', () {
      expect(validateAstronomicalBody(null), isNull);
    });

    test('normalizeAstronomicalBody lowercases input', () {
      expect(normalizeAstronomicalBody('EARTH'), equals('earth'));
      expect(normalizeAstronomicalBody('Mars'), equals('mars'));
      expect(normalizeAstronomicalBody('JUPITER'), equals('jupiter'));
    });

    test('normalizeAstronomicalBody returns null for null input', () {
      expect(normalizeAstronomicalBody(null), isNull);
    });

    test('normalizeAstronomicalBody passes lowercase through', () {
      expect(normalizeAstronomicalBody('earth'), equals('earth'));
      expect(normalizeAstronomicalBody('mars'), equals('mars'));
    });
  });

  group('ReferenceFrame fromMap / toMap roundtrip', () {
    test('full roundtrip with both fields', () {
      final original = ReferenceFrame(
        alternateSystem: 'wgs84-grid',
        astronomicalBody: 'mars',
      );

      final map = original.toMap();
      final reconstructed = ReferenceFrame.fromMap(map);

      expect(reconstructed.alternateSystem, equals(original.alternateSystem));
      expect(reconstructed.astronomicalBody, equals(original.astronomicalBody));
    });

    test('roundtrip with only astronomicalBody', () {
      final original = ReferenceFrame(astronomicalBody: 'moon');

      final map = original.toMap();
      final reconstructed = ReferenceFrame.fromMap(map);

      expect(reconstructed.astronomicalBody, equals(original.astronomicalBody));
      expect(reconstructed.alternateSystem, isNull);
    });

    test('roundtrip with only alternateSystem', () {
      final original = ReferenceFrame(alternateSystem: 'utc-grid');

      final map = original.toMap();
      final reconstructed = ReferenceFrame.fromMap(map);

      expect(reconstructed.alternateSystem, equals(original.alternateSystem));
      expect(reconstructed.astronomicalBody, equals('earth'));
    });

    test('roundtrip with no fields set', () {
      final original = ReferenceFrame();

      final map = original.toMap();
      expect(map, isEmpty);

      final reconstructed = ReferenceFrame.fromMap(map);
      expect(reconstructed.astronomicalBody, equals('earth'));
      expect(reconstructed.alternateSystem, isNull);
    });

    test('fromMap with empty map returns defaults', () {
      final frame = ReferenceFrame.fromMap({});

      expect(frame.astronomicalBody, equals('earth'));
      expect(frame.alternateSystem, isNull);
    });

    test('toMap excludes null fields', () {
      final frame = ReferenceFrame(alternateSystem: 'grid-1');
      final map = frame.toMap();

      expect(map.containsKey('alternate_system'), isTrue);
      expect(map.containsKey('astronomical_body'), isFalse);
    });

    test('toMap excludes astronomical_body when null', () {
      final frame = ReferenceFrame();
      final map = frame.toMap();

      expect(map, isEmpty);
    });

    test('toMap includes astronomical_body only when explicitly set', () {
      final frame = ReferenceFrame(astronomicalBody: 'venus');
      final map = frame.toMap();

      expect(map.containsKey('astronomical_body'), isTrue);
      expect(map['astronomical_body'], equals('venus'));
    });
  });

  group('ReferenceFrame copyWith', () {
    test('copyWith preserves unchanged fields', () {
      final frame = ReferenceFrame(
        alternateSystem: 'wgs84-grid',
        astronomicalBody: 'mars',
      );

      final copy = frame.copyWith();

      expect(copy.alternateSystem, equals('wgs84-grid'));
      expect(copy.astronomicalBody, equals('mars'));
      expect(copy, isNot(same(frame)));
    });

    test('copyWith overrides specified fields', () {
      final frame = ReferenceFrame(
        alternateSystem: 'wgs84-grid',
        astronomicalBody: 'mars',
      );

      final copy = frame.copyWith(
        alternateSystem: 'utc-grid',
        astronomicalBody: 'moon',
      );

      expect(copy.alternateSystem, equals('utc-grid'));
      expect(copy.astronomicalBody, equals('moon'));
    });

    test('copyWith overrides only alternateSystem', () {
      final frame = ReferenceFrame(
        alternateSystem: 'wgs84-grid',
        astronomicalBody: 'mars',
      );

      final copy = frame.copyWith(alternateSystem: 'new-grid');

      expect(copy.alternateSystem, equals('new-grid'));
      expect(copy.astronomicalBody, equals('mars'));
    });

    test('copyWith overrides only astronomicalBody', () {
      final frame = ReferenceFrame(
        alternateSystem: 'wgs84-grid',
        astronomicalBody: 'mars',
      );

      final copy = frame.copyWith(astronomicalBody: 'venus');

      expect(copy.alternateSystem, equals('wgs84-grid'));
      expect(copy.astronomicalBody, equals('venus'));
    });
  });
}
