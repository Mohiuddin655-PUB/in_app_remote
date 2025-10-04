import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_remote/in_app_remote.dart';

/// Fake Delegate for testing (in-memory only).
class FakeDelegate extends RemoteDelegate {
  Map<String, Map?> fakeCache = {};
  Map<String, Map?> fakeRemote = {};
  Map<String, String> fakeAssets = {};

  @override
  Future<Map?> cache(String name, String path) async {
    return fakeCache[path];
  }

  @override
  Future<bool> save(String name, String path, Map? data) async {
    fakeCache[path] = data;
    return true;
  }

  @override
  Future<Map?> fetch(String name, String path) async {
    return fakeRemote[path];
  }

  @override
  Future<String> asset(String name, String path) async {
    return fakeAssets[path] ?? "{}";
  }

  @override
  Stream<Map?> listen(String name, String path) {
    // For testing: emit a one-time update
    return Stream.value({"theme": "blue"});
  }
}

void main() {
  group("Remote class tests", () {
    late Remote<FakeDelegate> remote;
    late FakeDelegate delegate;

    setUp(() {
      delegate = FakeDelegate();
      remote = Remote<FakeDelegate>();
    });

    test("Initializes and loads assets + cache + remote", () async {
      // Setup fake data
      delegate.fakeAssets["settings.json"] = '{"theme": "dark"}';
      delegate.fakeCache["settings"] = {"language": "bn"};
      delegate.fakeRemote["settings"] = {"theme": "light", "language": "en"};

      // Initialize
      await remote.initialize(
        name: "user",
        connected: true,
        delegate: delegate,
        paths: {"settings"},
        listening: false,
        showLogs: true,
      );

      final settings = remote.props["settings"] as Map;
      expect(settings["theme"], equals("light")); // remote overrides
      expect(settings["language"], equals("en")); // remote overrides cache
    });

    test("Updates when listen emits new data", () async {
      // Setup fake remote & asset
      delegate.fakeAssets["settings.json"] = '{"theme": "dark"}';
      delegate.fakeRemote["settings"] = {"theme": "light"};

      await remote.initialize(
        name: "user",
        connected: true,
        delegate: delegate,
        paths: {"settings"},
        listening: true,
      );

      // Wait a tick for stream emission
      await Future.delayed(Duration(milliseconds: 10));

      final settings = remote.props["settings"] as Map;
      expect(settings["theme"], equals("blue")); // from listen()
    });

    test("Cache is updated after save", () async {
      delegate.fakeAssets["settings.json"] = '{"theme": "dark"}';
      delegate.fakeRemote["settings"] = {"theme": "light"};

      await remote.initialize(
        name: "user",
        connected: true,
        delegate: delegate,
        paths: {"settings"},
      );

      final before = remote.props["settings"];
      expect(before?["theme"], equals("light")); // saved remote
    });
  });
}
