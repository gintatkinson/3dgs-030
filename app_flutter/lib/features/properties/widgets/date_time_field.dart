import 'package:flutter/material.dart';
import 'package:app_flutter/domain/type_descriptor.dart';
import 'package:app_flutter/domain/validation.dart';

class DateTimePickerField extends StatefulWidget {
  final FieldDescriptor field;
  final String? initialValue;
  final bool readOnly;
  final void Function(String) onChanged;
  final String? Function(String?)? validator;

  const DateTimePickerField({
    super.key,
    required this.field,
    this.initialValue,
    this.readOnly = false,
    required this.onChanged,
    this.validator,
  });

  @override
  State<DateTimePickerField> createState() => _DateTimePickerFieldState();
}

class _DateTimePickerFieldState extends State<DateTimePickerField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(DateTimePickerField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != oldWidget.initialValue) {
      _controller.text = widget.initialValue ?? '';
    }
  }

  String _formatUtc(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final mi = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '$y-$m-${d}T$h:$mi:${s}Z';
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now().toUtc();
    DateTime? date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;

    TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now),
    );
    if (time == null || !mounted) return;

    final combined = DateTime(date.year, date.month, date.day, time.hour, time.minute).toUtc();
    _controller.text = _formatUtc(combined);
    widget.onChanged(_controller.text);
  }

  String? _defaultValidator(String? value) {
    return validateIso8601(value);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.readOnly) {
      final value = widget.initialValue;
      return Text(
        value != null && value.isNotEmpty ? value : 'Not set',
        style: Theme.of(context).textTheme.bodyMedium,
      );
    }

    final cs = Theme.of(context).colorScheme;

    return TextField(
      controller: _controller,
      style: Theme.of(context).textTheme.bodyMedium,
      decoration: InputDecoration(
        labelText: widget.field.label,
        suffixIcon: IconButton(
          icon: const Icon(Icons.calendar_today),
          onPressed: _pickDateTime,
        ),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
        filled: true,
        fillColor: cs.surface,
        enabledBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(6.0)),
          borderSide: BorderSide(color: Theme.of(context).dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(6.0)),
          borderSide: BorderSide(color: cs.primary, width: 1.5),
        ),
        errorText: (widget.validator ?? _defaultValidator)(_controller.text),
      ),
      onChanged: (value) {
        widget.onChanged(value);
        setState(() {});
      },
    );
  }
}
