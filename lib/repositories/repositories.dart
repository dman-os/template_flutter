export 'user.dart';
export 'auth.dart';

// import 'package:template_flutter/providers/cache/cache.dart';
// import 'package:tuple/tuple.dart';

/* abstract class ApiRepository<Identifier, Item, CreateInput, UpdateInput> {
  Future<Item?> get(Identifier id, String userId, String authToken);
  Future<Map<Identifier, Item>> list();
  Future<Item> create(CreateInput input, String userId, String authToken);
  Future<Item> update(
    Identifier id,
    UpdateInput input,
    String userId,
    String authToken,
  );
  Future<void> remove(
    Identifier id,
    String userId,
    String authToken, [
    bool bypassChangedItemNotification = false,
  ]);

  Stream<Set<Identifier>> get changedItems;

  // UpdateInput updateFromDiff(Item update, Item old);
  // CreateInput createFromItem(Item item);
  // Future<void> refreshCache(Map<Identifier, Item> items);
} */

/* abstract class ApiRepositoryWrapper<Identifier, Item, CreateInput, UpdateInput>
    extends ApiRepository<Identifier, Item, CreateInput, UpdateInput> {
  final ApiRepository<Identifier, Item, CreateInput, UpdateInput> repo;

  ApiRepositoryWrapper(this.repo);

  @override
  Stream<Set<Identifier>> get changedItems => repo.changedItems;

  @override
  CreateInput createFromItem(Item item) => repo.createFromItem(item);

  @override
  Future<Item> create(
    CreateInput input,
    String username,
    String authToken,
  ) =>
      repo.create(input, username, authToken);

  @override
  Future<Item?> get(
    Identifier id,
    String username,
    String authToken,
  ) =>
      repo.get(id, username, authToken);

  @override
  Future<Map<Identifier, Item>> list() => repo.list();

  @override
  Future<void> refreshCache(Map<Identifier, Item> items) {
    return repo.refreshCache(items);
  }

  @override
  Future<void> remove(Identifier id, String username, String authToken,
          [bool bypassChangedItemNotification = false]) =>
      repo.remove(id, username, authToken, bypassChangedItemNotification);

  @override
  Future<Item> update(
    Identifier id,
    UpdateInput input,
    String username,
    String authToken,
  ) =>
      repo.update(id, input, username, authToken);

  @override
  UpdateInput updateFromDiff(Item update, Item old) =>
      repo.updateFromDiff(update, old);
}
 */
/* mixin OfflineCapableRepository<Identifier, Item, CreateInput, UpdateInput>
    on ApiRepository<Identifier, Item, CreateInput, UpdateInput> {

  Future<Item> getItemOffline(Identifsier id);
  Future<Item> createItemOffline(Identifier id, Item input);
  Future<Item> updateItemOffline(Identifier id, Item update);
  Future<void> removeItemOffline(Identifier id);
} */

/* abstract class OfflineRepository<Identifier, Item, CreateInput, UpdateInput> {
  final Cache<Identifier, Item> cache;
  final Cache<Identifier, Item> serverVersionCache;
  final RemovedItemsCache<Identifier> removedItemsCache;
  /* OfflineRepository(
    ApiRepositoryWrapper<String, Category, CreateInput, UpdateInput> repo,
    this.cache,
    this.serverSeenItemsCache,
  ) : super(repo);
 */
  OfflineRepository(
      this.cache, this.serverVersionCache, this.removedItemsCache);

  final StreamController<Set<Identifier>> _changedItemsController =
      StreamController.broadcast();

  Stream<Set<Identifier>> get changedItems => _changedItemsController.stream;

  Future<Item?> getItemOffline(
    Identifier id,
  ) =>
      cache.getItem(id);

  Future<Map<Identifier, Item>> getItemsOffline() => cache.getItems();

  Future<Item> createItemOffline(CreateInput input) async {
    final p = itemFromCreateInput(input);
    await cache.setItem(p.item1, p.item2);
    _changedItemsController.add({p.item1});
    return p.item2;
  }

  Future<Item> updateItemOffline(
    Identifier id,
    UpdateInput update,
  ) async {
    final item = await cache.getItem(id);
    if (item == null) throw ItemNotFoundException(id);
    // if we haven't cached a server version
    if (await serverVersionCache.getItem(id) == null) {
      await serverVersionCache.setItem(id, item);
    }
    final updated = itemFromUpdateInput(item, update);
    await cache.setItem(id, updated);
    _changedItemsController.add({id});
    return updated;
  }

  Future<void> removeItemOffline(Identifier id) async {
    await serverVersionCache.removeItem(id);
    final item = await cache.getItem(id);
    if (item == null) return;
    await cache.removeItem(id);
    if (isServerVersion(item)) await removedItemsCache.add(id);
    _changedItemsController.add({id});
  }

  bool isServerVersion(Item item);

  /// This expects you to mark the created item with some way to identify
  /// the created items later.
  Tuple2<Identifier, Item> itemFromCreateInput(CreateInput input);

  /// This expects you to mark the created item with some way to identify
  /// the updated items later.
  Item itemFromUpdateInput(Item item, UpdateInput input);

  /// Use whatever marker you added on [`itemFromCreateInput`] to identify the
  /// new items.
  Future<List<Tuple2<Identifier, CreateInput>>> getPendingCreates();

  /// Use whatever marker you added on [`itemFromUpdateInput`] to identify the
  /// new items.
  Future<Map<Identifier, UpdateInput>> getPendingUpdates();

  Future<List<Identifier>> getPendingDeletes() => removedItemsCache.getItems();
} */

/* class SimpleRepository<Identifier, Item>
    extends ApiRepository<Identifier, Item, Item, Item> {
  final Cache<Identifier, Item> cache;

  SimpleRepository(this.cache);

  final StreamController<Set<Identifier>> _changedItemsController =
      StreamController.broadcast();

  @override
  Stream<Set<Identifier>> get changedItems => _changedItemsController.stream;

  @override
  Future<Item?> getItem(Identifier id, String username, String authToken) =>
      cache.getItem(id);

  @override
  Future<Map<Identifier, Item>> getItems() => cache.getItems();
  @override
  Future<void> removeItem(
    Identifier id,
    String username,
    String authToken, [
    bool bypassChangedItemNotification = false,
  ]) async {
    await cache.removeItem(id);
    if (!bypassChangedItemNotification) _changedItemsController.add({id});
  }

  @override
  Future<Item> createItem(Item input, String username, String authToken,
      [Identifier? id]) async {
    if (await cache.getItem(id!) != null) {
      throw Exception("Identifier occupied");
    }
    await cache.setItem(id, input);
    _changedItemsController.add({id});
    return input;
  }

  @override
  Future<Item> updateItem(
      Identifier id, Item input, String username, String authToken) async {
    await cache.setItem(id, input);
    _changedItemsController.add({id});
    return input;
  }

  @override
  Item updateFromDiff(Item update, Item old) => update;

  @override
  Item createFromItem(Item item) => item;

  @override
  Future<void> refreshCache(Map<Identifier, Item> items) async {
    await cache.clear();
    Set<Identifier> ids = {};
    for (final p in items.entries) {
      ids.add(p.key);
      await cache.setItem(p.key, p.value);
    }
    _changedItemsController.add(ids);
  }
} */

class ItemNotFoundException<Identifier> implements Exception {
  final Identifier identifier;

  const ItemNotFoundException(this.identifier);
}

T? ifNotEqualTo<T>(T value, T ifNotEqualTo) =>
    value != ifNotEqualTo ? value : null;
