class ReferenceFrame {
  final String? alternateSystem;
  final String? _astronomicalBody;

  String? get astronomicalBody => _astronomicalBody ?? 'earth';

  const ReferenceFrame({
    this.alternateSystem,
    String? astronomicalBody,
  }) : _astronomicalBody = astronomicalBody;

  factory ReferenceFrame.fromMap(Map<String, dynamic> map) {
    return ReferenceFrame(
      alternateSystem: map['alternate_system']?.toString(),
      astronomicalBody: _normalizeBody(map['astronomical_body']?.toString()),
    );
  }

  static String? _normalizeBody(String? value) {
    if (value == null) return null;
    return value.toLowerCase();
  }

  Map<String, dynamic> toMap() {
    final result = <String, dynamic>{};
    if (alternateSystem != null) result['alternate_system'] = alternateSystem;
    if (_astronomicalBody != null) {
      result['astronomical_body'] = _astronomicalBody;
    }
    return result;
  }

  ReferenceFrame copyWith({String? alternateSystem, String? astronomicalBody}) {
    return ReferenceFrame(
      alternateSystem: alternateSystem ?? this.alternateSystem,
      astronomicalBody: astronomicalBody ?? _astronomicalBody,
    );
  }

  @override
  String toString() =>
      'ReferenceFrame(alternateSystem: $alternateSystem, astronomicalBody: $astronomicalBody)';
}
