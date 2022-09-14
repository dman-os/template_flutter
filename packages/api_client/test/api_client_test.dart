@TestOn('vm')

import 'package:api_client/api_client.dart';
import 'package:test/test.dart';

const user01Id = "b993f441-2a42-895f-657a-c3bd5863fd56";
const user01Email = "hex.queen@teen.dj";
const user01Username = "sabrina";

T dbg<T>(T val) {
  print("$val");
  return val;
}

void main() {
  final client = ApiClient("http://localhost:4010");
  group('post /authenticate', () {
    late String username;
    late String email;
    late String password;

    setUp(() {
      username = user01Username;
      email = user01Email;
      password = "password";
    });

    test('supports email', () async {
      await client.authenticateEmail(email, password);
    });

    test('supports username', () async {
      await client.authenticateUsername(email, username);
    });
  });
  group('get /users/{id}', () {
    late String authToken;
    late String userId;

    setUp(() {
      authToken = "yeepo";
      userId = user01Id;
    });

    test('succeeds', () async {
      await client.getUser(userId, authToken);
    });
  });
  group('post /users', () {
    final username = "the_dancer";
    final email = "dan.the@danc.er";
    final password = "password";

    test('succeeds', () async {
      await client.createUser(
        CreateUserRequest(username, email, password),
      );
    });
  });
}
