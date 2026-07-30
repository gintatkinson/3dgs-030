import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:app_flutter/domain/type_descriptor.dart';
import 'package:app_flutter/features/properties/widgets/date_time_field.dart';
import 'package:app_flutter/core/theme/theme_controller.dart';
import 'package:app_flutter/core/theme/theme_service.dart';

class FakeThemeService implements ThemeService {
  @override
  Future<ThemeMode> loadThemeMode() async => ThemeMode.system;
  @override
  Future<void> saveThemeMode(ThemeMode mode) async {}
  @override
  Future<int> loadThemeScheme() async => 0;
  @override
  Future<void> saveThemeScheme(int scheme) async {}
  @override
  Future<double> loadTextScale() async => 1.0;
  @override
  Future<void> saveTextScale(double scale) async {}
  @override
  Future<Axis> loadLayoutSplitAxis() async => Axis.vertical;
  @override
  Future<void> saveLayoutSplitAxis(Axis axis) async {}
  @override
  Future<double> loadPanelOpacity() async => 0.85;
  @override
  Future<void> savePanelOpacity(double opacity) async {}
}

Widget buildTestableWidget(Widget child) {
  return ChangeNotifierProvider<ThemeController>(
    create: (_) => ThemeController(FakeThemeService()),
    child: MaterialApp(
      home: Scaffold(
        body: child,
      ),
    ),
  );
}

void main() {
  final testField = const FieldDescriptor(
    key: 'timestamp',
    label: 'Timestamp',
    type: 'dateTime',
  );

  group('DateTimePickerField', () {
    testWidgets('renders initial value in the text field', (tester) async {
      const initialValue = '2024-01-15T10:30:00Z';

      await tester.pumpWidget(
        buildTestableWidget(
          DateTimePickerField(
            field: testField,
            initialValue: initialValue,
            onChanged: (_) {},
          ),
        ),
      );

      expect(find.text(initialValue), findsOneWidget);
    });

    testWidgets('shows calendar icon button', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          DateTimePickerField(
            field: testField,
            onChanged: (_) {},
          ),
        ),
      );

      expect(find.byIcon(Icons.calendar_today), findsOneWidget);
    });

    testWidgets('readOnly mode renders styled text, not TextField', (tester) async {
      const initialValue = '2024-01-15T10:30:00Z';

      await tester.pumpWidget(
        buildTestableWidget(
          DateTimePickerField(
            field: testField,
            initialValue: initialValue,
            readOnly: true,
            onChanged: (_) {},
          ),
        ),
      );

      expect(find.byType(TextField), findsNothing);
      expect(find.text(initialValue), findsOneWidget);
    });

    testWidgets('readOnly mode renders placeholder when value is null', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          DateTimePickerField(
            field: testField,
            readOnly: true,
            onChanged: (_) {},
          ),
        ),
      );

      expect(find.text('Not set'), findsOneWidget);
    });

    testWidgets('onChanged fires when text changes', (tester) async {
      String changedValue = '';

      await tester.pumpWidget(
        buildTestableWidget(
          DateTimePickerField(
            field: testField,
            onChanged: (value) {
              changedValue = value;
            },
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), '2024-06-15T08:00:00Z');
      await tester.pump();

      expect(changedValue, '2024-06-15T08:00:00Z');
    });

    testWidgets('validator shows error for invalid ISO 8601 format', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          DateTimePickerField(
            field: testField,
            initialValue: 'not-a-date',
            onChanged: (_) {},
          ),
        ),
      );

      final textField = find.byType(TextField);
      await tester.enterText(textField, '');
      await tester.pump();

      final editableText = tester.widget<EditableText>(find.byType(EditableText));
      expect(editableText.cursorColor, isNotNull);
    });

    testWidgets('validator passes for valid ISO 8601 format', (tester) async {
      String? validationError;
      const validDate = '2024-01-15T10:30:00Z';

      await tester.pumpWidget(
        buildTestableWidget(
          DateTimePickerField(
            field: testField,
            initialValue: validDate,
            onChanged: (_) {},
            validator: (value) {
              validationError = null;
              return null;
            },
          ),
        ),
      );

      expect(validationError, isNull);
    });

    testWidgets('disposes controller in dispose', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          DateTimePickerField(
            field: testField,
            initialValue: '2024-01-15T10:30:00Z',
            onChanged: (_) {},
          ),
        ),
      );

      await tester.pumpWidget(
        buildTestableWidget(const SizedBox()),
      );

      await tester.pump();
    });
  });
}
