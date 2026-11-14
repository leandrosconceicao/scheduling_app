import 'package:go_router/go_router.dart';

/// Nomes das rotas. Navegue sempre pelo nome (ou pelas extensões abaixo),
/// nunca montando o path à mão.
abstract final class AppRoutes {
  static const splash = "splash";
  static const schedule = "schedule";
  static const scheduleForm = "schedule-form";
  static const mySchedules = "my-schedules";
  static const login = "login";
  static const signup = "signup";
  static const adminLogin = "admin-login";
  static const adminSchedules = "admin-schedules";
  static const adminConfig = "admin-config";
  static const adminConfigServices = "admin-config-services";
  static const adminConfigEmployees = "admin-config-employees";
}

extension AppNavigation on GoRouter {
  Map<String, String> _company(String companyId) => {"companyId": companyId};

  void goSchedule(String companyId) {
    goNamed(AppRoutes.schedule, pathParameters: _company(companyId));
  }

  Future<void> pushMySchedules(String companyId) {
    return pushNamed(AppRoutes.mySchedules, pathParameters: _company(companyId));
  }

  Future<void> pushScheduleForm(String companyId) {
    return pushNamed(
      AppRoutes.scheduleForm,
      pathParameters: _company(companyId),
    );
  }

  /// Retorna `true` quando o usuário concluiu o login.
  Future<bool?> pushLogin(String companyId, {bool enableCnpjInput = false}) {
    return pushNamed<bool>(
      AppRoutes.login,
      pathParameters: _company(companyId),
      queryParameters: {if (enableCnpjInput) "cnpj": "true"},
    );
  }

  void goLogin(String companyId) {
    goNamed(AppRoutes.login, pathParameters: _company(companyId));
  }

  Future<void> pushSignup(String companyId) {
    return pushNamed(AppRoutes.signup, pathParameters: _company(companyId));
  }

  Future<void> pushAdminLogin(String companyId) {
    return pushNamed(AppRoutes.adminLogin, pathParameters: _company(companyId));
  }

  void goAdminSchedules(String companyId) {
    goNamed(AppRoutes.adminSchedules, pathParameters: _company(companyId));
  }

  void goAdminConfig(String companyId) {
    goNamed(AppRoutes.adminConfig, pathParameters: _company(companyId));
  }

  void goAdminConfigServices(String companyId) {
    goNamed(AppRoutes.adminConfigServices, pathParameters: _company(companyId));
  }

  void goAdminConfigEmployees(String companyId) {
    goNamed(
      AppRoutes.adminConfigEmployees,
      pathParameters: _company(companyId),
    );
  }
}
