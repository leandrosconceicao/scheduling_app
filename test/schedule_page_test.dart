import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ltech_core/ltech_core.dart';
import 'package:scheduling_app/src/domain/domain.dart';
import 'package:scheduling_app/src/view/pages/schedule/home/home_states.dart';
import 'package:scheduling_app/src/view/view.dart';

class _FakeCompanyService extends Fake implements ICompanyService {
  Company? company;
  /// Criado dentro do teste: um Completer de fora da zona do `testWidgets`
  /// não é destravado pelo `pump`.
  late Completer<void> completer;

  @override
  Future<ApiResponse<Company?>> getCompany(String id) async {
    await completer.future;
    return ApiResponse.result(data: company, description: "Sem conexão");
  }

  @override
  Future<ApiResponse<List<ScheduleType>?>> getScheduleTypes(String id) async =>
      ApiResponse.result(data: [ScheduleType(id, "Corte", 40, id: "t1")]);

  @override
  Future<ApiResponse<List<Employee>?>> getEmployees(String id) async =>
      ApiResponse.result(data: [Employee("João Silva", "", id)]);

  @override
  Future<ApiResponse<List<Schedule>?>> getSchedules(
    String companyId, {
    DateTime? startsAt,
  }) async => ApiResponse.result(data: <Schedule>[]);
}

class _FakeAuthService extends Fake implements IAuthService {}

class _FakeCloudService extends Fake implements ICloudService {
  @override
  StreamSubscription schedulingSubscription({
    required String companyId,
    required DateTime selectedDate,
    required void Function(Object?) onData,
    Function(Object error)? onError,
  }) => const Stream<Object?>.empty().listen(null);
}

class _FakeNavigation extends Fake implements INavigationService {}

Future<void> _pump(WidgetTester tester, _FakeCompanyService service) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  service.completer = Completer<void>();
  // Criado aqui (e não no setUp) para seus Futures rodarem na zona do teste.
  Get.put(SchedulePageController("c1"));

  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(brightness: Brightness.dark),
      home: const SchedulePage(),
    ),
  );
}

/// Deixa os Futures do carregamento terminarem (o shimmer impede o
/// pumpAndSettle enquanto o esqueleto está na tela).
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// Fecha o controller (cancela relógio e Runner) e desmonta a árvore.
Future<void> _dispose(WidgetTester tester) async {
  Get.delete<SchedulePageController>();
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 31));
}

void main() {
  late _FakeCompanyService service;

  setUp(() {
    service = _FakeCompanyService();
    Get.put<ICompanyService>(service);
    Get.put<IAuthService>(_FakeAuthService());
    Get.put<ICloudService>(_FakeCloudService());
    Get.put<INavigationService>(_FakeNavigation());
  });

  tearDown(Get.reset);

  testWidgets('shows the skeleton while loading, then the store', (
    tester,
  ) async {
    service.company = Company.fromJson({
      "_id": "c1",
      "name": "Barbearia X",
      "address": {"street": "Rua A", "number": "10", "city": "SP"},
      "social": {"whatsapp": "11988887777", "instagram": "@barbearia"},
      "configuration": {
        "openingHours": "00:00",
        "closingTime": "23:59",
        "showSchedulesValues": true,
      },
    });
    await _pump(tester, service);

    expect(find.byType(HomeSkeleton), findsOneWidget);
    expect(find.text("Agendar horário"), findsNothing);

    service.completer.complete();
    await _settle(tester);

    expect(find.text("Barbearia X"), findsOneWidget);
    expect(find.text("Agendar horário"), findsOneWidget);
    expect(find.textContaining("Aberto agora"), findsOneWidget);
    expect(find.text("Como chegar"), findsOneWidget);
    expect(find.text("WhatsApp"), findsOneWidget);
    expect(find.text("Corte"), findsOneWidget);
    expect(find.text("João Silva"), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _dispose(tester);
  });

  testWidgets('shows an error with retry when the store fails', (tester) async {
    service.company = null;
    await _pump(tester, service);
    service.completer.complete();
    await _settle(tester);

    expect(find.text("Sem conexão"), findsOneWidget);
    expect(find.text("Tentar novamente"), findsOneWidget);
    expect(find.text("Agendar horário"), findsNothing);
    expect(tester.takeException(), isNull);
    await _dispose(tester);
  });
}
