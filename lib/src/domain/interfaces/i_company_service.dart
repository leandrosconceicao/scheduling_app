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

  Future<ApiResponse<List<Employee>?>> getEmployees(String companyId);
}
