export 'types.dart';

import 'package:dio/dio.dart';

import 'types.dart';

class ApiClient {
  late Dio dioClient;

  ApiClient(String baseUrl, {Duration timeout = const Duration(seconds: 3)})
      : dioClient = Dio(BaseOptions(
          baseUrl: baseUrl,
          sendTimeout: timeout.inMilliseconds,
          connectTimeout: timeout.inMilliseconds,
          receiveTimeout: timeout.inMilliseconds,
        ));

  ApiClient.fromDio(this.dioClient);

  Future<User> getUser(
    String id,
    String authToken,
  ) async {
    final response = await makeApiCall(
      "get",
      "/users/$id",
      authToken: authToken,
    );
    return User.fromJson(response.data);
  }

  Future<User> createUser(CreateUserRequest request) async {
    final response = await makeApiCall(
      "post",
      "/users",
      jsonBody: request,
    );
    return User.fromJson(response.data);
  }

  Future<AuthenticateResponse> authenticate(
    String identifier,
    String password,
  ) async {
    final response = await makeApiCall("post", "/authenticate", jsonBody: {
      "identifier": identifier,
      "password": password,
    });
    return AuthenticateResponse.fromJson(response.data);
  }

  /// The assumption is that `jsonBody` is json serializable
  Future<Response<dynamic>> makeApiCall(
    String method,
    String path, {
    String? authToken,
    dynamic jsonBody,
  }) async {
    if (!path.startsWith("/")) {
      path = "/$path";
    }
    final options = Options(
      method: method,
    );
    if (authToken != null) {
      options.headers = {
        "Authorization": "Bearer $authToken",
        ...?options.headers
      };
    }
    try {
      return await dioClient.request<Map<String, dynamic>>(
        path,
        options: options,
        data: jsonBody,
      );
    } on DioError catch (err) {
      switch (err.type) {
        case DioErrorType.connectTimeout:
        case DioErrorType.sendTimeout:
        case DioErrorType.receiveTimeout:
          throw TimeoutException(err.message);
        case DioErrorType.response:
          if (err.response!.headers.value("Content-Type") ==
              "application/json") {
            throw EndpointError.fromResponse(err.response!);
          } else {
            throw UnexpectedResponseException(err.response!);
          }
        case DioErrorType.cancel:
          throw Exception("Unexpected $DioErrorType: $err.type");
        case DioErrorType.other:
          throw Exception("Unexpected $DioErrorType: $err");
      }
    }
  }
}

class EndpointError {
  final int code;
  final String type;
  final Map<String, dynamic> json;

  const EndpointError(this.code, this.type, this.json);

  /// This assumes that the response's `Content-Type` header is set to `application/json`
  factory EndpointError.fromResponse(Response response) {
    late Map<String, dynamic> json = response.data;
    return EndpointError(response.statusCode!, json["error"] as String, json);
  }

  @override
  String toString() =>
      "${runtimeType.toString()} { code: $code, type: $type, json: $json }";
}

/// This implies an error in the `ApiClient` impl.
class UnexpectedResponseException implements Exception {
  final Response response;

  const UnexpectedResponseException(this.response);

  @override
  String toString() => "$runtimeType { response: $response }";
}

class TimeoutException implements Exception {
  final String message;

  const TimeoutException(this.message);

  @override
  String toString() => "$runtimeType { message: $message }";
}
