import 'package:flutter/services.dart';

/// Abstract class for handling remote data sources.
///
/// A delegate defines how assets, cache, and remote data
/// should be loaded, saved, and listened to.
abstract class RemoteDelegate {
  const RemoteDelegate();

  /// Load JSON from asset bundle.
  Future<String> asset(String name, String path) {
    return rootBundle.loadString("assets/$name/$path");
  }

  /// Load from cache (e.g. SharedPreferences, SQLite).
  Future<Map?> cache(String name, String path);

  /// Save data into cache.
  Future<bool> save(String name, String path, Map? data);

  /// Fetch data from remote source (e.g. REST, Firebase).
  Future<Map?> fetch(String name, String path);

  /// Listen for live changes (e.g. Firebase streams).
  Stream<Map?> listen(String name, String path) {
    return Stream.error("Stream not implemented for $path");
  }

  /// Lifecycle hook: before loading starts.
  Future<void> loading() async {}

  /// Lifecycle hook: after all data loaded.
  Future<void> loaded() async {}

  /// Lifecycle hook: when data is ready for a path.
  Future<void> ready(String name, String path) async {}

  /// Lifecycle hook: when data has changed for a path.
  Future<void> changes(String name, String path) async {}
}
