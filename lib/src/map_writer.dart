/// Utility class for merging maps deeply.
class MapWriter {
  const MapWriter._();

  /// Combines two maps recursively.
  ///
  /// - If both [a] and [b] have the same key and values are maps, they are merged.
  /// - Otherwise, [b]'s value overrides [a]'s value.
  static Map _combine(Map a, Map b) {
    final result = {};
    for (final key in {...a.keys, ...b.keys}) {
      final aVal = a[key];
      final bVal = b[key];
      if (aVal is Map && bVal is Map) {
        result[key] = combine(Map.from(aVal), Map.from(bVal));
      } else if (b.containsKey(key)) {
        result[key] = bVal;
      } else {
        result[key] = aVal;
      }
    }
    return result;
  }

  /// Public API to combine [a] with [b].
  ///
  /// Returns [a] if [b] is `null` or empty.
  static Map combine(Map a, Map? b) {
    if (b == null || b.isEmpty) return a;
    return _combine(a, b);
  }
}

/// Extension to use [MapWriter.combine] as a method on Map.
extension MapWriterHelper on Map {
  /// Combines this map with [other].
  Map combine(Map? other) => MapWriter.combine(this, other);
}
