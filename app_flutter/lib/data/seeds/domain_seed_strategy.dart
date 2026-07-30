import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:app_flutter/data/database_initializer.dart';

/// Concrete implementation of [SeedStrategy] that seeds the database with domain-specific mock data.
///
/// This includes base type definitions, attributes, space nodes, real NTT exchanges,
/// cable landing stations, and their interconnectivity links.
class DomainSeedStrategy implements SeedStrategy {
  
  /// Seeds the database by batch-inserting default schemas, nodes, and instances.
  ///
  /// Assumes the database tables have been successfully created by [DatabaseInitializer].
  @override
  Future<void> seed(Database db) async {
    final batch = db.batch();

    final spaceDetails = ['Components', 'Telemetry', 'Logs', 'Links'];
    final nttDetails = ['Components', 'Alarms', 'Links'];
    final landingDetails = ['Components', 'Links'];

    final displayNames = {
      'Components': 'Components',
      'Telemetry': 'Telemetry',
      'Logs': 'Logs',
      'Alarms': 'Alarms',
      'Links': 'Links',
    };

    // 1. Seed base system type definitions and their 50 generic attributes
    for (final d in displayNames.keys) {
      batch.insert('type_definitions', {
        'type_name': d,
        'display_name': displayNames[d] ?? d,
        'icon_name': 'widgets',
      }, conflictAlgorithm: ConflictAlgorithm.ignore);

      for (int i = 1; i <= 50; i++) {
        batch.insert('type_attributes', {
          'type_name': d,
          'attr_key': 'field_$i',
          'label': 'Field $i',
          'attr_type': 'string',
          'section_label': 'General',
          'section_order': 0,
          'is_required': 0,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
    }

    // 2. Generate 100 space orbit telemetry nodes
    final spaceNodes = <String>[];
    for (int i = 0; i < 100; i++) {
      final id = 'space_$i';
      spaceNodes.add(id);
      final lat = 25.0 + (i / 100.0) * 20.0;
      final lon = 125.0 + (i % 20) * 1.0;
      _addNodeToBatch(batch, id, null, spaceDetails, lat: lat, lon: lon, height: 500000.0, timestamp: '2026-07-30T09:00:00Z', validUntil: '2027-07-30T09:00:00Z');
    }

    // 3. Load and parse real NTT exchanges data from assets
    final nttFile = File('assets/ntt_exchanges_japan_763.json');
    String nttJsonString;
    if (await nttFile.exists()) {
      nttJsonString = await nttFile.readAsString();
    } else {
      nttJsonString = await rootBundle.loadString('assets/ntt_exchanges_japan_763.json');
    }
    final nttJson = jsonDecode(nttJsonString) as List;

    final nttNodes = <Map<String, dynamic>>[];
    for (int i = 0; i < nttJson.length; i++) {
      final item = nttJson[i];
      final id = 'ntt_exchange_$i';
      nttNodes.add({
        'id': id,
        'lat': (item['latitude'] as num).toDouble(),
        'lon': (item['longitude'] as num).toDouble(),
      });
      _addNodeToBatch(batch, id, null, nttDetails, lat: (item['latitude'] as num).toDouble(), lon: (item['longitude'] as num).toDouble(), height: 0.0, timestamp: '2026-07-30T09:00:00Z', validUntil: '2026-12-31T23:59:59Z');
    }

    // 4. Load and parse cable landing stations data from assets
    final landingFile = File('assets/cable_landing_stations_japan.json');
    String landingJsonString;
    if (await landingFile.exists()) {
      landingJsonString = await landingFile.readAsString();
    } else {
      landingJsonString = await rootBundle.loadString('assets/cable_landing_stations_japan.json');
    }
    final landingJson = jsonDecode(landingJsonString) as List;

    final landingNodes = <Map<String, dynamic>>[];
    for (int i = 0; i < landingJson.length; i++) {
      final item = landingJson[i];
      final id = 'cable_landing_$i';
      landingNodes.add({
        'id': id,
        'lat': (item['latitude'] as num).toDouble(),
        'lon': (item['longitude'] as num).toDouble(),
      });
      _addNodeToBatch(batch, id, null, landingDetails, lat: (item['latitude'] as num).toDouble(), lon: (item['longitude'] as num).toDouble(), height: 0.0, timestamp: '2026-07-30T09:00:00Z');
    }

    // 5. Interconnect stations, exchanges, and orbits with interface links
    final Set<String> addedLinks = {};
    int linkIdCounter = 0;

    void addLink(String from, String to) {
      final key1 = '${from}_$to';
      final key2 = '${to}_$from';
      if (!addedLinks.contains(key1) && !addedLinks.contains(key2)) {
        addedLinks.add(key1);
        addedLinks.add(key2);
        batch.insert('instances', {
          'id': 'link_${linkIdCounter++}',
          'parent_node_id': from,
          'type_name': 'interface',
          'data_json': jsonEncode({'description': 'link to node $to'}),
        });
      }
    }

    double distSq(double lat1, double lon1, double lat2, double lon2) {
      return (lat1 - lat2) * (lat1 - lat2) + (lon1 - lon2) * (lon1 - lon2);
    }

    for (int i = 0; i < nttNodes.length; i++) {
      final current = nttNodes[i];
      final distances = <Map<String, dynamic>>[];
      for (int j = 0; j < nttNodes.length; j++) {
        if (i == j) continue;
        final target = nttNodes[j];
        distances.add({
          'id': target['id'],
          'dist': distSq(
            current['lat'] as double,
            current['lon'] as double,
            target['lat'] as double,
            target['lon'] as double,
          ),
        });
      }
      distances.sort((a, b) => (a['dist'] as double).compareTo(b['dist'] as double));
      for (int k = 0; k < 2 && k < distances.length; k++) {
        addLink(current['id'] as String, distances[k]['id'] as String);
      }
      
      final space1 = spaceNodes[(i * 2) % 100];
      final space2 = spaceNodes[(i * 2 + 1) % 100];
      addLink(current['id'] as String, space1);
      addLink(current['id'] as String, space2);
    }

    for (int i = 0; i < landingNodes.length; i++) {
      final current = landingNodes[i];
      final distances = <Map<String, dynamic>>[];
      for (int j = 0; j < nttNodes.length; j++) {
        final target = nttNodes[j];
        distances.add({
          'id': target['id'],
          'dist': distSq(
            current['lat'] as double,
            current['lon'] as double,
            target['lat'] as double,
            target['lon'] as double,
          ),
        });
      }
      distances.sort((a, b) => (a['dist'] as double).compareTo(b['dist'] as double));
      for (int k = 0; k < 5 && k < distances.length; k++) {
        addLink(current['id'] as String, distances[k]['id'] as String);
      }
    }

    await batch.commit(noResult: true);
  }

  /// Helper helper to insert a complete node configuration (type_definition, relation, properties, and instances).
  void _addNodeToBatch(
    Batch batch,
    String node,
    String? parent,
    List<String> details, {
    required double lat,
    required double lon,
    required double height,
    String? timestamp,
    String? validUntil,
  }) {
    batch.insert('type_definitions', {
      'type_name': node,
      'display_name': node.replaceAll('_', ' '),
      'icon_name': 'insert_drive_file',
    });

    for (final d in details) {
      batch.insert('type_relations', {
        'parent_type_name': node,
        'relation_name': 'contains',
        'child_type_name': d,
        'child_label': d == 'Components' ? 'Components' : d.replaceAll('_', ' ').split(' ').map((s) => s.isEmpty ? '' : s[0].toUpperCase() + s.substring(1)).join(' '),
      });
    }

    for (int i = 1; i <= 50; i++) {
      batch.insert('type_attributes', {
        'type_name': node,
        'attr_key': 'field_$i',
        'label': 'Field $i',
        'attr_type': 'string',
        'section_label': 'General',
        'section_order': 0,
        'is_required': 0,
      });
    }

    final propertiesMap = <String, dynamic>{
      for (int j = 1; j <= 50; j++) 'field_$j': 'val_${node}_field_$j',
      'location': {
        'ellipsoid': {
          'latitude': lat,
          'longitude': lon,
          'height': height,
        }
      },
      if (timestamp != null) 'timestamp': timestamp,
      if (validUntil != null) 'valid-until': validUntil,
    };
    batch.insert('properties', {
      'node_id': node,
      'parent_node_id': parent,
      'data_json': jsonEncode(propertiesMap),
    });

    for (final d in details) {
      for (int k = 1; k <= 5; k++) {
        final instId = 'inst_${node}_${d}_$k';
        final instanceMap = {
          for (int j = 1; j <= 50; j++) 'field_$j': 'val_inst_${node}_${d}_${k}_field_$j'
        };
        batch.insert('instances', {
          'id': instId,
          'parent_node_id': node,
          'type_name': d,
          'data_json': jsonEncode(instanceMap),
        });
      }
    }
  }
}
