import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ltech_core/ltech_core.dart';
import 'package:scheduling_app/src/application/application.dart';
import 'package:scheduling_app/src/domain/domain.dart';

class _RecordingHttpClient implements IHttpClient {
  String? method;
  String? endpoint;
  Object? requestBody;
  Map<String, String>? headers;

  void _record(
    String method,
    String endpoint,
    Map<String, String>? headers, [
    Object? requestBody,
  ]) {
    this.method = method;
    this.endpoint = endpoint;
    this.headers = headers;
    this.requestBody = requestBody;
  }

  @override
  Future<ApiResponse<T?>> get<T>({
    required String endpoint,
    Map<String, String>? headers,
    Duration? timeout,
    T? Function(dynamic p1)? parser,
  }) async {
    _record("GET", endpoint, headers);
    return ApiResponse.success();
  }

  @override
  Future<ApiResponse<T?>> post<T>({
    required String endpoint,
    Map<String, String>? headers,
    Duration? timeout,
    Object? requestBody,
    T Function(dynamic p1)? parser,
  }) async {
    _record("POST", endpoint, headers, requestBody);
    return ApiResponse.success();
  }

  @override
  Future<ApiResponse<T?>> patch<T>({
    required String endpoint,
    Map<String, String>? headers,
    Duration? timeout,
    Object? requestBody,
    T Function(dynamic p1)? parser,
  }) async {
    _record("PATCH", endpoint, headers, requestBody);
    return ApiResponse.success();
  }

  @override
  Future<ApiResponse<T?>> delete<T>({
    required String endpoint,
    Map<String, String>? headers,
    Duration? timeout,
    Object? requestBody,
    T Function(dynamic p1)? parser,
  }) async {
    _record("DELETE", endpoint, headers, requestBody);
    return ApiResponse.success();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeOwnerSession extends ChangeNotifier implements IOwnerSessionService {
  @override
  String get token => "owner-token";

  @override
  bool get isAuthenticated => true;

  @override
  Future<void> start(String token) async {}

  @override
  Future<void> end() async {}
}

void main() {
  const ownerHeaders = {"authorization": "Bearer owner-token"};

  late _RecordingHttpClient client;
  late CompanyConfigService service;

  setUp(() {
    client = _RecordingHttpClient();
    service = CompanyConfigService(client, _FakeOwnerSession());
  });

  test(
    "getCompanyScheduleTypes usa a rota do dono com o token do dono",
    () async {
      await service.getCompanyScheduleTypes("company1");

      expect(client.method, "GET");
      expect(client.endpoint, "/company/company1/schedule_types");
      expect(client.headers, ownerHeaders);
    },
  );

  test("getScheduleTypes usa a rota do cliente sem o token do dono", () async {
    await service.getScheduleTypes("company1");

    expect(client.method, "GET");
    expect(client.endpoint, "/schedules/types/company1");
    expect(client.headers, isNull);
  });

  test("addNewScheduleType envia o token do dono", () async {
    await service.addNewScheduleType(
      "company1",
      ScheduleType("company1", "Barba", 35),
    );

    expect(client.method, "POST");
    expect(client.endpoint, "/schedules/types/company1");
    expect(client.headers, ownerHeaders);
    expect(client.requestBody, {"name": "Barba", "price": 35});
  });

  test("updateScheduleType usa a rota de tipos e envia os campos", () async {
    await service.updateScheduleType(
      "company1",
      "type1",
      name: "Barba",
      price: 35,
    );

    expect(client.method, "PATCH");
    expect(client.endpoint, "/schedules/types/company1/type1");
    expect(client.headers, ownerHeaders);
    expect(client.requestBody, {"name": "Barba", "price": 35});
  });

  test("removeScheduleType envia o token do dono", () async {
    await service.removeScheduleType("company1", "type1");

    expect(client.method, "DELETE");
    expect(client.endpoint, "/schedules/types/company1/type1");
    expect(client.headers, ownerHeaders);
  });

  test("rotas do cliente seguem sem o cabeçalho do dono", () async {
    await service.getSchedules("company1");
    expect(client.headers, isNull);

    await service.getEmployees("company1");
    expect(client.headers, isNull);
  });
}
