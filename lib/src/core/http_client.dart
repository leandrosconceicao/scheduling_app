import 'dart:developer';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response, MultipartFile, FormData;
import 'package:ltech_core/ltech_core.dart'
    show IHttpClient, ApiResponse, TextFormat;

import '../domain/domain.dart';

final class HttpClient implements IHttpClient {
  Dio _client;

  HttpClient._(this._client);

  static const api = String.fromEnvironment("API_URL");

  factory HttpClient() {
    final dio = Dio(
      BaseOptions(
        baseUrl: api,
        validateStatus: (status) => !(status == 401),
        responseType: ResponseType.json,
        receiveTimeout: const Duration(seconds: 15),
        connectTimeout: const Duration(seconds: 15),
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final repository = Get.find<ILocalRepository>();
          // final auth = app.headers?["authorization"] ?? "";
          final auth = repository.read<String>("access_token") ?? "";

          // Um token passado na requisição (ex.: rotas do dono) tem prioridade.
          if (auth.hasContent && !options.headers.containsKey('authorization')) {
            options.headers['authorization'] = "Bearer $auth";
          }
          handler.next(options);
        },
        onError: (error, handler) {
          if (error.response?.statusCode == 401) {
            if (_sentOwnerToken(error.requestOptions)) {
              // O roteador observa a sessão e leva de volta ao login da empresa.
              Get.find<IOwnerSessionService>().end();
            } else {
              Get.find<IAuthService>().logout();
            }

            // final res = ApiResponse.fromJson(error.response?.data, error.response?.statusCode ?? 500);
            // if (res.description.contains("Token")) {
            //   app.blockedAccess();
            //   return;
            // }
          }
          handler.next(error);
        },
      ),
    );

