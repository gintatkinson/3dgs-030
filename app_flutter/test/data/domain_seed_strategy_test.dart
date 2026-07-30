import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:app_flutter/data/database_initializer.dart';
import 'package:app_flutter/data/seeds/domain_seed_strategy.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('DomainSeedStrategy geo-location timestamps', () {
    late Database db;

    setUp(() async {
      db = await DatabaseInitializer.create(
        dbPath: inMemoryDatabasePath,
        seed: false,
      );
      await DomainSeedStrategy().seed(db);
    });

    tearDown(() async {
      await db.close();
    });

    Future<Map<String, dynamic>> getNodeProperties(String nodeId) async {
      final result = await db.query(
        'properties',
        where: 'node_id = ?',
        whereArgs: [nodeId],
      );
      return jsonDecode(result.first['data_json'] as String)
          as Map<String, dynamic>;
    }

    test('seeded space node properties contain timestamp', () async {
      final props = await getNodeProperties('space_0');
      expect(props, contains('timestamp'));
    });

    test('seeded space node properties contain valid-until', () async {
      final props = await getNodeProperties('space_0');
      expect(props, contains('valid-until'));
    });

    test('seeded NTT exchange node properties contain timestamp', () async {
      final props = await getNodeProperties('ntt_exchange_0');
      expect(props, contains('timestamp'));
    });

    test('seeded NTT exchange node properties contain valid-until', () async {
      final props = await getNodeProperties('ntt_exchange_0');
      expect(props, contains('valid-until'));
    });

    test('seeded cable landing station node properties contain timestamp',
        () async {
      final props = await getNodeProperties('cable_landing_0');
      expect(props, contains('timestamp'));
    });

    test('timestamp values are valid ISO 8601 format', () async {
      final spaceProps = await getNodeProperties('space_0');
      final nttProps = await getNodeProperties('ntt_exchange_0');
      final landingProps = await getNodeProperties('cable_landing_0');

      final iso8601Pattern =
          RegExp(r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$');

      expect(
        iso8601Pattern.hasMatch(spaceProps['timestamp'] as String),
        isTrue,
        reason: 'space node timestamp should be ISO 8601',
      );
      expect(
        iso8601Pattern.hasMatch(nttProps['timestamp'] as String),
        isTrue,
        reason: 'NTT exchange timestamp should be ISO 8601',
      );
      expect(
        iso8601Pattern.hasMatch(landingProps['timestamp'] as String),
        isTrue,
        reason: 'landing station timestamp should be ISO 8601',
      );
      expect(
        iso8601Pattern.hasMatch(spaceProps['valid-until'] as String),
        isTrue,
        reason: 'space node valid-until should be ISO 8601',
      );
      expect(
        iso8601Pattern.hasMatch(nttProps['valid-until'] as String),
        isTrue,
        reason: 'NTT exchange valid-until should be ISO 8601',
      );
    });
  });
}
