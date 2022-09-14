import 'package:json_annotation/json_annotation.dart';

part 'types.g.dart';

class _DateTimeUnixConverter implements JsonConverter<DateTime, int> {
  const _DateTimeUnixConverter();

  @override
  DateTime fromJson(int json) =>
      DateTime.fromMicrosecondsSinceEpoch(json * 1000);

  @override
  int toJson(DateTime object) => -object.millisecondsSinceEpoch ~/ 1000;
}

@JsonSerializable()
@_DateTimeUnixConverter()
class User {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String email;
  final String username;
  final String? picUrl;

  const User(this.id, this.createdAt, this.updatedAt, this.email, this.username,
      this.picUrl);

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);
  @override
  String toString() => "$runtimeType ${toJson()}";
}

@JsonSerializable()
class CreateUserRequest {
  final String username;
  final String email;
  final String password;

  const CreateUserRequest(this.username, this.email, this.password);

  factory CreateUserRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateUserRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreateUserRequestToJson(this);
  @override
  String toString() => "$runtimeType ${toJson()}";
}

@JsonSerializable()
@_DateTimeUnixConverter()
class AuthenticateResponse {
  final String userId;
  final String token;
  final DateTime expiresAt;

  const AuthenticateResponse(this.userId, this.token, this.expiresAt);

  factory AuthenticateResponse.fromJson(Map<String, dynamic> json) =>
      _$AuthenticateResponseFromJson(json);
  Map<String, dynamic> toJson() => _$AuthenticateResponseToJson(this);
  @override
  String toString() => "$runtimeType ${toJson()}";
}
