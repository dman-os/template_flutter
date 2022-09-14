import 'dart:async';
import 'dart:io';

import 'package:template_flutter/models.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

import 'cache.dart';

const _serverVersionPrefix = "serverVersion";

Future<sqflite.Database> initDb() async {
  var databasesPath = await sqflite.getDatabasesPath();
  final path = "$databasesPath/main.db";
  {
    final dir = Directory(databasesPath);
    if (!(await dir.exists())) await dir.create(recursive: true);
  }

  // await sqflite.deleteDatabase(path);

  final db = await sqflite.openDatabase(
    path,
    // path,
    version: 1,
    onCreate: (db, version) async {
      await db.transaction(migrateV1);
    },
  );

  return db;
}

Future<void> migrateV1(sqflite.Transaction txn) async {
  await txn.execute('''
create table users ( 
  _id text unique not null,
  username text primary key,
  email text unique,
  picURL text unique,
  -- version integer not null,
  createdAt integer not null,
  updatedAt integer not null
)''');

  const templateRows = """
  ( 
  id text primary key,
  name text not null,
  version integer not null,
  isServerVersion integer not null,
  createdAt integer not null,
  updatedAt integer not null)""";
  await txn.execute("create table template  $templateRows");
  await txn
      .execute("create table ${_serverVersionPrefix}Templates $templateRows");
  await txn.execute('''create table removedTemplates (_id text primary key)''');

  await txn.execute('''
create table stuff ( 
  key text primary key,
  value text key not null)
''');
}

class _StuffCache {
  final sqflite.Database db;

  _StuffCache(this.db);

  Future<String?> getStuff(String key) async {
    List<Map<String, Object?>> maps = await db.query("stuff",
        columns: ["value"], where: "key = ?", whereArgs: [key]);
    if (maps.isNotEmpty) {
      return (maps.first as dynamic)["value"];
    }
    return null;
  }

  Future<void> setStuff(String key, String value) async {
    await db.insert(
      "stuff",
      {
        "key": key,
        "value": value,
      },
      conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
    );
  }

  Future<void> clearStuff(
    String key,
  ) async {
    await db.delete(
      "stuff",
      where: 'key = ?',
      whereArgs: [key],
    );
  }
}

class AuthCache {
  final _StuffCache _stuffCache;

  AuthCache(sqflite.Database db) : _stuffCache = _StuffCache(db);

  Future<String?> getAccessToken() => _stuffCache.getStuff("accessToken");
  Future<void> setAccessToken(String token) =>
      _stuffCache.setStuff("accessToken", token);
  Future<void> clearAccessToken() => _stuffCache.clearStuff("accessToken");

  Future<DateTime?> getTokenExpiresAt() async {
    final expiresAt = await _stuffCache.getStuff("tokenExpiresAt");
    if (expiresAt != null) {
      return DateTime.fromMillisecondsSinceEpoch(int.parse(expiresAt));
    } else {
      return null;
    }
  }

  Future<void> setTokenExpiresAt(DateTime time) => _stuffCache.setStuff(
        "tokenExpiresAt",
        time.millisecondsSinceEpoch.toString(),
      );
  Future<void> clearTokenExpiresAt() =>
      _stuffCache.clearStuff("tokenExpiresAt");

  Future<String?> getRefreshToken() => _stuffCache.getStuff("refreshToken");
  Future<void> setRefreshToken(String token) =>
      _stuffCache.setStuff("refreshToken", token);
  Future<void> clearRefreshToken() => _stuffCache.clearStuff("refreshToken");

  Future<String?> getId() => _stuffCache.getStuff("loggedInId");
  Future<void> setId(String id) => _stuffCache.setStuff("loggedInId", id);
  Future<void> clearId() => _stuffCache.clearStuff("loggedInId");
}

/* class PreferencesCache {
  final _StuffCache _stuffCache;

  PreferencesCache(sqflite.Database db) : _stuffCache = _StuffCache(db);

  Future<Preferences> getPreferences() async => Preferences(
        miscCategory: await getMiscCategory(),
        mainBudget: await getMainBudget(),
        syncPending: await getSyncPending(),
      );

  Future<bool?> getSyncPending() async {
    final pending = await _stuffCache.getStuff("syncPending");
    if (pending == null) return null;
    return pending == "true";
  }

  Future<void> setSyncPending(bool pending) =>
      _stuffCache.setStuff("syncPending", pending ? "true" : "false");
  Future<void> clearSyncPending() => _stuffCache.clearStuff("syncPending");
} */

