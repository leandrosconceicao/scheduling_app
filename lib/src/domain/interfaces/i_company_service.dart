import 'dart:typed_data';

import '../../application/application.dart';
import '../../shared/shared.dart';
import '../domain.dart';

abstract interface class ICompanyService {
  Future<ApiResponse<ScheduleType?>> addNewScheduleType(
    String companyId,
    ScheduleType type,
  );

  Future<ApiResponse<List<ScheduleType>?>> getScheduleTypes(String companyId);

  Future<ApiResponse> removeScheduleType(String companyId, String typeId);

  Future<ApiResponse<ScheduleType?>> updateScheduleType(
    String companyId,
    String typeId, {
    String? name,
    num? price,
  });

  Future<ApiResponse<List<Schedule>?>> getSchedules(
    String companyId, {
    DateTime? startsAt,
  });

  Future<ApiResponse<Schedule?>> createSchedule(
    String companyId,
    Schedule schedules,
  );

  Future<ApiResponse<Schedule?>> lockSchedule(
    String companyId,
    Schedule newSchedule,
  );

  Future<ApiResponse> removeLockSchedule(String companyId, Schedule schedule);

  Future<ApiResponse<Company?>> addCompany(Company company);
  Future<ApiResponse<Company?>> getCompany(String id);
  Future<ApiResponse<Company?>> getCompanyBySubdomain(String subdomain);
  Future<ApiResponse> updateCompany(String companyId, CompanyDto request);

  /// Envia a logo (JPEG, PNG ou WebP, até 2 MB). Devolve a empresa atualizada.
  Future<ApiResponse<Company?>> uploadCompanyLogo(
    String companyId, {
    required Uint8List bytes,
    required String filename,
    required String contentType,
  });

  Future<ApiResponse<List<Employee>?>> getEmployees(String companyId);

  /// Lista os barbeiros pela rota do dono da empresa.
  Future<ApiResponse<List<Employee>?>> getCompanyEmployees(String companyId);

  Future<ApiResponse<Employee?>> addEmployee(
    String companyId,
    Employee employee,
  );

  Future<ApiResponse<Employee?>> updateEmployee(
    String companyId,
    String employeeId, {
    String? name,
  });

  /// Envia a foto (JPEG, PNG ou WebP, até 2 MB). Devolve o barbeiro atualizado.
  Future<ApiResponse<Employee?>> uploadEmployeePhoto(
    String companyId,
    String employeeId, {
    required Uint8List bytes,
    required String filename,
    required String contentType,
  });

  Future<ApiResponse> removeEmployee(String companyId, String employeeId);
}