    return HttpClient._(dio);
  }

  /// Só as rotas do dono informam o `authorization` na requisição; nas demais,
  /// o interceptor usa o token do Firebase.
  static bool _sentOwnerToken(RequestOptions options) {
    final sent = options.headers['authorization'];
    final firebaseToken = Get.find<ILocalRepository>().read<String>(
      "access_token",
    );

    return sent != null && sent != "Bearer $firebaseToken";
  }

  /// Converte erros do Dio, preservando a mensagem devolvida pela API.
  static ApiResponse<T> _dioErrorResponse<T>(DioException e) {
    log(e.toString());

    final response = e.response;

    if (response == null) return ApiResponse.socketError();

    final data = response.data;
    final status = response.statusCode ?? 400;

    if (data is Map<String, dynamic>) return ApiResponse.fromJson(data, status);

    return status == 401 ? ApiResponse.unauthorizedAccess() : ApiResponse.unknow();
  }

  @override
  Future<ApiResponse<T?>> delete<T>({
    required String endpoint,
    Map<String, String>? headers,
    Duration? timeout,
    Object? requestBody,
    T Function(dynamic p1)? parser,
  }) async {
    try {
      final response = await _client.delete(
        endpoint,
        options: Options(headers: headers, receiveTimeout: timeout),
        data: requestBody,
      );
      return _responseParser(response, parser);
    } on DioException catch (e) {
      return _dioErrorResponse(e);
    } catch (e) {
      log(e.toString());
      return ApiResponse.unknow(errorDescription: e.toString());
    }
  }

  @override
  Future<ApiResponse<T?>> get<T>({
    required String endpoint,
    Map<String, String>? headers,
    Duration? timeout,
    T? Function(dynamic p1)? parser,
  }) async {
    try {
      final response = await _client.get(
        endpoint,
        options: Options(headers: headers, receiveTimeout: timeout),
      );
      return _responseParser(response, parser);
    } on DioException catch (e) {
      return _dioErrorResponse(e);
    } catch (e, stk) {
      log(e.toString());
      return ApiResponse.unknow(
        errorDescription: e.toString(),
        stackTrace: stk.toString(),
      );
    }
  }

  @override
  Future<ApiResponse<T?>> patch<T>({
    required String endpoint,
    Map<String, String>? headers,
    Duration? timeout,
    Object? requestBody,
    T Function(dynamic p1)? parser,
  }) async {
    try {
      final response = await _client.patch(
        endpoint,
        options: Options(headers: headers, receiveTimeout: timeout),
        data: requestBody,
      );
      return _responseParser(response, parser);
    } on DioException catch (e) {
      return _dioErrorResponse(e);
    } catch (e) {
      log(e.toString());
      return ApiResponse.unknow(errorDescription: e.toString());
    }
  }

  @override
  Future<ApiResponse<T?>> post<T>({
    required String endpoint,
    Map<String, String>? headers,
    Duration? timeout,
    Object? requestBody,
    T Function(dynamic p1)? parser,
  }) async {
    try {
      final response = await _client.post(
        endpoint,
        options: Options(headers: headers, receiveTimeout: timeout),
        data: requestBody,
      );
      return _responseParser(response, parser);
    } on DioException catch (e) {
      return _dioErrorResponse(e);
    } catch (e) {
      log(e.toString());
      return ApiResponse.unknow(errorDescription: e.toString());
    }
  }

  @override
  Future<ApiResponse<T?>> put<T>({
    required String endpoint,
    Map<String, String>? headers,
    Duration? timeout,
    Object? requestBody,
    T Function(dynamic p1)? parser,
  }) async {
    try {
      final response = await _client.put(
        endpoint,
        options: Options(headers: headers, receiveTimeout: timeout),
        data: requestBody,
      );
      return _responseParser(response, parser);
    } catch (e) {
      log(e.toString());
      return ApiResponse.unknow(errorDescription: e.toString());
    }
  }

  static ApiResponse<T> _responseParser<T>(
    Response res,
    T? Function(dynamic)? parser, {
    bool external = false,
  }) {
    final ApiResponse<T> parsed =
        res.statusCode == 204 || (external && (res.statusCode ?? 500) < 399)
        ? ApiResponse.success()
        : ApiResponse.fromJson(res.data, res.statusCode ?? 500);

    final data = res.data is Map && !external ? res.data['dados'] : res.data;

    final parsedData = parser != null && data != null ? parser(data) : null;

    final successData = ApiResponse(
      description: parsed.description,
      tecnicalDescription: parsed.tecnicalDescription,
      // headers: res.headers.,
      result: parsed.result,
      rawBody: data,
      data: parsedData,
    );
    return switch (res.statusCode) {
      200 || 201 => successData,
      204 => ApiResponse.success(),
      _ => parsed,
    };
  }

  @override
  Future<ApiResponse<T?>> postForm<T>({
    required String endpoint,
    Map<String, String>? headers,
    Duration? timeout,
    Uint8List? bytes,
    String? filename,
    T Function(dynamic p1)? parser,
    void Function(int, int)? onSendProgress,
  }) async {
    try {
      final file = MultipartFile.fromBytes(bytes!, filename: filename);

      final formData = FormData.fromMap({"file": file});

      final response = await _client.post(
        endpoint,
        options: Options(headers: headers, receiveTimeout: timeout),
        data: formData,
        onSendProgress: onSendProgress,
      );
      return _responseParser(response, parser);
    } catch (e) {
      log(e.toString());
      return ApiResponse.unknow(errorDescription: e.toString());
    }
  }

  @override
  Future<ApiResponse<T?>> rawGet<T>(
    String endpoint, {
    Duration? timeout,
    T Function(dynamic)? parser,
  }) async {
    try {
      final response = await _client.get(
        endpoint,
        options: Options(receiveTimeout: timeout),
      );
      return _responseParser(response, parser, external: true);
    } catch (e) {
      log(e.toString());
      return ApiResponse.unknow(errorDescription: e.toString());
    }
  }
}
