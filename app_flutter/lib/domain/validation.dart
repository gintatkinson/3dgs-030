import 'package:app_flutter/domain/type_descriptor.dart';

final _iso8601Regex = RegExp(
  r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d+)?(Z|[+-]\d{2}:\d{2})$',
);

/// Validates that [value] is a well-formed ISO 8601 date-time string per RFC 6991 / RFC 9179.
///
/// Returns `null` if valid, or an error message string if invalid.
/// Returns `null` for null or empty input (optional field semantics).
String? validateIso8601(String? value) {
  if (value == null || value.isEmpty) {
    return null;
  }
  if (!_iso8601Regex.hasMatch(value)) {
    return 'Must be a valid ISO 8601 date-time (e.g. 2024-01-15T10:30:00Z)';
  }
  return null;
}

/// Generic validation function that evaluates constraints on a map of input values.
bool validateFields(Map<String, dynamic> input, List<FieldDescriptor> descriptors) {
  for (final fd in descriptors) {
    final value = input[fd.key];

    // If missing/empty, check required constraint. Otherwise skip validation if not required.
    if (value == null || (value is String && value.isEmpty)) {
      if (fd.required) {
        return false;
      }
      continue;
    }

    final strVal = value.toString();
    if (fd.type == 'int') {
      final parsed = int.tryParse(strVal);
      if (parsed == null) return false;
      if (fd.minValue != null && parsed < fd.minValue!) return false;
      if (fd.maxValue != null && parsed > fd.maxValue!) return false;
    } else if (fd.type == 'double' || fd.type == 'real') {
      final parsed = double.tryParse(strVal);
      if (parsed == null) return false;
      if (fd.minValue != null && parsed < fd.minValue!) return false;
      if (fd.maxValue != null && parsed > fd.maxValue!) return false;
    } else if (fd.type == 'string') {
      if (fd.pattern != null && fd.pattern!.isNotEmpty) {
        final regex = RegExp(fd.pattern!);
        if (!regex.hasMatch(strVal)) return false;
      }
    } else if (fd.type == 'enum') {
      if (fd.enumOptions != null && !fd.enumOptions!.contains(strVal)) {
        return false;
      }
    }
  }
  return true;
}
