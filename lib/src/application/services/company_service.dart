import 'dart:typed_data';

import '../../domain/domain.dart';
import '../../shared/shared.dart';
import '../application.dart';

final class CompanyConfigService implements ICompanyService {
  final IHttpClient _client;
  final IFormUploadClient? _uploader;
  final IOwnerSessionService _ownerSession;

  /// [uploader] atende as rotas de imagem (PUT multipart). Se omitido, usa o
  /// próprio [client] quando ele também sabe enviar arquivos.
  CompanyConfigService(
    IHttpClient client,
    this._ownerSession, {
    IFormUploadClient? uploader,
  }) : _client = client,
       _uploader =
           uploader ??
           (client is IFormUploadClient ? client as IFormUploadClient : null);

  String get _companyEndpoint => "/company";
  String get _endpoint => "/schedules";
  String get _lockSchedule => "/lock_schedule";
  String get _employee => "$_companyEndpoint/employees";

  /// Cabeçalho das rotas protegidas por `validateOwnerToken` na API.
  /// Sem ele, a requisição seguiria com o token do Firebase e seria rejeitada.
  Map<String, String> get _ownerHeaders => {
    "authorization": "Bearer ${_ownerSession.token}",
  };

  @override
  Future<ApiResponse<ScheduleType?>> addNewScheduleType(
    String companyId,
    ScheduleType type,
  ) {
    return _client.post(
      endpoint: "$_endpoint/types/$companyId",
      headers: _ownerHeaders,
      requestBody: type.toJson(),
      parser: (json) => ScheduleType.fromJson(json),
    );
  }

  @override
  Future<ApiResponse<Schedule?>> createSchedule(
    String companyId,
    Schedule newSchedule,
  ) {
    return _client.post(
      endpoint: "$_endpoint/$companyId",
      requestBody: newSchedule.toJson(),
      parser: (json) => Schedule.fromJson(json),
    );
  }

  @override
  Future<ApiResponse<List<ScheduleType>?>> getScheduleTypes(String companyId) {
    return _client.get(
      endpoint: "$_endpoint/types/$companyId",
      parser: (json) => ScheduleType.toList(json),
    );
  }

  @override
  Future<ApiResponse<List<ScheduleType>?>> getCompanyScheduleTypes(
    String companyId,
  ) {
    return _client.get(
      endpoint: "$_companyEndpoint/$companyId/schedule_types",
      headers: _ownerHeaders,
      parser: (json) => ScheduleType.toList(json),
    );
  }

  @override
  Future<ApiResponse<List<Schedule>?>> getSchedules(
    String companyId, {
    DateTime? startsAt,
  }) {
    String url = "$_endpoint/$companyId";

    if (startsAt != null) url += "?startsAt=${startsAt.toRequestDate}";

    return _client.get(endpoint: url, parser: (json) => Schedule.toList(json));
  }

  @override
  Future<ApiResponse<List<Schedule>?>> getClientSchedules({
    String? companyId,
    SchedulePeriod period = SchedulePeriod.upcoming,
    bool includeCanceled = false,
    int page = 1,
    int limit = 20,
  }) {
    final query = Uri(
      queryParameters: {
        "period": period.code,
        "includeCanceled": "$includeCanceled",
        "page": "$page",
        "limit": "$limit",
      },
    ).query;
    final base = companyId == null ? "$_endpoint/me" : "$_endpoint/$companyId/me";

    return _client.get(
      endpoint: "$base?$query",
      parser: (json) => Schedule.toList(json),
    );
  }

  @override
  Future<ApiResponse<dynamic>> removeScheduleType(
    String companyId,
    String typeId,
  ) {
    return _client.delete(
      endpoint: "$_endpoint/types/$companyId/$typeId",
      headers: _ownerHeaders,
    );
  }

  @override
  Future<ApiResponse<ScheduleType?>> updateScheduleType(
    String companyId,
    String typeId, {
    String? name,
    num? price,
  }) {
    final updateBody = <String, dynamic>{};

    if (name?.hasContent ?? false) updateBody.putIfAbsent('name', () => name);

    if (price != null) updateBody.putIfAbsent("price", () => price);

    return _client.patch(
      endpoint: "$_endpoint/types/$companyId/$typeId",
      headers: _ownerHeaders,
      requestBody: updateBody,
      parser: (json) => ScheduleType.fromJson(json),
    );
  }

