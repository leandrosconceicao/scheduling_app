import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../domain/domain.dart';
import '../view/view.dart';
import 'app_routes.dart';
import 'guards/owner_guard.dart';
import 'widgets/app_page.dart';
import 'widgets/controller_scope.dart';

class AppRouter {
  AppRouter._internal();

  static final AppRouter _intance = AppRouter._internal();

  factory AppRouter() => _intance;

  late final GoRouter instance = _build(Get.find<IOwnerSessionService>());

  static GoRouter _build(IOwnerSessionService ownerSession) {
    final ownerGuard = OwnerGuard(ownerSession);

    return GoRouter(
      initialLocation: "/",
      navigatorKey: rootNavigatorKey,
      refreshListenable: ownerSession,
      debugLogDiagnostics: kDebugMode,
      errorPageBuilder: (_, state) =>
          appPage(state, NotFoundPage(error: state.error)),
      routes: [
        GoRoute(
          path: "/",
          name: AppRoutes.splash,
          pageBuilder: (_, state) => appPage(
            state,
            ControllerScope(
              create: SplashController.new,
              child: const SplashPage(),
            ),
          ),
        ),
        // Compatibilidade com links antigos.
        GoRoute(
          path: "/agendamentos/:companyId",
          redirect: (_, state) => "/${state.pathParameters["companyId"]}",
        ),
        GoRoute(
          path: "/:companyId",
          name: AppRoutes.schedule,
          pageBuilder: (_, state) => appPage(
            state,
            ControllerScope(
              create: () => SchedulePageController(_companyId(state)),
              child: const SchedulePage(),
            ),
          ),
          routes: [
            GoRoute(
              path: "agendar",
              name: AppRoutes.scheduleForm,
              // Voltar (AppBar, sistema ou navegador) retorna uma etapa do
              // formulário antes de fechar a tela.
              onExit: (_, _) => _canLeaveScheduleForm(),
              pageBuilder: (_, state) => appPage(state, const ScheduleForm()),
            ),
            GoRoute(
              path: "login",
              name: AppRoutes.login,
              pageBuilder: (_, state) => appPage(
                state,
                ControllerScope(
                  create: () => LoginPageController(
                    _companyId(state),
                    enableCnpjInput:
                        state.uri.queryParameters["cnpj"] == "true",
                  ),
                  child: const LoginPage(),
                ),
              ),
            ),
            GoRoute(
              path: "cadastro",
              name: AppRoutes.signup,
              pageBuilder: (_, state) => appPage(
                state,
                ControllerScope(
                  create: SignupController.new,
                  child: const SignupPage(),
                ),
              ),
            ),
            GoRoute(
              path: "admin/login",
              name: AppRoutes.adminLogin,
              redirect: ownerGuard.skipLoginWhenAuthenticated,
              pageBuilder: (_, state) => appPage(
                state,
                ControllerScope(
                  create: () => CompanyLoginController(
                    _companyId(state),
                    from: OwnerGuard.safeFrom(
                      state.uri.queryParameters["from"],
                    ),
                  ),
                  child: const CompanyLoginPage(),
                ),
              ),
            ),
            GoRoute(
              path: "admin/configuracoes",
              name: AppRoutes.adminConfig,
              redirect: ownerGuard.requireOwner,
              pageBuilder: (_, state) => appPage(
                state,
                ControllerScope(
                  create: () =>
                      CompanyConfigurationController(_companyId(state)),
                  child: const CompanyConfigurationPage(),
                ),
              ),
              routes: [
                GoRoute(
                  path: "servicos",
                  name: AppRoutes.adminConfigServices,
                  redirect: ownerGuard.requireOwner,
                  pageBuilder: (_, state) => appPage(
                    state,
                    ControllerScope(
                      create: () =>
                          CompanyServicesController(_companyId(state)),
                      child: const CompanyConfigurationServices(),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  static String _companyId(GoRouterState state) {
    return state.pathParameters["companyId"] ?? "";
  }

  static bool _canLeaveScheduleForm() {
    if (!Get.isRegistered<SchedulePageController>()) return true;
    return Get.find<SchedulePageController>().handleFormBack();
  }
}
