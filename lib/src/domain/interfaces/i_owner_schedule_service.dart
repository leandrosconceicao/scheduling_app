import '../../shared/shared.dart';
import '../domain.dart';

/// Agendamentos vistos pelo proprietário da empresa.
abstract interface class IOwnerScheduleService {
  /// [states] vazio usa o padrão da API (agendados e concluídos).
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
  });

  /// Conclui o atendimento (só após o início do horário).
  Future<ApiResponse<Schedule?>> completeAppointment(
    String companyId,
    String id,
  );

  /// Cancela pela empresa; o [reason] é obrigatório.
  Future<ApiResponse> cancelAppointment(
    String companyId,
    String id,
    String reason,
  );
}
