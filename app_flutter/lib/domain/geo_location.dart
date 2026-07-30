/// Container for geo-location temporal attributes per ietf-geo-location YANG
/// grouping (RFC 9179).
class GeoLocation {
  final String? timestamp;
  final String? validUntil;

  const GeoLocation({this.timestamp, this.validUntil});

  factory GeoLocation.fromMap(Map<String, dynamic> map) {
    final nested = map['ietf-geo-location:geo-location'];
    final source = (nested is Map<String, dynamic>) ? nested : map;

    return GeoLocation(
      timestamp: source['timestamp']?.toString(),
      validUntil: source['valid-until']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    final result = <String, dynamic>{};
    if (timestamp != null) result['timestamp'] = timestamp;
    if (validUntil != null) result['valid-until'] = validUntil;
    return result;
  }

  @override
  String toString() =>
      'GeoLocation(timestamp: $timestamp, validUntil: $validUntil)';
}
