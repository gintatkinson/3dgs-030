import 'package:app_flutter/domain/type_descriptor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FieldDescriptor', () {
    group('readOnly', () {
      test('preserves flag when set to true', () {
        final fd = FieldDescriptor(
          key: 'name',
          label: 'Name',
          type: 'string',
          readOnly: true,
        );

        expect(fd.readOnly, isTrue);
      });

      test('defaults to false', () {
        final fd = FieldDescriptor(
          key: 'name',
          label: 'Name',
          type: 'string',
        );

        expect(fd.readOnly, isFalse);
      });
    });

    group('dateTime type normalization', () {
      test('normalizes dateTime type', () {
        final fd = FieldDescriptor.fromMap({
          'key': 'created_at',
          'label': 'Created At',
          'type': 'dateTime',
        });

        expect(fd.type, 'dateTime');
      });

      test('normalizes datetime (lowercase)', () {
        final fd = FieldDescriptor.fromMap({
          'key': 'created_at',
          'label': 'Created At',
          'type': 'datetime',
        });

        expect(fd.type, 'dateTime');
      });

      test('preserves other types unchanged', () {
        final fd = FieldDescriptor.fromMap({
          'key': 'name',
          'label': 'Name',
          'type': 'string',
        });

        expect(fd.type, 'string');
      });
    });

    group('fromMap', () {
      test('parses readOnly as true', () {
        final fd = FieldDescriptor.fromMap({
          'key': 'name',
          'label': 'Name',
          'type': 'string',
          'readOnly': true,
        });

        expect(fd.readOnly, isTrue);
      });

      test('parses read_only as true', () {
        final fd = FieldDescriptor.fromMap({
          'key': 'name',
          'label': 'Name',
          'type': 'string',
          'read_only': true,
        });

        expect(fd.readOnly, isTrue);
      });

      test('parses readOnly as false', () {
        final fd = FieldDescriptor.fromMap({
          'key': 'name',
          'label': 'Name',
          'type': 'string',
          'readOnly': false,
        });

        expect(fd.readOnly, isFalse);
      });

      test('defaults readOnly to false when absent', () {
        final fd = FieldDescriptor.fromMap({
          'key': 'name',
          'label': 'Name',
          'type': 'string',
        });

        expect(fd.readOnly, isFalse);
      });

      test('parses all known fields from map', () {
        final fd = FieldDescriptor.fromMap({
          'key': 'voltage',
          'label': 'Voltage',
          'type': 'double',
          'section_label': 'Electrical',
          'section_order': 1,
          'required': true,
          'min_value': 0.0,
          'max_value': 1000.0,
          'pattern': r'^\d+\.?\d*$',
          'enum_options': ['5', '12', '24'],
          'enum_display_names': ['5V', '12V', '24V'],
          'default_value': '5',
          'input_formatters': ['uppercase'],
          'readOnly': true,
        });

        expect(fd.key, 'voltage');
        expect(fd.label, 'Voltage');
        expect(fd.type, 'double');
        expect(fd.sectionLabel, 'Electrical');
        expect(fd.sectionOrder, 1);
        expect(fd.required, isTrue);
        expect(fd.minValue, 0.0);
        expect(fd.maxValue, 1000.0);
        expect(fd.pattern, r'^\d+\.?\d*$');
        expect(fd.enumOptions, ['5', '12', '24']);
        expect(fd.enumDisplayNames, ['5V', '12V', '24V']);
        expect(fd.defaultValue, '5');
        expect(fd.inputFormatters, ['uppercase']);
        expect(fd.readOnly, isTrue);
      });
    });

    group('toMap', () {
      test('includes read_only key when readOnly is true', () {
        final fd = FieldDescriptor(
          key: 'name',
          label: 'Name',
          type: 'string',
          readOnly: true,
        );

        final map = fd.toMap();
        expect(map['read_only'], isTrue);
      });

      test('includes read_only key when readOnly is false', () {
        final fd = FieldDescriptor(
          key: 'name',
          label: 'Name',
          type: 'string',
          readOnly: false,
        );

        final map = fd.toMap();
        expect(map['read_only'], isFalse);
      });

      test('serializes all fields to map', () {
        final fd = FieldDescriptor(
          key: 'voltage',
          label: 'Voltage',
          type: 'double',
          sectionLabel: 'Electrical',
          sectionOrder: 1,
          required: true,
          minValue: 0.0,
          maxValue: 1000.0,
          pattern: r'^\d+\.?\d*$',
          enumOptions: ['5', '12', '24'],
          enumDisplayNames: ['5V', '12V', '24V'],
          defaultValue: '5',
          inputFormatters: ['uppercase'],
          readOnly: true,
        );

        final map = fd.toMap();

        expect(map['key'], 'voltage');
        expect(map['label'], 'Voltage');
        expect(map['type'], 'double');
        expect(map['section_label'], 'Electrical');
        expect(map['section_order'], 1);
        expect(map['required'], isTrue);
        expect(map['min_value'], 0.0);
        expect(map['max_value'], 1000.0);
        expect(map['pattern'], r'^\d+\.?\d*$');
        expect(map['enum_options'], ['5', '12', '24']);
        expect(map['enum_display_names'], ['5V', '12V', '24V']);
        expect(map['default_value'], '5');
        expect(map['input_formatters'], ['uppercase']);
        expect(map['read_only'], isTrue);
      });

      test('omits null optional fields', () {
        final fd = FieldDescriptor(
          key: 'name',
          label: 'Name',
          type: 'string',
        );

        final map = fd.toMap();

        expect(map['key'], 'name');
        expect(map['label'], 'Name');
        expect(map['type'], 'string');
        expect(map.containsKey('section_label'), isFalse);
        expect(map.containsKey('enum_options'), isFalse);
        expect(map.containsKey('enum_display_names'), isFalse);
        expect(map.containsKey('pattern'), isFalse);
        expect(map.containsKey('min_value'), isFalse);
        expect(map.containsKey('max_value'), isFalse);
        expect(map.containsKey('default_value'), isFalse);
        expect(map.containsKey('input_formatters'), isFalse);
      });
    });

    group('equality', () {
      test('two FieldDescriptors with same values are equal', () {
        final a = FieldDescriptor(
          key: 'name',
          label: 'Name',
          type: 'string',
          readOnly: true,
        );
        final b = FieldDescriptor(
          key: 'name',
          label: 'Name',
          type: 'string',
          readOnly: true,
        );

        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('two FieldDescriptors with different readOnly are not equal', () {
        final a = FieldDescriptor(
          key: 'name',
          label: 'Name',
          type: 'string',
          readOnly: true,
        );
        final b = FieldDescriptor(
          key: 'name',
          label: 'Name',
          type: 'string',
          readOnly: false,
        );

        expect(a, isNot(equals(b)));
      });

      test('two FieldDescriptors with different type are not equal', () {
        final a = FieldDescriptor(
          key: 'name',
          label: 'Name',
          type: 'string',
        );
        final b = FieldDescriptor(
          key: 'name',
          label: 'Name',
          type: 'int',
        );

        expect(a, isNot(equals(b)));
      });
    });
  });
}