  @override
  Future<ApiResponse<Company?>> addCompany(Company company) {
    return _client.post(
      endpoint: _companyEndpoint,
      headers: _ownerHeaders,
      requestBody: company.toJson(),
      parser: (json) => Company.fromJson(json),
    );
  }

  @override
  Future<ApiResponse<Company?>> getCompany(String id) {
    return _client.get(
      endpoint: "$_companyEndpoint/$id",
      parser: (json) => Company.fromJson(json),
    );
  }

  @override
  Future<ApiResponse<dynamic>> updateCompany(
    String companyId,
    CompanyDto request,
  ) {
    return _client.patch(
      endpoint: "$_companyEndpoint/$companyId",
      headers: _ownerHeaders,
      requestBody: request.toJson(),
    );
  }

  @override
  Future<ApiResponse<Company?>> uploadCompanyLogo(
    String companyId, {
    required Uint8List bytes,
    required String filename,
    required String contentType,
  }) async {
    final uploader = _uploader;

    if (uploader == null) {
      return ApiResponse.unknow(
        errorDescription: "Envio de arquivos não disponível",
      );
    }

    return uploader.putForm(
      endpoint: "$_companyEndpoint/update_logo/$companyId",
      headers: _ownerHeaders,
      bytes: bytes,
      filename: filename,
      contentType: contentType,
      parser: (json) => Company.fromJson(json),
    );
  }

  @override
  Future<ApiResponse<Company?>> getCompanyBySubdomain(String subdomain) {
    return _client.get(
      endpoint: "$_companyEndpoint/search_domain?subdomain=$subdomain",
      parser: (json) => Company.fromJson(json),
    );
  }

  @override
  Future<ApiResponse<Schedule?>> lockSchedule(
    String companyId,
    Schedule newSchedule,
  ) {
    return _client.post(
      endpoint: "$_lockSchedule/$companyId",
      requestBody: newSchedule.toJson(),
      parser: (json) => Schedule.fromJson(json),
    );
  }

  @override
  Future<ApiResponse<dynamic>> removeLockSchedule(
    String companyId,
    Schedule schedule,
  ) {
    return _client.delete(
      endpoint: "$_lockSchedule/$companyId",
      requestBody: schedule.toDeleteJson(),
    );
  }

  @override
  Future<ApiResponse<List<Employee>?>> getEmployees(String companyId) {
    return _client.get(
      endpoint: "$_employee/$companyId",
      parser: (json) => Employee.toList(json),
    );
  }

  @override
  Future<ApiResponse<List<Employee>?>> getCompanyEmployees(String companyId) {
    return _client.get(
      endpoint: "$_companyEndpoint/$companyId/employees",
      headers: _ownerHeaders,
      parser: (json) => Employee.toList(json),
    );
  }

  @override
  Future<ApiResponse<Employee?>> addEmployee(
    String companyId,
    Employee employee,
  ) {
    return _client.post(
      endpoint: "$_employee/$companyId",
      headers: _ownerHeaders,
      requestBody: employee.toJson(),
      parser: (json) => Employee.fromJson(json),
    );
  }

  @override
  Future<ApiResponse<Employee?>> updateEmployee(
    String companyId,
    String employeeId, {
    String? name,
  }) {
    final updateBody = <String, dynamic>{};

    if (name?.hasContent ?? false) updateBody.putIfAbsent("name", () => name);

    return _client.patch(
      endpoint: "$_employee/$companyId/$employeeId",
      headers: _ownerHeaders,
      requestBody: updateBody,
      parser: (json) => Employee.fromJson(json),
    );
  }

  @override
  Future<ApiResponse<Employee?>> uploadEmployeePhoto(
    String companyId,
    String employeeId, {
    required Uint8List bytes,
    required String filename,
    required String contentType,
  }) async {
    final uploader = _uploader;

    if (uploader == null) {
      return ApiResponse.unknow(
        errorDescription: "Envio de arquivos não disponível",
      );
    }

    return uploader.putForm(
      endpoint: "$_employee/$companyId/$employeeId/photo",
      headers: _ownerHeaders,
      bytes: bytes,
      filename: filename,
      contentType: contentType,
      parser: (json) => Employee.fromJson(json),
    );
  }

  @override
  Future<ApiResponse<dynamic>> removeEmployee(
    String companyId,
    String employeeId,
  ) {
    return _client.delete(
      endpoint: "$_employee/$companyId/$employeeId",
      headers: _ownerHeaders,
    );
  }
}
