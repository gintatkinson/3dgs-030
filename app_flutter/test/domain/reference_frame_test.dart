import 'package:app_flutter/domain/reference_frame.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReferenceFrame', () {
    test('default astronomicalBody is "earth"', () {
      final frame = ReferenceFrame();

      expect(frame.astronomicalBody, 'earth');
      expect(frame.alternateSystem, isNull);
    });

    test('construct with custom astronomicalBody', () {
      final frame = ReferenceFrame(astronomicalBody: 'mars');

      expect(frame.astronomicalBody, 'mars');
      expect(frame.alternateSystem, isNull);
    });

    test('construct with alternateSystem', () {
      final frame = ReferenceFrame(alternateSystem: 'WGS84');

      expect(frame.alternateSystem, 'WGS84');
      expect(frame.astronomicalBody, 'earth');
    });

    test('fromMap extracts both fields', () {
      const map = {
        'alternate_system': 'UTM',
        'astronomical_body': 'moon',
      };

      final frame = ReferenceFrame.fromMap(map);
      expect(frame.alternateSystem, 'UTM');
      expect(frame.astronomicalBody, 'moon');
    });

    test('fromMap handles null fields', () {
      final frame = ReferenceFrame.fromMap({});

      expect(frame.alternateSystem, isNull);
      expect(frame.astronomicalBody, 'earth');
    });

    test('toMap excludes null fields', () {
      final frame1 = ReferenceFrame(alternateSystem: 'WGS84');
      final map1 = frame1.toMap();
      expect(map1, contains('alternate_system'));
      expect(map1, isNot(contains('astronomical_body')));

      final frame2 = ReferenceFrame(
        alternateSystem: 'UTM',
        astronomicalBody: 'mars',
      );
      final map2 = frame2.toMap();
      expect(map2, contains('alternate_system'));
      expect(map2, contains('astronomical_body'));

      final frame3 = ReferenceFrame();
      final map3 = frame3.toMap();
      expect(map3, isEmpty);
    });

    test('copyWith preserves unchanged fields', () {
      final frame = ReferenceFrame(
        alternateSystem: 'WGS84',
        astronomicalBody: 'mars',
      );

      final copy = frame.copyWith();

      expect(copy.alternateSystem, 'WGS84');
      expect(copy.astronomicalBody, 'mars');
      expect(copy, isNot(same(frame)));
    });

    test('copyWith overrides specified fields', () {
      final frame = ReferenceFrame(
        alternateSystem: 'WGS84',
        astronomicalBody: 'mars',
      );

      final copy = frame.copyWith(alternateSystem: 'UTM', astronomicalBody: 'moon');

      expect(copy.alternateSystem, 'UTM');
      expect(copy.astronomicalBody, 'moon');
    });

    test('toString returns debug representation', () {
      final frame = ReferenceFrame(
        alternateSystem: 'WGS84',
        astronomicalBody: 'earth',
      );

      final str = frame.toString();
      expect(str, contains('ReferenceFrame'));
      expect(str, contains('alternateSystem'));
      expect(str, contains('astronomicalBody'));
    });
  });
}
