import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ltech_core/ltech_core.dart' show ApiResponse, IHttpClient;
import 'package:scheduling_app/src/application/application.dart';
import 'package:scheduling_app/src/core/core.dart';
import 'package:scheduling_app/src/domain/domain.dart';
import 'package:scheduling_app/src/view/view.dart'
    show MySchedulesController, MySchedulesPage, ScheduleCard;

Map<String, dynamic> _json(
  int n, {
  Map<String, dynamic>? cancellation,
  Object? company = const {"name": "Barbearia X", "logoUrl": "", "subdomain": "x"},
}) => {
  "_id": "s$n",
  "companyId": "c1",
  "startsAt": "2030-11-${10 + n}T17:00:00.000Z",
  "endsAt": "2030-11-${10 + n}T17:30:00.000Z",
  "state": "scheduled",
  "typeId": "t1",
  "employeeId": "e1",
  "typeDetail": {"_id": "t1", "name": "Corte", "priceAsNumber": 40},
  "employeeDetail": {"_id": "e1", "name": "João"},
  "companyDetail": ?company,
  "cancellation": ?cancellation,
};

class _FakeAuth implements IAuthService {
  bool logged = true;

  @override
  bool get isLoggedIn => logged;

  @override
  bool get isAnonymous => false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeCompanyService implements ICompanyService {
  final calls = <({SchedulePeriod period, bool canceled, int page})>[];
  ApiResponse<List<Schedule>?>? response;
  List<Schedule> Function(int page, SchedulePeriod period)? pages;

  @override
  Future<ApiResponse<List<Schedule>?>> getClientSchedules({
    String? companyId,
    SchedulePeriod period = SchedulePeriod.upcoming,
    bool includeCanceled = false,
    int page = 1,
    int limit = 20,
  }) async {
    calls.add((period: period, canceled: includeCanceled, page: page));
    return response ?? ApiResponse.result(data: pages?.call(page, period) ?? []);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeHttp implements IHttpClient {
  String? endpoint;

  @override
  Future<ApiResponse<T?>> get<T>({
    required String endpoint,
    Map<String, String>? headers,
    Duration? timeout,
    T? Function(dynamic)? parser,
  }) async {
    this.endpoint = endpoint;
    return ApiResponse.result(data: null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeOwnerSession implements IOwnerSessionService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group("Schedule.fromJson", () {
    test("lê empresa e cancelamento", () {
      final s = Schedule.fromJson(
        _json(
          1,
          cancellation: {
            "canceledBy": "company",
            "canceledAt": "2030-11-01T12:00:00.000Z",
            "reason": "Imprevisto",
          },
        ),
      );

      expect(s.companyDetail?.name, "Barbearia X");
      expect(s.isCanceled, isTrue);
      expect(s.cancellation?.canceledBy, CancellationOrigin.company);
      expect(s.cancellation?.reason, "Imprevisto");
    });

    test("empresa apagada (null) e sem cancelamento", () {
      final s = Schedule.fromJson(_json(1, company: null)..["companyDetail"] = null);

      expect(s.companyDetail, isNull);
      expect(s.isCanceled, isFalse);
    });
  });

  test("getClientSchedules monta a rota e os filtros", () async {
    final http = _FakeHttp();
    final service = CompanyConfigService(http, _FakeOwnerSession());

    await service.getClientSchedules(
      period: SchedulePeriod.past,
      includeCanceled: true,
      page: 2,
      limit: 10,
    );
    expect(
      http.endpoint,
      "/schedules/me?period=past&includeCanceled=true&page=2&limit=10",
    );

    await service.getClientSchedules(companyId: "c1");
    expect(
      http.endpoint,
      "/schedules/c1/me?period=upcoming&includeCanceled=false&page=1&limit=20",
    );
  });

  group("MySchedulesController", () {
    late _FakeCompanyService service;
    late _FakeAuth auth;

    setUp(() {
      service = _FakeCompanyService();
      auth = _FakeAuth();
      Get.put<ICompanyService>(service);
      Get.put<IAuthService>(auth);
    });

    tearDown(Get.reset);

    List<Schedule> page(int n) =>
        List.generate(n, (i) => Schedule.fromJson(_json(i)));

    test("carrega os próximos ao abrir, sem cancelados", () async {
      service.pages = (_, _) => page(2);
      final c = Get.put(MySchedulesController("c1"));
      await pumpEventQueue();

      expect(c.upcoming.items, hasLength(2));
      expect(c.upcoming.hasMore.value, isFalse);
      expect(service.calls.single, (
        period: SchedulePeriod.upcoming,
        canceled: false,
        page: 1,
      ));
      expect(c.history.loaded.value, isFalse);
    });

    test("histórico só carrega na primeira vez e inclui cancelados", () async {
      final c = Get.put(MySchedulesController("c1"));
      await pumpEventQueue();

      c.ensureLoaded(c.history);
      await pumpEventQueue();
      c.ensureLoaded(c.history);
      await pumpEventQueue();

      final calls = service.calls.where((e) => e.period == SchedulePeriod.past);
      expect(calls, hasLength(1));
      expect(calls.single.canceled, isTrue);
    });

    test("pagina enquanto a página vier cheia", () async {
      service.pages = (p, _) => p == 1 ? page(MySchedulesController.pageSize) : page(3);
      final c = Get.put(MySchedulesController("c1"));
      await pumpEventQueue();

      expect(c.upcoming.hasMore.value, isTrue);

      await c.load(c.upcoming, more: true);

      expect(c.upcoming.items, hasLength(MySchedulesController.pageSize + 3));
      expect(c.upcoming.hasMore.value, isFalse);
      expect(service.calls.last.page, 2);
    });

    test("falha mantém os itens e expõe o erro", () async {
      service.pages = (_, _) => page(MySchedulesController.pageSize);
      final c = Get.put(MySchedulesController("c1"));
      await pumpEventQueue();

      service.response = ApiResponse.badRequest(errorDescription: "Falhou");
      await c.load(c.upcoming, more: true);

      expect(c.upcoming.error.value, "Falhou");
      expect(c.upcoming.items, hasLength(MySchedulesController.pageSize));
      expect(c.upcoming.hasMore.value, isTrue);
    });

    test("sem login não consulta a API", () async {
      auth.logged = false;
      Get.put(MySchedulesController("c1"));
      await pumpEventQueue();

      expect(service.calls, isEmpty);
    });
  });

  group("MySchedulesPage", () {
    late _FakeCompanyService service;

    setUp(() {
      service = _FakeCompanyService();
      Get.put<ICompanyService>(service);
      Get.put<IAuthService>(_FakeAuth());
    });

    tearDown(Get.reset);

    Future<void> pumpPage(WidgetTester tester) async {
      Get.put(MySchedulesController("c1"));
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: rootNavigatorKey,
          theme: appTheme,
          home: const MySchedulesPage(),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets("mostra os próximos e o histórico com cancelamento", (tester) async {
      service.pages = (_, period) => period == SchedulePeriod.upcoming
          ? [Schedule.fromJson(_json(1))]
          : [
              Schedule.fromJson(
                _json(2, cancellation: {
                  "canceledBy": "company",
                  "canceledAt": "2030-11-01T12:00:00.000Z",
                  "reason": "Imprevisto",
                }),
              ),
            ];
      await pumpPage(tester);

      expect(find.text("Barbearia X"), findsOneWidget);
      expect(find.text("Corte"), findsOneWidget);
      expect(find.text("João"), findsOneWidget);
      expect(find.byType(ScheduleCard), findsOneWidget);

      await tester.tap(find.text("Histórico"));
      await tester.pumpAndSettle();

      expect(find.text("Cancelado pelo estabelecimento"), findsOneWidget);
      expect(find.text("Motivo: Imprevisto"), findsOneWidget);
    });

    testWidgets("estado vazio e erro com nova tentativa", (tester) async {
      service.response = ApiResponse.badRequest(errorDescription: "Sem conexão");
      await pumpPage(tester);

      expect(find.text("Sem conexão"), findsOneWidget);

      service.response = null;
      await tester.tap(find.text("Tentar novamente"));
      await tester.pumpAndSettle();

      expect(find.text("Nenhum agendamento por vir"), findsOneWidget);
    });
  });
}
