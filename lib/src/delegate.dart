import 'package:flutter/services.dart';

abstract class RemoteDelegate {
  const RemoteDelegate();

  Future<String> asset(String name, String path) {
    return rootBundle.loadString("assets/$name/$path");
  }

  Future<Map?> cache(String name, String path);

  Future<bool> save(String name, String path, Map? data);

  Future<Map?> fetch(String name, String path);

  Stream<Map?> listen(String name, String path) {
    return Stream.error("Stream not implemented for $path");
  }

  Future<void> initializing() async {}

  Future<void> initialized() async {}

  Future<void> ready(String name, String path) async {}

  Future<void> changes(String name, String path) async {}
}
