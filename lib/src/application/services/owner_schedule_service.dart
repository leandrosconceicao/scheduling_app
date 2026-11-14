import '../../domain/domain.dart';
import '../../shared/shared.dart';

final class OwnerScheduleService implements IOwnerScheduleService {
  final IHttpClient _client;
  final IOwnerSessionService _ownerSession;

  OwnerScheduleService(this._client, this._ownerSession);

  Map<String, String> get _ownerHeaders => {
    "authorization": "Bearer ${_ownerSession.token}",
  };

  String _base(String companyId) => "/company/$companyId";

  @override
  Future<ApiResponse<List<Schedule>?>> getAppointments(
    String companyId, {
    DateTime? from,
    DateTime? to,
    String? employeeId,
    Set<ScheduleState> states = const {},
    String? search,
    bool descending = false,
    int page = 1,
    int limit = 100,
  }) {
    final query = Uri(
      queryParameters: {
        if (from != null) "from": from.toUtc().toIso8601String(),
        if (to != null) "to": to.toUtc().toIso8601String(),
        if (employeeId != null && employeeId.isNotEmpty)
          "employeeId": employeeId,
        if (states.isNotEmpty) "state": states.map((e) => e.code).join(","),
        if (search != null && search.trim().isNotEmpty) "search": search.trim(),
        "order": descending ? "desc" : "asc",
        "page": "$page",
        "limit": "$limit",
      },
    ).query;

    return _client.get(
      endpoint: "${_base(companyId)}/appointments?$query",
      headers: _ownerHeaders,
      parser: (json) => Schedule.toList(json),
    );
  }

  @override
  Future<ApiResponse<Schedule?>> completeAppointment(
    String companyId,
    String id,
  ) {
    return _client.patch(
      endpoint: "${_base(companyId)}/appointments/$id",
      headers: _ownerHeaders,
      requestBody: {"state": ScheduleState.completed.code},
      parser: (json) => Schedule.fromJson(json),
    );
  }

  @override
  Future<ApiResponse<dynamic>> cancelAppointment(
    String companyId,
    String id,
    String reason,
  ) {
    return _client.delete(
      endpoint: "${_base(companyId)}/schedules/$id",
      headers: _ownerHeaders,
      requestBody: {"reason": reason},
    );
  }
}
