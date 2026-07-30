/// Describes a single object type discovered at runtime from the connected
/// [DataSource].
///
/// The client uses this to render tree nodes, property forms, table columns,
/// and topology graphs. The descriptor is domain-agnostic — it works for
/// telco, air-traffic, industrial IoT, or any other domain without code
/// changes. The data source drives what appears in the UI.
///
/// One [TypeDescriptor] instance exists per object type, not per instance.
/// All fields are immutable and must be provided at construction. An empty
/// [TypeDescriptor] (no fields, no relations) is valid and renders as a
/// bare label in the tree — it does not throw.
class TypeDescriptor {
  /// Internal identifier matching the data source, e.g. "device".
  ///
  /// Must be unique within the data source. Used as the key for lookups
  /// via [DataSource.typeFor]. Cannot be empty.
  final String typeName;

  /// Human-readable label for UI display, e.g. "Device".
  ///
  /// Displayed in tree nodes, tab headers, and dropdown selectors.
  /// Falls back to [typeName] if left null by the caller (handled by
  /// the widget layer, not enforced here).
  final String displayName;

  /// Material icon name string, e.g. "developer_board".
  ///
  /// Resolved to [IconData] by [IconMapper.resolve]. If the name is
  /// not in the icon map, [IconMapper] returns a fallback icon —
  /// the tree always shows something, never a blank.
  final String iconName;

  /// All editable fields/attributes of this type.
  ///
  /// Each [FieldDescriptor] specifies the field's type, label,
  /// validation constraints, and UI grouping. When this list changes
  /// (e.g. switching to a different object type), the grid rebuilds
  /// to show the new fields. An empty list renders a "No fields"
  /// message — it does not throw.
  final List<FieldDescriptor> fields;

  /// Child object types for the tree hierarchy.
  ///
  /// Each entry describes a directed parent→child relationship.
  /// An empty list makes this type a leaf node in the tree.
  /// Child types appear as expandable sub-nodes in the sidebar.
  final List<TypeRelationDescriptor> childTypes;

  /// Object types related to this one (events, alerts, logs, etc.).
  ///
  /// These appear as tabs in the detail pane but NOT as tree children.
  /// Related types are sibling or peer entities that share context
  /// with this type without owning it structurally.
  final List<TypeRelationDescriptor> relatedTypes;

  /// Parent object types for reverse tree navigation.
  ///
  /// Used for "go to parent" actions and breadcrumb trails.
  /// An empty list means this type is a root node with no parent.
  final List<TypeRelationDescriptor> parentTypes;

  const TypeDescriptor({
    required this.typeName,
    required this.displayName,
    required this.iconName,
    required this.fields,
    required this.childTypes,
    required this.relatedTypes,
    required this.parentTypes,
  });
}

/// Describes one field/attribute of a [TypeDescriptor].
///
/// Each field tells the UI how to render an editor control (text field,
/// dropdown, numeric spinner, date picker) and how to validate the input.
/// Fields are discovered at runtime — no compile-time schema is required.
/// An empty [FieldDescriptor] is invalid; at minimum [key], [label], and
/// [type] must be provided.
class FieldDescriptor {
  static final _compiledPatterns = <String, RegExp>{};

  /// Returns a cached compiled [RegExp] for [pattern], or null if [pattern]
  /// is null or empty. Reuses previously compiled instances to avoid GC churn.
  RegExp? get compiledPattern {
    if (pattern == null || pattern!.isEmpty) return null;
    return _compiledPatterns.putIfAbsent(pattern!, () => RegExp(pattern!));
  }
  /// Unique key within the type, e.g. "maxVoltage".
  ///
  /// Used as the map key when reading/writing property data.
  /// Must be non-empty and unique within the parent [TypeDescriptor.fields].
  final String key;

  /// Human-readable label, e.g. "Max Voltage (V)".
  ///
  /// Displayed above or beside the editor control in the property form.
  final String label;

  /// Data type: "string", "int", "double", "enum", "date".
  ///
  /// Determines which editor widget to render and which validation rules
  /// to apply. Unknown types fall back to a plain text field. The value
  /// is case-sensitive.
  final String type;

