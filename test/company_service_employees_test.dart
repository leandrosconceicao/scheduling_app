import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ltech_core/ltech_core.dart';
import 'package:scheduling_app/src/application/application.dart';
import 'package:scheduling_app/src/domain/domain.dart';

class _RecordingHttpClient implements IHttpClient, IFormUploadClient {
  String? method;
  String? endpoint;
  Object? requestBody;
  Map<String, String>? headers;
  String? uploadContentType;
  String? uploadFilename;
  int? uploadSize;

  ApiResponse<T?> _record<T>(
    String method,
    String endpoint,
    Map<String, String>? headers, [
    Object? requestBody,
  ]) {
    this.method = method;
    this.endpoint = endpoint;
    this.headers = headers;
    this.requestBody = requestBody;
    return ApiResponse.success();
  }

  @override
  Future<ApiResponse<T?>> get<T>({
    required String endpoint,
    Map<String, String>? headers,
    Duration? timeout,
    T? Function(dynamic p1)? parser,
  }) async => _record("GET", endpoint, headers);

  @override
  Future<ApiResponse<T?>> post<T>({
    required String endpoint,
    Map<String, String>? headers,
    Duration? timeout,
    Object? requestBody,
    T Function(dynamic p1)? parser,
  }) async => _record("POST", endpoint, headers, requestBody);

  @override
  Future<ApiResponse<T?>> patch<T>({
    required String endpoint,
    Map<String, String>? headers,
    Duration? timeout,
    Object? requestBody,
    T Function(dynamic p1)? parser,
  }) async => _record("PATCH", endpoint, headers, requestBody);

  @override
  Future<ApiResponse<T?>> delete<T>({
    required String endpoint,
    Map<String, String>? headers,
    Duration? timeout,
    Object? requestBody,
    T Function(dynamic p1)? parser,
  }) async => _record("DELETE", endpoint, headers, requestBody);

  @override
  Future<ApiResponse<T?>> putForm<T>({
    required String endpoint,
    required Uint8List bytes,
    required String filename,
    required String contentType,
    Map<String, String>? headers,
    Duration? timeout,
    T Function(dynamic p1)? parser,
    void Function(int, int)? onSendProgress,
  }) async {
    uploadContentType = contentType;
    uploadFilename = filename;
    uploadSize = bytes.length;
    return _record("PUT", endpoint, headers);
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

  test("getCompanyEmployees usa a rota do dono com o token do dono", () async {
    await service.getCompanyEmployees("company1");

    expect(client.method, "GET");
    expect(client.endpoint, "/company/company1/employees");
    expect(client.headers, ownerHeaders);
  });

  test("addEmployee envia nome e foto com o token do dono", () async {
    await service.addEmployee("company1", Employee("Bruno", "", "company1"));

    expect(client.method, "POST");
    expect(client.endpoint, "/company/employees/company1");
    expect(client.headers, ownerHeaders);
    expect(client.requestBody, {"name": "Bruno"});
  });

  test("updateEmployee envia só o nome preenchido", () async {
    await service.updateEmployee("company1", "emp1", name: "Bruno");

    expect(client.method, "PATCH");
    expect(client.endpoint, "/company/employees/company1/emp1");
    expect(client.headers, ownerHeaders);
    expect(client.requestBody, {"name": "Bruno"});

    await service.updateEmployee("company1", "emp1", name: "");

    expect(client.requestBody, <String, dynamic>{});
  });

  test(
    "uploadEmployeePhoto envia o arquivo por PUT com o token do dono",
    () async {
      await service.uploadEmployeePhoto(
        "company1",
        "emp1",
        bytes: Uint8List(5),
        filename: "foto.png",
        contentType: "image/png",
      );

      expect(client.method, "PUT");
      expect(client.endpoint, "/company/employees/company1/emp1/photo");
      expect(client.headers, ownerHeaders);
      expect(client.uploadContentType, "image/png");
      expect(client.uploadFilename, "foto.png");
      expect(client.uploadSize, 5);
    },
  );

  test("removeEmployee envia o token do dono", () async {
    await service.removeEmployee("company1", "emp1");

    expect(client.method, "DELETE");
    expect(client.endpoint, "/company/employees/company1/emp1");
    expect(client.headers, ownerHeaders);
  });

  test(
    "a leitura pública de barbeiros segue sem o cabeçalho do dono",
    () async {
      await service.getEmployees("company1");

      expect(client.endpoint, "/company/employees/company1");
      expect(client.headers, isNull);
    },
  );
}
