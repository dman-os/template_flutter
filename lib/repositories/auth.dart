import 'dart:async';

import 'package:api_client/api_client.dart';
import 'package:template_flutter/providers/cache/cache.dart';
import 'package:tuple/tuple.dart';

class RefreshTokenExpiredException implements Exception {}

class CacheEmptyException implements Exception {}

class AuthRepository {
  final AuthCache cache;
  final ApiClient client;

  AuthRepository(
    this.cache,
    this.client,
  );

  Future<AuthenticateResponse> signInUsername(
    String username,
    String password,
  ) async {
    final response = await client.authenticateUsername(username, password);
    await refreshFromValues(response);
    return response;
  }

  Future<AuthenticateResponse> signInEmail(
    String email,
    String password,
  ) async {
    final response = await client.authenticateEmail(email, password);
    await refreshFromValues(response);
    return response;
  }

  Future<String> getLoggedInId() async {
    final id = await cache.getId();
    if (id == null) throw CacheEmptyException();
    return id;
  }

  Future<String?> tryGetLoggedInId() => cache.getId();

  Future<Tuple2<String, DateTime>?> tryGetAccessToken() async {
    final expiresAt = await cache.getTokenExpiresAt();
    if (expiresAt == null || expiresAt.isBefore(DateTime.now())) return null;
    return Tuple2((await cache.getAccessToken())!, expiresAt);
  }

  /// This will immediately override any values in the cache.
  Future<void> refreshFromValues(AuthenticateResponse response) async {
    await cache.setAccessToken(response.token);
    // await cache.setRefreshToken(refreshToken);
    await cache.setTokenExpiresAt(response.expiresAt);
    await cache.setId(response.userId);
  }

  Future<void> clearCache() async {
    await cache.clearAccessToken();
    await cache.clearRefreshToken();
    await cache.clearTokenExpiresAt();
    await cache.clearId();
  }
}
