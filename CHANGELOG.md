## 1.0.0

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