  /// UI section grouping label, e.g. "Alternate Structural Grid Frame".
  ///
  /// If null, the field belongs to a default "Other" section rendered
  /// at the bottom. Section labels match against the UI's section header
  /// map; unknown sections are displayed as-is.
  final String? sectionLabel;

  /// Display order within the section (lower = first).
  ///
  /// Fields with equal [sectionOrder] appear in insertion order.
  /// Negative values are allowed and sort before zero.
  final int sectionOrder;

  /// Whether this field must have a non-null value.
  ///
  /// When true, the UI marks the field as required with an indicator and
  /// prevents saving if the value is null or empty. Validation is the
  /// caller's responsibility — this field is a hint, not a constraint.
  final bool required;

  /// Whether this field is read-only.
  ///
  /// When true, the UI renders the field as non-editable. Defaults to
  /// false. The data source may mark certain fields (e.g. server-assigned
  /// identifiers, timestamps) as read-only to prevent user modification.
  final bool readOnly;

  /// Minimum numeric value for int/double types.
  ///
  /// Applied as an inclusive lower bound during validation.
  /// Ignored for non-numeric types. Null means no minimum.
  final num? minValue;

  /// Maximum numeric value for int/double types.
  ///
  /// Applied as an inclusive upper bound during validation.
  /// Ignored for non-numeric types. Null means no maximum.
  final num? maxValue;

  /// Regex pattern for string validation.
  ///
  /// Applied via [RegExp.hasMatch]. If [pattern] is null or empty
  /// the string passes without check. The pattern is not anchored
  /// by default — callers should wrap in ^...$ if a full match is needed.
  final String? pattern;

  /// Allowed enum values for enum types.
  ///
  /// Populates a dropdown with these options. Must be non-empty when
  /// [type] is "enum". Null or empty renders a text field instead.
  final List<String>? enumOptions;

  /// Display names for each enum option (same index as [enumOptions]).
  ///
  /// If null or shorter than [enumOptions], the option value itself is
  /// used as the display label. Useful for showing "Active States"
  /// when the stored value is "active".
  final List<String>? enumDisplayNames;

  /// Default value when creating a new instance.
  ///
  /// Populated into the form when adding a new node of this type.
  /// Can be any JSON-serialisable type. Null means no default.
  final dynamic defaultValue;

  /// Input formatter names, e.g. ["uppercase", "maxLength:2"].
  ///
  /// Applied by the widget layer to constrain user input.
  /// Unknown formatter names are silently ignored.
  final List<String>? inputFormatters;

  /// Feature flag name for conditional rendering (YANG `if-feature`).
  ///
  /// When non-null, this field is only shown if the flag is present in
  /// [PropertyGrid.enabledFeatures]. When null the field always renders.
  final String? featureFlag;

  /// Autocomplete suggestions for this field.
  ///
  /// When non-null and non-empty, and the field type is 'string', the UI
  /// renders an [Autocomplete] widget instead of a plain text field.
  /// The user can still type free-text values not in this list.
  final List<String>? suggestions;

  const FieldDescriptor({
    required this.key,
    required this.label,
    required this.type,
    this.sectionLabel,
    this.sectionOrder = 0,
    this.required = false,
    this.readOnly = false,
    this.minValue,
    this.maxValue,
    this.pattern,
    this.enumOptions,
    this.enumDisplayNames,
    this.defaultValue,
    this.inputFormatters,
    this.featureFlag,
    this.suggestions,
  });

