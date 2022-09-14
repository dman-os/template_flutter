import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

import 'package:api_client/api_client.dart';
import 'package:template_flutter/providers/cache/cache.dart';
import 'package:template_flutter/repositories/repositories.dart';

final sqliteDatabseProvider = Provider<sqflite.Database>(
  (_) => throw StateError(
      "Programming error: Value must be set via a ProviderScope override"),
);

final apiClientProvider = Provider((ref) => ApiClient("http://localhost:8080"));

final userCache =
    Provider((ref) => SqliteUserCache(ref.watch(sqliteDatabseProvider)));
final authCacheProvider =
    Provider((ref) => AuthCache(ref.watch(sqliteDatabseProvider)));

final userRepoProvider = Provider(
  (ref) =>
      ApiUserRepository(ref.watch(userCache), ref.watch(apiClientProvider)),
);
final authRepoProvider = Provider(
  (ref) => AuthRepository(
      ref.watch(authCacheProvider), ref.watch(apiClientProvider)),
);

class AuthState {
  final String _authToken;
  final String loggedInId;
  final DateTime expiresAt;

  AuthState(this._authToken, this.loggedInId, this.expiresAt);

  String? get authToken {
    if (expiresAt.isBefore(DateTime.now())) return null;
    return _authToken;
  }
}

final authStateProvider = StateProvider<AuthState?>((_) => null);
