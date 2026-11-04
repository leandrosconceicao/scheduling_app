import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:scheduling_app/src/routes/app_routes.dart';
import 'package:scheduling_app/src/routes/navigation_service.dart';

GoRouter _router() {
  return GoRouter(
    initialLocation: "/",
    routes: [
      GoRoute(path: "/", builder: (_, _) => const Text("splash")),
      GoRoute(
        path: "/:companyId",
        name: AppRoutes.schedule,
        builder: (_, _) => const Text("schedule"),
        routes: [
          GoRoute(
            path: "login",
            name: AppRoutes.login,
            builder: (context, _) => Column(
              children: [
                TextButton(
                  onPressed: () => context.pop(true),
                  child: const Text("ok"),
                ),
                TextButton(
                  onPressed: () => context.pop(),
                  child: const Text("cancel"),
                ),
              ],
            ),
          ),
        ],
      ),
    ],
  );
}

Future<(GoRouter, GoRouterNavigationService)> _pump(WidgetTester tester) async {
  final router = _router();
  await tester.pumpWidget(MaterialApp.router(routerConfig: router));
  return (router, GoRouterNavigationService(router));
}

void main() {
  testWidgets('toSchedule goes to the company route', (tester) async {
    final (router, navigation) = await _pump(tester);

    navigation.toSchedule("c1");
    await tester.pumpAndSettle();

    expect(find.text("schedule"), findsOneWidget);
    expect(router.routerDelegate.currentConfiguration.uri.toString(), "/c1");
  });

  testWidgets('requestLogin resolves true when login completes', (tester) async {
    final (_, navigation) = await _pump(tester);
    navigation.toSchedule("c1");
    await tester.pumpAndSettle();

    final result = navigation.requestLogin("c1");
    await tester.pumpAndSettle();
    await tester.tap(find.text("ok"));
    await tester.pumpAndSettle();

    expect(await result, isTrue);
    expect(find.text("schedule"), findsOneWidget);
  });

  testWidgets('requestLogin resolves false when login is dismissed', (tester) async {
    final (_, navigation) = await _pump(tester);
    navigation.toSchedule("c1");
    await tester.pumpAndSettle();

    final result = navigation.requestLogin("c1");
    await tester.pumpAndSettle();
    await tester.tap(find.text("cancel"));
    await tester.pumpAndSettle();

    expect(await result, isFalse);
  });
}
