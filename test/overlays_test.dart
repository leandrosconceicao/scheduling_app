import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:scheduling_app/src/core/core.dart';
import 'package:scheduling_app/src/shared/shared.dart';

/// App mínimo com as mesmas chaves globais do app real e uma página empilhada.
Future<void> _pumpOnDetails(WidgetTester tester) async {
  final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: "/",
    routes: [
      GoRoute(
        path: "/",
        builder: (_, _) => const Scaffold(body: Text("home")),
        routes: [
          GoRoute(
            path: "details",
            builder: (_, _) => const Scaffold(body: Text("details")),
          ),
        ],
      ),
    ],
  );

  await tester.pumpWidget(
    MaterialApp.router(
      routerConfig: router,
      scaffoldMessengerKey: scaffoldMessengerKey,
    ),
  );
  router.push("/details");
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('closing an alert pops only the dialog, not the page', (tester) async {
    await _pumpOnDetails(tester);

    AppAlertDialog.show(body: "mensagem");
    await tester.pumpAndSettle();
    expect(find.text("mensagem"), findsOneWidget);

    await tester.tap(find.text("Ok"));
    await tester.pumpAndSettle();

    expect(find.text("mensagem"), findsNothing);
    expect(find.text("details"), findsOneWidget);
  });

  testWidgets('DefaultAlert close button pops only the dialog', (tester) async {
    // O alerta limita a altura a 30% da tela; usa uma tela de celular alta.
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    await _pumpOnDetails(tester);

    DefaultAlert.show(message: "sucesso");
    await tester.pumpAndSettle();

    await tester.tap(find.byType(IconButton));
    await tester.pumpAndSettle();

    expect(find.text("sucesso"), findsNothing);
    expect(find.text("details"), findsOneWidget);
  });

  testWidgets('confirmRequest returns the chosen option', (tester) async {
    await _pumpOnDetails(tester);

    final result = AppAlertDialog.confirmRequest(message: "Continuar?");
    await tester.pumpAndSettle();
    await tester.tap(find.text("Sim"));
    await tester.pumpAndSettle();

    expect(await result, isTrue);
    expect(find.text("details"), findsOneWidget);
  });

  testWidgets('showSnk uses the app ScaffoldMessenger', (tester) async {
    await _pumpOnDetails(tester);

    showSnk("aviso");
    await tester.pump();

    expect(find.text("aviso"), findsOneWidget);
  });
}
