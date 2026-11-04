import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:scheduling_app/src/domain/domain.dart';
import 'package:scheduling_app/src/routes/app_routes.dart';
import 'package:scheduling_app/src/routes/guards/owner_guard.dart';

class _FakeOwnerSession extends ChangeNotifier implements IOwnerSessionService {
  String _token = "";

  @override
  bool get isAuthenticated => _token.isNotEmpty;

  @override
  String get token => _token;

  @override
  Future<void> start(String token) async {
    _token = token;
    notifyListeners();
  }

  @override
  Future<void> end() async {
    _token = "";
    notifyListeners();
  }
}

/// Mesma estrutura de rotas do app, com telas de marcação.
GoRouter _router(IOwnerSessionService session, String initialLocation) {
  final guard = OwnerGuard(session);

  return GoRouter(
    initialLocation: initialLocation,
    refreshListenable: session,
    routes: [
      GoRoute(
        path: "/agendamentos/:companyId",
        redirect: (_, state) => "/${state.pathParameters["companyId"]}",
      ),
      GoRoute(
        path: "/:companyId",
        name: AppRoutes.schedule,
        builder: (_, _) => const Text("schedule"),
        routes: [
          GoRoute(
            path: "admin/login",
            name: AppRoutes.adminLogin,
            redirect: guard.skipLoginWhenAuthenticated,
            builder: (_, _) => const Text("admin-login"),
          ),
          GoRoute(
            path: "admin/configuracoes",
            name: AppRoutes.adminConfig,
            redirect: guard.requireOwner,
            builder: (_, _) => const Text("admin-config"),
          ),
        ],
      ),
    ],
  );
}

Future<GoRouter> _pump(
  WidgetTester tester,
  IOwnerSessionService session,
  String location,
) async {
  final router = _router(session, location);
  await tester.pumpWidget(MaterialApp.router(routerConfig: router));
  await tester.pumpAndSettle();
  return router;
}

String _location(GoRouter router) {
  return router.routerDelegate.currentConfiguration.uri.toString();
}

void main() {
  testWidgets('admin area without session redirects to login keeping "from"',
      (tester) async {
    final router = await _pump(tester, _FakeOwnerSession(), "/c1/admin/configuracoes");

    expect(find.text("admin-login"), findsOneWidget);
    expect(
      _location(router),
      "/c1/admin/login?from=%2Fc1%2Fadmin%2Fconfiguracoes",
    );
  });

  testWidgets('starting the session re-evaluates the guard', (tester) async {
    final session = _FakeOwnerSession();
    final router = await _pump(tester, session, "/c1/admin/configuracoes");

    await session.start("token");
    await tester.pumpAndSettle();

    expect(find.text("admin-config"), findsOneWidget);
    expect(_location(router), "/c1/admin/configuracoes");
  });

  testWidgets('ending the session returns to login keeping "from"',
      (tester) async {
    final session = _FakeOwnerSession();
    await session.start("token");
    final router = await _pump(tester, session, "/c1/admin/configuracoes");

    await session.end();
    await tester.pumpAndSettle();

    expect(find.text("admin-login"), findsOneWidget);
    expect(
      _location(router),
      "/c1/admin/login?from=%2Fc1%2Fadmin%2Fconfiguracoes",
    );
  });

  testWidgets('authenticated owner skips the login page', (tester) async {
    final session = _FakeOwnerSession();
    await session.start("token");

    final router = await _pump(tester, session, "/c1/admin/login");

    expect(find.text("admin-config"), findsOneWidget);
    expect(_location(router), "/c1/admin/configuracoes");
  });

  testWidgets('legacy /agendamentos links redirect to the company route',
      (tester) async {
    final router = await _pump(tester, _FakeOwnerSession(), "/agendamentos/c1");

    expect(find.text("schedule"), findsOneWidget);
    expect(_location(router), "/c1");
  });

  test('safeFrom only accepts internal paths', () {
    expect(OwnerGuard.safeFrom("/c1/admin/configuracoes"), "/c1/admin/configuracoes");
    expect(OwnerGuard.safeFrom("//evil.com"), isNull);
    expect(OwnerGuard.safeFrom("https://evil.com"), isNull);
    expect(OwnerGuard.safeFrom(null), isNull);
  });
}
