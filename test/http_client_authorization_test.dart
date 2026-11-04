import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide HeaderValue;
import 'package:ltech_core/ltech_core.dart' show ApiResponse;
import 'package:scheduling_app/src/core/http_client.dart';
import 'package:scheduling_app/src/domain/domain.dart';

class _FakeLocalRepository implements ILocalRepository {
  final Map<String, String> values;

  _FakeLocalRepository(this.values);

  @override
  T? read<T>(String key) => values[key] as T?;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeOwnerSession extends ChangeNotifier implements IOwnerSessionService {
  var ended = false;

  @override
  String get token => "owner-token";

  @override
  bool get isAuthenticated => !ended;

  @override
  Future<void> start(String token) async {}

  @override
  Future<void> end() async => ended = true;
}

class _FakeAuthService implements IAuthService {
  var loggedOut = false;

  @override
  Future<ApiResponse> logout() async {
    loggedOut = true;
    return ApiResponse.success();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late HttpServer server;
  late _FakeOwnerSession ownerSession;
  late _FakeAuthService authService;
  String? receivedAuthorization;
  var responseStatus = 204;

  String url() => "http://${server.address.host}:${server.port}/teste";

  setUp(() async {
    receivedAuthorization = null;
    responseStatus = 204;
    ownerSession = _FakeOwnerSession();
    authService = _FakeAuthService();

    Get.put<ILocalRepository>(
      _FakeLocalRepository({"access_token": "firebase-token"}),
    );
    Get.put<IOwnerSessionService>(ownerSession);
    Get.put<IAuthService>(authService);

    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      receivedAuthorization = request.headers.value("authorization");
      request.response
        ..statusCode = responseStatus
        ..headers.contentType = ContentType.json;
      if (responseStatus != 204) {
        request.response.write(
          jsonEncode({"statusProcess": false, "message": "Não autorizado"}),
        );
      }
      await request.response.close();
    });
  });

  tearDown(() async {
    await server.close(force: true);
    Get.reset();
  });

  test("sem cabeçalho explícito, envia o token do Firebase", () async {
    await HttpClient().get(endpoint: url());

    expect(receivedAuthorization, "Bearer firebase-token");
  });

  test("cabeçalho explícito tem prioridade sobre o token do Firebase", () async {
    await HttpClient().get(
      endpoint: url(),
      headers: {"authorization": "Bearer owner-token"},
    );

    expect(receivedAuthorization, "Bearer owner-token");
  });

  test("401 com token do dono encerra só a sessão do dono", () async {
    responseStatus = 401;

    final res = await HttpClient().patch(
      endpoint: url(),
      headers: {"authorization": "Bearer owner-token"},
    );

    expect(ownerSession.ended, isTrue);
    expect(authService.loggedOut, isFalse);
    expect(res.result, isFalse);
    expect(res.description, "Não autorizado");
  });

  test("401 com token do Firebase mantém a sessão do dono", () async {
    responseStatus = 401;

    final res = await HttpClient().get(endpoint: url());

    expect(authService.loggedOut, isTrue);
    expect(ownerSession.ended, isFalse);
    expect(res.description, "Não autorizado");
  });
}
