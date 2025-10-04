import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'delegate.dart';
import 'map_writer.dart';

/// A generic Remote data manager with support for:
/// - Loading from assets, cache, and remote (delegate-based) sources
/// - Live updates via subscriptions
/// - ChangeNotifier for reactive UI binding
/// - Symmetric and standard path handling
class Remote<T extends RemoteDelegate> extends ChangeNotifier {
  /// Constructor
  Remote();

  // ---------------------------------------------------------------------------
  // INITIAL PART
  // ---------------------------------------------------------------------------

  /// Merged properties of all loaded paths
  final Map _props = {};

  /// Registered data paths
  Set<String> _paths = {};

  /// Paths that require synchronous handling
  Set<String> _symmetricPaths = {};

  /// Name of the remote instance
  String _name = 'remote';

  /// Connection status
  bool _connected = false;

  /// Whether live subscriptions are active
  bool _listening = false;

  /// Whether logs are enabled
  bool _showLogs = false;

  /// Delegate for backend operations
  T? _delegate;

  /// Callback called after initialization
  VoidCallback? _callback;

  /// Get current remote name
  String get name => _name;

  /// Get merged properties
  Map get props => _props;

  /// Get registered paths
  Set<String> get paths => _paths;

  /// Check if remote is connected
  bool get connected => _connected;

  /// Check if logging is enabled
  bool get showLogs => _showLogs;

  /// Get current delegate
  T? get delegate => _delegate;

  /// Log message if logging is enabled
  void log(Object? msg) {
    if (!_showLogs) return;
    dev.log(msg.toString(), name: name.toUpperCase());
  }

  /// Initialize remote with optional delegate, paths, and callbacks
  Future<void> initialize({
    required String name,
    T? delegate,
    Set<String>? paths,
    Set<String>? symmetricPaths,
    bool connected = false,
    bool listening = true,
    bool showLogs = true,
    VoidCallback? onReady,
  }) async {
    _name = name;
    _paths = paths ?? {};
    _symmetricPaths = symmetricPaths ?? {};
    _showLogs = showLogs;
    _delegate = delegate;
    _connected = connected;
    _listening = listening;
    _callback = onReady;

    await _loads();
    if (_listening) await _subscribes();
  }

  // ---------------------------------------------------------------------------
  // CONNECTION PART
  // ---------------------------------------------------------------------------

  /// Re-subscribe to all paths
  Future<void> resubscribes() async {
    _listening = true;
    try {
      await _subscribes();
    } catch (msg) {
      log(msg);
    }
  }

  /// Cancel all active subscriptions
  Future<void> cancelSubscriptions() => _unsubscribes();

  /// Change connection status and reload data if necessary
  Future<void> changeConnection(bool value) async {
    if (_connected == value) return;
    _connected = value;
    if (!value) {
      return _unsubscribes();
    }
    await reload(notifiable: true);
    if (_listening) await resubscribes();
  }

  // ---------------------------------------------------------------------------
  // ASSET PART
  // ---------------------------------------------------------------------------

