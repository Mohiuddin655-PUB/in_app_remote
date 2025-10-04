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