class _SqliteCache<Identifier, Item> extends Cache<Identifier, Item> {
  final sqflite.Database db;
  String tableName;
  final String primaryColumnName;
  final String? defaultOrderColumn;
  final List<String> columns;
  final Map<String, dynamic> Function(Item) toMap;
  final Item Function(Map<String, dynamic>) fromMap;

  _SqliteCache(
    this.db, {
    required this.tableName,
    required this.primaryColumnName,
    required this.columns,
    required this.toMap,
    required this.fromMap,
    this.defaultOrderColumn,
  });

  @override
  Future<Item?> getItem(Identifier id) async {
    List<Map<String, Object?>> maps = await db.query(tableName,
        columns: columns, where: '$primaryColumnName = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return fromMap(maps.first);
    }
    return null;
  }

  @override
  Future<Map<Identifier, Item>> getItems() async {
    List<Map<String, Object?>> maps = await db.query(
      tableName,
      columns: columns,
      orderBy: defaultOrderColumn,
    );
    return Map.fromEntries(
      maps.map((e) => MapEntry(e[primaryColumnName] as Identifier, fromMap(e))),
    );
  }

  @override
  Future<void> removeItem(Identifier id) async {
    await db
        .delete(tableName, where: '$primaryColumnName = ?', whereArgs: [id]);
  }

  @override
  Future<void> setItem(Identifier id, Item item) async {
    final map = toMap(item);
    await db.insert(
      tableName,
      map,
      conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> clear() async {
    await db.delete(tableName);
  }
}

class SqliteUserCache extends _SqliteCache<String, User> {
  SqliteUserCache(sqflite.Database db)
      : super(
          db,
          tableName: "users",
          primaryColumnName: "username",
          columns: [
            "_id",
            "createdAt",
            "updatedAt",
            "version",
            "firebaseId",
            "username",
            "email",
            "phoneNumber",
            "pictureURL",
            "mainBudget",
            "miscCategory",
          ],
          toMap: (u) => u.toJson()
            ..update("createdAt", (t) => u.createdAt.millisecondsSinceEpoch)
            ..update("updatedAt", (t) => u.updatedAt.millisecondsSinceEpoch),
          fromMap: (m) => User.fromJson(
            Map.from(m)
              ..update(
                  "createdAt",
                  (t) => DateTime.fromMillisecondsSinceEpoch(t as int)
                      .toIso8601String())
              ..update(
                  "updatedAt",
                  (t) => DateTime.fromMillisecondsSinceEpoch(t as int)
                      .toIso8601String()),
          ),
        );
}

class ServerVersionSqliteCache<Identifier, Item>
    extends Cache<Identifier, Item> {
  final _SqliteCache<Identifier, Item> cache;

  ServerVersionSqliteCache(this.cache) {
    cache.tableName = "$_serverVersionPrefix${cache.tableName}";
  }

  @override
  Future<void> clear() => cache.clear();

  @override
  Future<Item?> getItem(Identifier id) => cache.getItem(id);

  @override
  Future<Map<Identifier, Item>> getItems() => cache.getItems();
  @override
  Future<void> removeItem(Identifier id) => cache.removeItem(id);
  @override
  Future<void> setItem(Identifier id, Item item) => cache.setItem(id, item);
}

class _SqliteRemovedItemsCache extends RemovedItemsCache<String> {
  final _SqliteCache<String, String> actualCache;
  _SqliteRemovedItemsCache(sqflite.Database db, String tableName)
      : actualCache = _SqliteCache(
          db,
          tableName: tableName,
          primaryColumnName: "_id",
          columns: ["_id"],
          toMap: (o) => {"_id": o},
          fromMap: (m) => m["_id"],
        );

  @override
  Future<void> add(String id) async => actualCache.setItem(id, id);

  @override
  Future<void> clear() async => actualCache.clear();

  @override
  Future<List<String>> getItems() async =>
      (await actualCache.getItems()).values.toList();

  @override
  Future<bool> has(String id) async => await actualCache.getItem(id) != null;

  @override
  Future<void> remove(String id) => actualCache.removeItem(id);
}

class SqliteRemovedBudgetsCache extends _SqliteRemovedItemsCache {
  SqliteRemovedBudgetsCache(sqflite.Database db) : super(db, "removedBudgets");
}