  /// Load data from asset JSON
  Future<Map?> _assets(String path) async {
    try {
      path = "$path.json";
      String data;
      if (_delegate != null) {
        data = await _delegate!.asset(name, path);
      } else {
        data = await rootBundle.loadString(path);
      }
      if (data.isEmpty) return null;
      final decoded = jsonDecode(data);
      if (decoded is! Map) return null;
      return decoded;
    } catch (msg) {
      log(msg);
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // CACHE PART
  // ---------------------------------------------------------------------------

  /// Load cached data for a path
  Future<Map?> _cached(String path) async {
    if (_delegate == null) return null;
    try {
      Map? cache = await _delegate!.cache(name, path);
      return cache;
    } catch (msg) {
      log(msg);
      return null;
    }
  }

  /// Save data to cache
  Future<bool> _save(String path, Map? data) async {
    if (_delegate == null) return false;
    try {
      final feedback = await _delegate!.save(name, path, data);
      return feedback;
    } catch (msg) {
      log(msg);
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // REMOTE PART
  // ---------------------------------------------------------------------------

  /// Fetch remote data using delegate
  Future<void> _fetch(String path) async {
    if (_delegate == null) return;
    try {
      if (!_connected) return;
      final data = await _delegate!.fetch(name, path);
      await _save(path, data);
    } on TimeoutException catch (_) {
      log("Timeout while connecting to $path. Please check your connection.");
    } catch (msg) {
      log(msg);
    }
  }

  // ---------------------------------------------------------------------------
  // LOADING PART
  // ---------------------------------------------------------------------------

  /// Loading state
  bool _loading = false;

  /// Whether currently loading
  bool get loading => _loading;

  /// Load data for a single path
  Future<void> _load(
    String path, {
    bool changed = false,
    bool reload = false,
  }) async {
    try {
      if (!changed || reload) await _fetch(path);

      Map data = {};
      final local = _props[path];
      if (local is Map) data = data.combine(local);

      if (!changed) {
        Map? asset = await _assets(path);
        if (asset != null) data = data.combine(asset);
      }

      Map? cache = await _cached(path);
      if (cache != null) data = data.combine(cache);

      if (data.isEmpty) {
        _props.remove(path);
        return;
      }

      _props[path] = data;

      if (changed) {
        notifyListeners();
        log("$path properties changed!");
      } else if (reload) {
        log("$path properties reloaded!");
      } else {
        log("$path properties loaded!");
      }

      if (_delegate != null) {
        changed ? _delegate!.changes(name, path) : _delegate!.ready(name, path);
      }
    } catch (msg) {
      log(msg);
    }
  }

  /// Load all paths
  Future<void> _loads() async {
    try {
      _loading = true;
      notifyListeners();
      if (_delegate != null) await _delegate!.loading();

      for (final path in paths) {
        if (_symmetricPaths.contains(path)) {
          await _load(path);
        } else {
          _load(path);
        }
      }

      _loading = false;
      notifyListeners();
      log("all symmetric properties loaded!");
      if (_delegate != null) await _delegate!.loaded();
      _callback?.call();
    } catch (msg) {
      _loading = false;
      notifyListeners();
      log(msg);
    }
  }

  /// Reload all paths, optionally showing loading indicator
  Future<void> reload({
    bool showLoading = false,
    bool notifiable = true,
  }) async {
    if (showLoading) {
      _loading = true;
      notifyListeners();
    }
    try {
      for (final path in paths) {
        if (_symmetricPaths.contains(path)) {
          await _load(path, reload: true);
        } else {
          _load(path, reload: true);
        }
      }
      if (showLoading) _loading = false;
      if (notifiable || showLoading) notifyListeners();
      log("all symmetric properties reloaded!");
      if (_delegate != null) await _delegate!.loaded();
      _callback?.call();
    } catch (msg) {
      log(msg);
    }
  }

  // ---------------------------------------------------------------------------
  // SUBSCRIPTIONS PART
  // ---------------------------------------------------------------------------

  /// Active subscriptions for live updates
  final Map<String, StreamSubscription?> _subscriptions = {};

  /// Subscribe to a single path
  Future<void> _subscribe(String path) async {
    if (_delegate == null) return;
    try {
      await _subscriptions[path]?.cancel();
      _subscriptions.remove(path);
      if (!_connected) return;

      _subscriptions[path] = _delegate!.listen(name, path).listen((data) async {
        if (data == _props[path]) return;
        final kept = await _save(path, data);
        if (!kept) return;
        await _load(path, changed: true);
      });
    } on TimeoutException catch (_) {
      log("Timeout while connecting to $path. Please check your connection.");
    } catch (msg) {
      log(msg);
    }
  }

  /// Subscribe to multiple paths
  Future<void> _subscribes([Set<String>? paths]) async {
    if (paths == null || paths.isEmpty) await _unsubscribes();
    for (var path in (paths ?? _paths)) {
      if (_symmetricPaths.contains(path)) {
        await _subscribe(path);
      } else {
        _subscribe(path);
      }
      log("stream subscription[$path] created!");
    }
  }

  /// Unsubscribe from all paths
  Future<void> _unsubscribes() async {
    try {
      for (var subscription in _subscriptions.entries) {
        try {
          await subscription.value?.cancel();
          log("stream subscription[${subscription.key}] canceled!");
        } catch (msg) {
          log(msg);
        }
      }
      _subscriptions.clear();
    } catch (msg) {
      log(msg);
    }
  }

  @override
  void dispose() {
    _unsubscribes().whenComplete(() {
      if (_listening) log("subscriptions canceled!");
    });
    super.dispose();
  }
}
