// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'types.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) => User(
      json['id'] as String,
      const _DateTimeUnixConverter().fromJson(json['createdAt'] as int),
      const _DateTimeUnixConverter().fromJson(json['updatedAt'] as int),
      json['email'] as String,
      json['username'] as String,
      json['picUrl'] as String?,
    );

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
      'id': instance.id,
      'createdAt': const _DateTimeUnixConverter().toJson(instance.createdAt),
      'updatedAt': const _DateTimeUnixConverter().toJson(instance.updatedAt),
      'email': instance.email,
      'username': instance.username,
      'picUrl': instance.picUrl,
    };

CreateUserRequest _$CreateUserRequestFromJson(Map<String, dynamic> json) =>
    CreateUserRequest(
      json['username'] as String,
      json['email'] as String,
      json['password'] as String,
    );

Map<String, dynamic> _$CreateUserRequestToJson(CreateUserRequest instance) =>
    <String, dynamic>{
      'username': instance.username,
      'email': instance.email,
      'password': instance.password,
    };

AuthenticateResponse _$AuthenticateResponseFromJson(
        Map<String, dynamic> json) =>
    AuthenticateResponse(
      json['userId'] as String,
      json['token'] as String,
      const _DateTimeUnixConverter().fromJson(json['expiresAt'] as int),
    );

Map<String, dynamic> _$AuthenticateResponseToJson(
        AuthenticateResponse instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'token': instance.token,
      'expiresAt': const _DateTimeUnixConverter().toJson(instance.expiresAt),
    };
