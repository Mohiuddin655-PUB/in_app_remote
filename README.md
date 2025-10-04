# Remote

The `Remote` class is a powerful data manager for Flutter apps, providing robust remote data
handling with UI integration. Its key features include:

## Features

### 1. Multi-Source Data Loading

- Loads data in the following order:
    1. Assets
    2. Cache
    3. Remote (delegate-based backend)
- Merges data from multiple sources seamlessly.

### 2. Live Updates via Subscriptions

- Supports real-time updates from remote sources.
- Uses `StreamSubscription` to listen for changes.
- Automatically updates cached and in-memory data on changes.

### 3. Delegate-Based Backend Abstraction

- Supports custom backend implementations through a `RemoteDelegate`.
- Delegate handles fetching, caching, asset loading, and change notifications.

### 4. UI Binding

- Extends `ChangeNotifier` for Flutter UI integration.
- Notifies listeners on data changes, allowing reactive UI updates.

### 5. Connection Management

- Handles connection state (`connected` / `disconnected`).
- Automatically subscribes/unsubscribes based on connection status.
- Supports resubscribing and canceling subscriptions dynamically.

### 6. Loading State Management

- Tracks loading state with `loading` flag.
- Provides methods for loading individual paths or all paths.
- Supports refresh and full reload operations.

### 7. Logging

- Optional logging via `_showLogs` flag.
- Logs all key actions like loading, subscriptions, and errors.

### 8. Error Handling

- Handles network timeouts gracefully.
- Catches and logs exceptions during fetch, save, and subscription operations.

### 9. Flexible Data Paths

- Manages multiple registered data paths (`_paths`).
- Allows selective loading, subscribing, and updating of paths.

### 10. Data Persistence

- Supports caching and saving of remote data via delegate.
- Combines asset, cache, and remote data automatically.

### 11. Callbacks

- Supports an optional `onReady` callback invoked after initialization.

### 12. Clean Disposal

- Cancels all subscriptions on `dispose`.
- Ensures no memory leaks for active streams.

---

## Example

```dart
import 'package:flutter/material.dart';
import 'package:in_app_remote/in_app_remote.dart';

class MyRemoteDelegate extends RemoteDelegate {
  @override
  Future<Map<String, dynamic>> fetch(String remoteName, String path) async {
    // Simulate network request
    await Future.delayed(Duration(seconds: 1));
    return {'message': 'Hello from remote for $path'};
  }

  @override
  Future<Map<String, dynamic>?> cache(String remoteName, String path) async {
    // Return cached data if any (optional)
    return null;
  }

  @override
  Future<String> asset(String remoteName, String path) async {
    // Load asset JSON (optional)
    return '{"message": "Hello from asset for $path"}';
  }

  @override
  Stream<Map<String, dynamic>?> listen(String remoteName, String path) {
    // Return a stream to simulate live updates
    return Stream.periodic(
      Duration(seconds: 5),
          (count) => {'message': 'Update #$count for $path'},
    );
  }

  @override
  Future<bool> save(String remoteName, String path, Map? data) async {
    // Save data to cache or local storage
    return true;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Create Remote instance
  final remote = Remote<MyRemoteDelegate>();

  // Initialize remote
  await remote.initialize(
    name: 'myRemote',
    connected: true,
    delegate: MyRemoteDelegate(),
    paths: {'greetings'},
    listening: true,
    showLogs: true,
    onReady: () => print('Remote is ready!'),
  );

  // Listen to changes
  remote.addListener(() {
    print('Data updated: ${remote.props}');
  });

  // Reload data manually
  await remote.reload();
}
```
---

**Summary:**  
The `Remote` class is designed for Flutter apps requiring a structured, reactive, and multi-source approach to remote data management, complete with caching, subscriptions, and UI integration.

