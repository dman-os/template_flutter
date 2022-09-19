import 'dart:async';

import 'package:api_client/api_client.dart';
import 'package:template_flutter/providers/cache/cache.dart';
import 'package:template_flutter/repositories/repositories.dart';

class ApiUserRepository {
  final Cache<String, User> cache;
  final ApiClient client;
  final StreamController<Set<String>> _changedItemsController =
      StreamController.broadcast();

  @override
  Stream<Set<String>> get changedItems => _changedItemsController.stream;

  ApiUserRepository(this.cache, this.client);

  @override
  Future<User> create(CreateUserRequest input) async {
    final item = await client.createUser(input);
    // await cache.setItem(item.id, item);
    // _changedItemsController.add({item.id});
    return item;
  }

  @override
  Future<User?> get(String id, String authToken) async {
    var item = await cache.getItem(id);
    if (item != null) return item;
    try {
      item = await client.getUser(id, authToken);
      await cache.setItem(id, item);
      return item;
    } on EndpointError catch (err) {
      if (err.type == "NotFound") return null;
      rethrow;
    }
  }

  @override
  Future<Map<String, User>> list() => cache.getItems();

  @override
  Future<void> remove(
    String id,
    String username,
    String authToken, [
    bool bypassChangedItemNotification = false,
  ]) {
    // TODO: implement remove
    throw UnimplementedError();
  }

  @override
  Future<User> update(String id, input, String username, String authToken) {
    // TODO: implement update
    throw UnimplementedError();
  }

  @override
  updateFromDiff(User update, User old) {
    // TODO: implement updateFromDiff
    throw UnimplementedError();
  }

  @override
  Future<void> refreshCache(Map<String, User> items) async {
    await cache.clear();
    Set<String> ids = {};
    for (final p in items.entries) {
      ids.add(p.key);
      await cache.setItem(p.key, p.value);
    }
    _changedItemsController.add(ids);
  }
}