  factory FieldDescriptor.fromMap(Map<String, dynamic> map) {
    var type = map['type']?.toString() ?? 'string';
    if (type == 'datetime') {
      type = 'dateTime';
    }

    return FieldDescriptor(
      key: map['key']?.toString() ?? '',
      label: map['label']?.toString() ?? '',
      type: type,
      sectionLabel: map['section_label']?.toString(),
      sectionOrder: map['section_order'] is int
          ? map['section_order'] as int
          : (int.tryParse(map['section_order']?.toString() ?? '') ?? 0),
      required: map['required'] == true,
      readOnly: map['readOnly'] == true || map['read_only'] == true,
      minValue: map['min_value'] is num ? map['min_value'] as num : null,
      maxValue: map['max_value'] is num ? map['max_value'] as num : null,
      pattern: map['pattern']?.toString(),
      enumOptions: map['enum_options'] is List
          ? List<String>.from(map['enum_options'] as List)
          : null,
      enumDisplayNames: map['enum_display_names'] is List
          ? List<String>.from(map['enum_display_names'] as List)
          : null,
      defaultValue: map['default_value'],
      inputFormatters: map['input_formatters'] is List
          ? List<String>.from(map['input_formatters'] as List)
          : null,
      featureFlag: map['feature_flag']?.toString(),
      suggestions: map['suggestions'] is List
          ? List<String>.from(map['suggestions'] as List)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    final result = <String, dynamic>{
      'key': key,
      'label': label,
      'type': type,
      'section_order': sectionOrder,
      'required': required,
      'read_only': readOnly,
    };
    if (sectionLabel != null) result['section_label'] = sectionLabel;
    if (minValue != null) result['min_value'] = minValue;
    if (maxValue != null) result['max_value'] = maxValue;
    if (pattern != null) result['pattern'] = pattern;
    if (enumOptions != null) result['enum_options'] = enumOptions;
    if (enumDisplayNames != null) result['enum_display_names'] = enumDisplayNames;
    if (defaultValue != null) result['default_value'] = defaultValue;
    if (inputFormatters != null) result['input_formatters'] = inputFormatters;
    if (featureFlag != null) result['feature_flag'] = featureFlag;
    if (suggestions != null) result['suggestions'] = suggestions;
    return result;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FieldDescriptor &&
        other.key == key &&
        other.label == label &&
        other.type == type &&
        other.sectionLabel == sectionLabel &&
        other.sectionOrder == sectionOrder &&
        other.required == required &&
        other.readOnly == readOnly &&
        other.minValue == minValue &&
        other.maxValue == maxValue &&
        other.pattern == pattern &&
        _listEquals(other.enumOptions, enumOptions) &&
        _listEquals(other.enumDisplayNames, enumDisplayNames) &&
        other.defaultValue == defaultValue &&
        _listEquals(other.inputFormatters, inputFormatters) &&
        other.featureFlag == featureFlag &&
        _listEquals(other.suggestions, suggestions);
  }

  @override
  int get hashCode => Object.hash(
        key,
        label,
        type,
        sectionLabel,
        sectionOrder,
        required,
        readOnly,
        minValue,
        maxValue,
        pattern,
        enumOptions,
        enumDisplayNames,
        defaultValue,
        inputFormatters,
        featureFlag,
        Object.hashAll(suggestions ?? []),
      );
}

bool _listEquals<T>(List<T>? a, List<T>? b) {
  if (identical(a, b)) return true;
  if (a == null || b == null) return a == b;
  if (a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// Describes a directed relationship between two [TypeDescriptor]s.
///
/// Used by the tree view, tab bar, and navigation breadcrumbs to
/// determine which types are connected and how to label the connection.
/// Relationships are directional: parent→child defines hierarchy,
/// while related→current defines peer associations.
class TypeRelationDescriptor {
  /// Semantic name of the relation, e.g. "contains", "belongs_to".
  ///
  /// Determines the arrow label in topology views and the tooltip in
  /// tree nodes. An empty string renders a generic "Related" label.
  final String relationName;

  /// The [TypeDescriptor.typeName] of the related (target) type.
  ///
  /// Must match a [TypeDescriptor.typeName] returned by the data source.
  /// A mismatch results in a dangling reference — the UI skips it
  /// gracefully with a warning log.
  final String childTypeName;

  /// Human-readable plural label for UI tab headers, e.g. "Sensors".
  ///
  /// Displayed as the tab title and as a section header in the
  /// related-items panel. Falls back to [childTypeName] if empty.
  final String childLabel;

  const TypeRelationDescriptor({
    required this.relationName,
    required this.childTypeName,
    required this.childLabel,
  });
}
