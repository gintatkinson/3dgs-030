import 'package:app_flutter/domain/validation.dart';
import 'package:app_flutter/domain/type_descriptor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('validateFields', () {
    test('required field validation', () {
      final desc = <FieldDescriptor>[
        const FieldDescriptor(key: 'name', label: 'Name', type: 'string', required: true),
      ];
      expect(validateFields({'name': 'John'}, desc), isTrue);
      expect(validateFields({'name': ''}, desc), isFalse);
      expect(validateFields({}, desc), isFalse);
    });

    test('optional field validation when empty', () {
      final desc = <FieldDescriptor>[
        const FieldDescriptor(key: 'name', label: 'Name', type: 'string', required: false, pattern: '^[A-Z]{3}\$'),
      ];
      // Since it is optional and empty, it should pass without regex check
      expect(validateFields({}, desc), isTrue);
      expect(validateFields({'name': ''}, desc), isTrue);
      expect(validateFields({'name': 'ABC'}, desc), isTrue);
      expect(validateFields({'name': 'ab'}, desc), isFalse); // fails pattern if value present
    });

    test('integer range constraints', () {
      final desc = <FieldDescriptor>[
        const FieldDescriptor(key: 'age', label: 'Age', type: 'int', required: true, minValue: 18, maxValue: 99),
      ];
      expect(validateFields({'age': 20}, desc), isTrue);
      expect(validateFields({'age': '20'}, desc), isTrue); // parses string int
      expect(validateFields({'age': 17}, desc), isFalse);
      expect(validateFields({'age': 100}, desc), isFalse);
      expect(validateFields({'age': 'not_an_int'}, desc), isFalse);
    });

    test('double range constraints', () {
      final desc = <FieldDescriptor>[
        const FieldDescriptor(key: 'score', label: 'Score', type: 'double', required: true, minValue: 1.5, maxValue: 5.0),
      ];
      expect(validateFields({'score': 3.14}, desc), isTrue);
      expect(validateFields({'score': '3.14'}, desc), isTrue);
      expect(validateFields({'score': 1.4}, desc), isFalse);
      expect(validateFields({'score': 5.1}, desc), isFalse);
      expect(validateFields({'score': 'invalid'}, desc), isFalse);
    });

    test('pattern regex constraints', () {
      final desc = <FieldDescriptor>[
        const FieldDescriptor(key: 'code', label: 'Code', type: 'string', required: true, pattern: '^[A-Z]{2}\$'),
      ];
      expect(validateFields({'code': 'FI'}, desc), isTrue);
      expect(validateFields({'code': 'US'}, desc), isTrue);
      expect(validateFields({'code': 'us'}, desc), isFalse);
      expect(validateFields({'code': 'USA'}, desc), isFalse);
    });

    test('enum options constraints', () {
      final desc = <FieldDescriptor>[
        const FieldDescriptor(
          key: 'status',
          label: 'Status',
          type: 'enum',
          required: true,
          enumOptions: ['ACTIVE', 'INACTIVE'],
        ),
      ];
      expect(validateFields({'status': 'ACTIVE'}, desc), isTrue);
      expect(validateFields({'status': 'INACTIVE'}, desc), isTrue);
      expect(validateFields({'status': 'PENDING'}, desc), isFalse);
    });
  });

  group('validateIso8601', () {
    test('valid ISO 8601 returns null', () {
      expect(validateIso8601('2024-01-15T10:30:00Z'), isNull);
    });

    test('valid with milliseconds returns null', () {
      expect(validateIso8601('2024-01-15T10:30:00.123Z'), isNull);
    });

    test('valid with timezone +HH:MM returns null', () {
      expect(validateIso8601('2024-01-15T10:30:00+05:30'), isNull);
    });

    test('valid with timezone -HH:MM returns null', () {
      expect(validateIso8601('2024-01-15T10:30:00-08:00'), isNull);
    });

    test('null input returns null', () {
      expect(validateIso8601(null), isNull);
    });

    test('empty input returns null', () {
      expect(validateIso8601(''), isNull);
    });

    test('invalid format returns error message', () {
      expect(validateIso8601('not-a-date'), isA<String>());
    });

    test('missing time part returns error', () {
      expect(validateIso8601('2024-01-15'), isA<String>());
    });
  });

  group('validateAstronomicalBody', () {
    test('"earth" is valid', () {
      expect(validateAstronomicalBody('earth'), isNull);
    });

    test('"mars" is valid', () {
      expect(validateAstronomicalBody('mars'), isNull);
    });

    test('"67p/churyumov-gerasimenko" is valid', () {
      expect(validateAstronomicalBody('67p/churyumov-gerasimenko'), isNull);
    });

    test('"enceladus" is valid', () {
      expect(validateAstronomicalBody('enceladus'), isNull);
    });

    test('null returns null', () {
      expect(validateAstronomicalBody(null), isNull);
    });

    test('empty string returns null', () {
      expect(validateAstronomicalBody(''), isNull);
    });

    test('value with control character is invalid', () {
      expect(validateAstronomicalBody('\x00'), isA<String>());
    });
  });

  group('normalizeAstronomicalBody', () {
    test('"Earth" normalizes to "earth"', () {
      expect(normalizeAstronomicalBody('Earth'), equals('earth'));
    });

    test('"EARTH" normalizes to "earth"', () {
      expect(normalizeAstronomicalBody('EARTH'), equals('earth'));
    });

    test('"MARS" normalizes to "mars"', () {
      expect(normalizeAstronomicalBody('MARS'), equals('mars'));
    });

    test('null returns null', () {
      expect(normalizeAstronomicalBody(null), isNull);
    });

    test('empty returns empty', () {
      expect(normalizeAstronomicalBody(''), equals(''));
    });
  });
}
