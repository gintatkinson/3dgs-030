import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:app_flutter/domain/type_descriptor.dart';
import 'package:app_flutter/features/properties/property_grid.dart';
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

void main() {
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

  Finder findTextFieldByLabel(String labelText) {
    final Finder columnFinder = find.byWidgetPredicate((Widget widget) {
      if (widget is Column) {
        final List<Widget> children = widget.children;
        if (children.isNotEmpty && children.first is Text) {
          final Text textWidget = children.first as Text;
          if (textWidget.data == labelText) {
            return true;
          }
        }
      }
      return false;
    });
    return find.descendant(
      of: columnFinder,
      matching: find.byType(TextField),
    );
  }

  Finder findDropdownByLabel(String labelText) {
    final Finder columnFinder = find.byWidgetPredicate((Widget widget) {
      if (widget is Column) {
        final List<Widget> children = widget.children;
        if (children.isNotEmpty && children.first is Text) {
          final Text textWidget = children.first as Text;
          if (textWidget.data == labelText) {
            return true;
          }
        }
      }
      return false;
    });
    return find.descendant(
      of: columnFinder,
      matching: find.byType(DropdownButtonFormField<String>),
    );
  }

  testWidgets('Highlights first section when activeView matches section label',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      buildTestableWidget(
        PropertyGrid(
          activeView: 'Primary',
          fields: const [
            FieldDescriptor(
                key: 'f1',
                label: 'Field 1',
                type: 'string',
                sectionLabel: 'Primary',
                sectionOrder: 0),
            FieldDescriptor(
                key: 'f2',
                label: 'Field 2',
                type: 'string',
                sectionLabel: 'Secondary',
                sectionOrder: 0),
          ],
        ),
      ),
    );

    expect(find.text('Active Reference'), findsOneWidget);

    final List<Opacity> opacities =
        tester.widgetList<Opacity>(find.byType(Opacity)).toList();
    expect(opacities[0].opacity, 1.0);
    expect(opacities[1].opacity, 0.65);
  });

  testWidgets('Highlights first section when activeView is root',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      buildTestableWidget(
        PropertyGrid(
          activeView: 'root',
          fields: const [
            FieldDescriptor(
                key: 'f1',
                label: 'Field 1',
                type: 'string',
                sectionLabel: 'Alpha',
                sectionOrder: 0),
            FieldDescriptor(
                key: 'f2',
                label: 'Field 2',
                type: 'string',
                sectionLabel: 'Beta',
                sectionOrder: 0),
          ],
        ),
      ),
    );

    expect(find.text('Active Reference'), findsOneWidget);

    final List<Opacity> opacities =
        tester.widgetList<Opacity>(find.byType(Opacity)).toList();
    expect(opacities[0].opacity, 1.0);
    expect(opacities[1].opacity, 0.65);
  });

  testWidgets('Performs pattern validation on blur',
      (WidgetTester tester) async {
    Map<String, dynamic>? savedData;

    await tester.pumpWidget(
      buildTestableWidget(
        PropertyGrid(
          activeView: 'root',
          fields: const [
            FieldDescriptor(
                key: 'code',
                label: 'Code',
                type: 'string',
                pattern: r'^[A-Z]{2}$',
                inputFormatters: ['uppercase', 'maxLength:2']),
          ],
          onSave: (data) {
            savedData = data;
          },
        ),
      ),
    );

    final Finder codeField = findTextFieldByLabel('Code');
    expect(codeField, findsOneWidget);

    final TextField textField = tester.widget<TextField>(codeField);
    textField.focusNode!.requestFocus();
    await tester.pumpAndSettle();
    await tester.enterText(codeField, 'U1');
    await tester.pumpAndSettle();

    expect(savedData, isNull);

    textField.focusNode!.unfocus();
    await tester.pumpAndSettle();

    expect(find.text('Invalid format'), findsOneWidget);
    expect(savedData, isNull);

    textField.focusNode!.requestFocus();
    await tester.pumpAndSettle();
    await tester.enterText(codeField, 'FI');
    await tester.pumpAndSettle();

    textField.focusNode!.unfocus();
    await tester.pumpAndSettle();

    expect(find.text('Invalid format'), findsNothing);
    expect(savedData, isNotNull);
    expect(savedData!['code'], 'FI');

    final String jsonString =
        const JsonEncoder.withIndent('  ').convert(savedData);
    expect(find.text(jsonString), findsOneWidget);
  });

  testWidgets('Performs numeric min/max validation on blur',
      (WidgetTester tester) async {
    Map<String, dynamic>? savedData;

    await tester.pumpWidget(
      buildTestableWidget(
        PropertyGrid(
          activeView: 'root',
          fields: const [
            FieldDescriptor(
                key: 'value',
                label: 'Value',
                type: 'int',
                minValue: 0,
                maxValue: 100),
          ],
          onSave: (data) {
            savedData = data;
          },
        ),
      ),
    );

    final Finder valueField = findTextFieldByLabel('Value');
    expect(valueField, findsOneWidget);

    final TextField textField = tester.widget<TextField>(valueField);
    textField.focusNode!.requestFocus();
    await tester.pumpAndSettle();
    await tester.enterText(valueField, '-1');
    await tester.pumpAndSettle();

    textField.focusNode!.unfocus();
    await tester.pumpAndSettle();

    expect(find.text('Value cannot be less than 0'), findsOneWidget);
    expect(savedData, isNull);

    textField.focusNode!.requestFocus();
    await tester.pumpAndSettle();
    await tester.enterText(valueField, '50');
    await tester.pumpAndSettle();

    textField.focusNode!.unfocus();
    await tester.pumpAndSettle();

    expect(find.text('Value cannot be less than 0'), findsNothing);
    expect(savedData!['value'], 50);

    textField.focusNode!.requestFocus();
    await tester.pumpAndSettle();
    await tester.enterText(valueField, '101');
    await tester.pumpAndSettle();

    textField.focusNode!.unfocus();
    await tester.pumpAndSettle();

    expect(find.text('Value cannot be greater than 100'), findsOneWidget);

    textField.focusNode!.requestFocus();
    await tester.pumpAndSettle();
    await tester.enterText(valueField, '100');
    await tester.pumpAndSettle();

    textField.focusNode!.unfocus();
    await tester.pumpAndSettle();

    expect(find.text('Value cannot be greater than 100'), findsNothing);
    expect(savedData!['value'], 100);
  });

  testWidgets('Enum dropdown renders and commits on change',
      (WidgetTester tester) async {
    Map<String, dynamic>? savedData;

    await tester.pumpWidget(
      buildTestableWidget(
        PropertyGrid(
          activeView: 'root',
          fields: const [
            FieldDescriptor(
                key: 'type',
                label: 'Type',
                type: 'enum',
                enumOptions: ['a', 'b', 'c'],
                enumDisplayNames: ['Option A', 'Option B', 'Option C']),
          ],
          onSave: (data) {
            savedData = data;
          },
        ),
      ),
    );

    final Finder dropdownFinder = findDropdownByLabel('Type');
    expect(dropdownFinder, findsOneWidget);

    await tester.tap(find.text('Option A'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Option C').last);
    await tester.pumpAndSettle();

    expect(savedData, isNotNull);
    expect(savedData!['type'], 'c');
  });

  testWidgets('dateTime field renders DateTimePickerField',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      buildTestableWidget(
        PropertyGrid(
          activeView: 'root',
          fields: const [
            FieldDescriptor(
              key: 'timestamp',
              label: 'Timestamp',
              type: 'dateTime',
              sectionLabel: 'Primary',
            ),
          ],
        ),
      ),
    );

    expect(find.byType(DateTimePickerField), findsOneWidget);
  });

  testWidgets('readOnly field renders as styled text, not editable',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      buildTestableWidget(
        PropertyGrid(
          activeView: 'root',
          fields: const [
            FieldDescriptor(
              key: 'f1',
              label: 'Read Only Field',
              type: 'string',
              readOnly: true,
              sectionLabel: 'Primary',
            ),
          ],
          initialValues: const {'f1': 'readonly value'},
        ),
      ),
    );

    expect(find.text('Read Only Field'), findsOneWidget);
    expect(find.text('readonly value'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(find.byType(DropdownButtonFormField<String>), findsNothing);
  });

  testWidgets('empty fields list shows placeholder text',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      buildTestableWidget(
        PropertyGrid(
          activeView: 'root',
          fields: const [],
        ),
      ),
    );

    expect(find.text('No location data recorded.'), findsOneWidget);
  });

  testWidgets('invalid dateTime shows error border',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      buildTestableWidget(
        PropertyGrid(
          activeView: 'root',
          fields: const [
            FieldDescriptor(
              key: 'timestamp',
              label: 'Timestamp',
              type: 'dateTime',
              sectionLabel: 'Primary',
            ),
          ],
        ),
      ),
    );

    final Finder pickerFinder = find.byType(DateTimePickerField);
    expect(pickerFinder, findsOneWidget);

    final Finder textField = find.descendant(
      of: pickerFinder,
      matching: find.byType(TextField),
    );
    expect(textField, findsOneWidget);

    await tester.enterText(textField, 'invalid-date');
    await tester.pumpAndSettle();

    expect(
      find.text('Must be a valid ISO 8601 date-time (e.g. 2024-01-15T10:30:00Z)'),
      findsOneWidget,
    );
  });

  testWidgets('field with featureFlag renders when flag is enabled',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      buildTestableWidget(
        PropertyGrid(
          activeView: 'root',
          enabledFeatures: const {'alternate-systems'},
          fields: const [
            FieldDescriptor(
              key: 'alt',
              label: 'Alternate Field',
              type: 'string',
              featureFlag: 'alternate-systems',
            ),
          ],
        ),
      ),
    );

    expect(find.text('Alternate Field'), findsOneWidget);
  });

  testWidgets('field with featureFlag is hidden when flag is not enabled',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      buildTestableWidget(
        PropertyGrid(
          activeView: 'root',
          enabledFeatures: const {},
          fields: const [
            FieldDescriptor(
              key: 'alt',
              label: 'Alternate Field',
              type: 'string',
              featureFlag: 'alternate-systems',
            ),
          ],
        ),
      ),
    );

    expect(find.text('Alternate Field'), findsNothing);
  });

  testWidgets('field without featureFlag always renders',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      buildTestableWidget(
        PropertyGrid(
          activeView: 'root',
          enabledFeatures: const {},
          fields: const [
            FieldDescriptor(
              key: 'normal',
              label: 'Normal Field',
              type: 'string',
            ),
          ],
        ),
      ),
    );

    expect(find.text('Normal Field'), findsOneWidget);
  });
}
