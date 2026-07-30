import 'package:app_flutter/domain/geo_location.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GeoLocation', () {
    test('construct with timestamp only', () {
      final geo = GeoLocation(timestamp: '2024-07-01T12:00:00Z');

      expect(geo.timestamp, '2024-07-01T12:00:00Z');
      expect(geo.validUntil, isNull);
    });

    test('construct with both timestamp and validUntil', () {
      final geo = GeoLocation(
        timestamp: '2024-07-01T12:00:00Z',
        validUntil: '2024-12-31T23:59:59Z',
      );

      expect(geo.timestamp, '2024-07-01T12:00:00Z');
      expect(geo.validUntil, '2024-12-31T23:59:59Z');
    });

    test('fromMap with nested JSON structure', () {
      const map = {
        'ietf-geo-location:geo-location': {
          'timestamp': '2024-01-15T08:30:00Z',
          'valid-until': '2025-01-15T08:30:00Z',
        },
      };

      final geo = GeoLocation.fromMap(map);
      expect(geo.timestamp, '2024-01-15T08:30:00Z');
      expect(geo.validUntil, '2025-01-15T08:30:00Z');
    });

    test('fromMap with null values', () {
      final geo = GeoLocation.fromMap({});

      expect(geo.timestamp, isNull);
      expect(geo.validUntil, isNull);
    });

    test('toMap excludes null fields', () {
      final geo1 = GeoLocation(timestamp: '2024-07-01T12:00:00Z');
      final map1 = geo1.toMap();
      expect(map1, contains('timestamp'));
      expect(map1, isNot(contains('valid-until')));

      final geo2 = GeoLocation(
        timestamp: '2024-07-01T12:00:00Z',
        validUntil: '2024-12-31T23:59:59Z',
      );
      final map2 = geo2.toMap();
      expect(map2, contains('timestamp'));
      expect(map2, contains('valid-until'));

      final geo3 = GeoLocation();
      final map3 = geo3.toMap();
      expect(map3, isEmpty);
    });

    test('toString returns debug representation', () {
      final geo = GeoLocation(
        timestamp: '2024-07-01T12:00:00Z',
        validUntil: '2024-12-31T23:59:59Z',
      );

      final str = geo.toString();
      expect(str, contains('GeoLocation'));
      expect(str, contains('timestamp'));
      expect(str, contains('validUntil'));
    });
  });
}
