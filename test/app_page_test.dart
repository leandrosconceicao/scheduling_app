import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:scheduling_app/src/routes/widgets/app_page.dart';

Future<Page<dynamic>> _pumpPage(WidgetTester tester, {required bool isWeb}) async {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: "/",
        pageBuilder: (_, state) => appPage(state, const Text("home"), isWeb: isWeb),
      ),
    ],
  );
  await tester.pumpWidget(MaterialApp.router(routerConfig: router));
  return tester.widget<Navigator>(find.byType(Navigator)).pages.last;
}

void main() {
  testWidgets('uses no transition on web', (tester) async {
    expect(await _pumpPage(tester, isWeb: true), isA<NoTransitionPage<void>>());
  });

  testWidgets('uses the platform transition on mobile', (tester) async {
    expect(await _pumpPage(tester, isWeb: false), isA<MaterialPage<void>>());
  });
}
