import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ltech_core/ltech_core.dart' show ApiResponse, IHttpClient;
import 'package:scheduling_app/src/application/application.dart';
import 'package:scheduling_app/src/core/core.dart';
import 'package:scheduling_app/src/domain/domain.dart';
import 'package:scheduling_app/src/view/view.dart'
    show OwnerSchedulesController, OwnerSchedulesPage, AppointmentFilter;

Map<String, dynamic> _json(
  String id, {
  String state = "scheduled",
  DateTime? startsAt,
  Map<String, dynamic>? cancellation,
}) {
  final start = (startsAt ?? DateTime.now().add(const Duration(hours: 3)))
      .toUtc();
  return {
    "_id": id,
    "companyId": "c1",
    "startsAt": start.toIso8601String(),
    "endsAt": start.add(const Duration(minutes: 30)).toIso8601String(),
    "state": state,
    "typeId": "t1",
    "employeeId": "e1",
    "client": {"uid": "u$id", "name": "Cliente $id", "phoneNumber": "+5581999999999"},
    "typeDetail": {"_id": "t1", "name": "Corte", "priceAsNumber": 40},
    "employeeDetail": {"_id": "e1", "name": "João"},
    "cancellation": ?cancellation,
  };
}

class _FakeOwnerSession implements IOwnerSessionService {
  bool ended = false;

  @override
  String get token => "owner-token";

  @override
  Future<void> end() async => ended = true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _RecordingHttp implements IHttpClient {
  String? method;
  String? endpoint;
  Object? body;
  Map<String, String>? headers;

  ApiResponse<T?> _rec<T>(String m, String e, Map<String, String>? h, [Object? b]) {
    method = m;
    endpoint = e;
    headers = h;
    body = b;
    return ApiResponse.result(data: null);
  }

  @override
  Future<ApiResponse<T?>> get<T>({
    required String endpoint,
    Map<String, String>? headers,
    Duration? timeout,
    T? Function(dynamic)? parser,
  }) async => _rec("GET", endpoint, headers);

  @override
  Future<ApiResponse<T?>> patch<T>({
    required String endpoint,
    Map<String, String>? headers,
    Duration? timeout,
    Object? requestBody,
    T Function(dynamic)? parser,
  }) async => _rec("PATCH", endpoint, headers, requestBody);

  @override
  Future<ApiResponse<T?>> delete<T>({
    required String endpoint,
    Map<String, String>? headers,
    Duration? timeout,
    Object? requestBody,
    T Function(dynamic)? parser,
  }) async => _rec("DELETE", endpoint, headers, requestBody);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeOwnerSchedules implements IOwnerScheduleService {
  final calls = <Map<String, Object?>>[];
  List<Schedule> items = [];
  ApiResponse? failure;
  final completed = <String>[];
  final canceled = <String, String>{};

  @override
  Future<ApiResponse<List<Schedule>?>> getAppointments(
    String companyId, {
    DateTime? from,
    DateTime? to,
    String? employeeId,
    Set<ScheduleState> states = const {},
    String? search,
    bool descending = false,
    int page = 1,
    int limit = 100,
  }) async {
    calls.add({
      "from": from,
      "to": to,
      "employeeId": employeeId,
      "states": states,
      "search": search,
      "descending": descending,
      "page": page,
    });
    if (failure != null) return ApiResponse.badRequest(errorDescription: "Falhou");
    return ApiResponse.result(data: items);
  }

  @override
  Future<ApiResponse<Schedule?>> completeAppointment(String companyId, String id) async {
    completed.add(id);
    return ApiResponse.result(data: null);
  }

  @override
  Future<ApiResponse> cancelAppointment(String companyId, String id, String reason) async {
    canceled[id] = reason;
    return ApiResponse.success();
  }
}

class _FakeCompany implements ICompanyService {
  @override
  Future<ApiResponse<List<Employee>?>> getCompanyEmployees(String companyId) async =>
      ApiResponse.result(
        data: [
          Employee.fromJson({"_id": "e1", "name": "João"}),
          Employee.fromJson({"_id": "e2", "name": "Pedro"}),
        ],
      );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group("ScheduleState", () {
    test("conhece concluído e cancelado; estado desconhecido vira open", () {
      expect(ScheduleState.parse("completed"), ScheduleState.completed);
      expect(ScheduleState.parse("canceled"), ScheduleState.canceled);
      expect(ScheduleState.parse("xyz"), ScheduleState.open);
      expect(Schedule.fromJson(_json("a", state: "canceled")).isCanceled, isTrue);
      expect(Schedule.fromJson(_json("a", state: "completed")).isCompleted, isTrue);
    });
  });

  group("OwnerScheduleService", () {
    late _RecordingHttp http;
    late OwnerScheduleService service;

    setUp(() {
      http = _RecordingHttp();
      service = OwnerScheduleService(http, _FakeOwnerSession());
    });

    test("lista com filtros, token do dono e datas em UTC", () async {
      await service.getAppointments(
        "c1",
        from: DateTime.utc(2030, 1, 1),
        to: DateTime.utc(2030, 1, 2),
        employeeId: "e1",
        states: {ScheduleState.scheduled, ScheduleState.canceled},
        search: " ana ",
        descending: true,
        page: 2,
        limit: 10,
      );

      final uri = Uri.parse(http.endpoint!);
      expect(uri.path, "/company/c1/appointments");
      expect(uri.queryParameters, {
        "from": "2030-01-01T00:00:00.000Z",
        "to": "2030-01-02T00:00:00.000Z",
        "employeeId": "e1",
        "state": "scheduled,canceled",
        "search": "ana",
        "order": "desc",
        "page": "2",
        "limit": "10",
      });
      expect(http.headers, {"authorization": "Bearer owner-token"});
    });

    test("sem filtros opcionais, só ordem e paginação", () async {
      await service.getAppointments("c1");

      expect(Uri.parse(http.endpoint!).queryParameters, {
        "order": "asc",
        "page": "1",
        "limit": "100",
      });
    });

    test("concluir faz PATCH com o estado completed", () async {
      await service.completeAppointment("c1", "s1");

      expect(http.method, "PATCH");
      expect(http.endpoint, "/company/c1/appointments/s1");
      expect(http.body, {"state": "completed"});
    });

    test("cancelar faz DELETE com o motivo", () async {
      await service.cancelAppointment("c1", "s1", "Imprevisto");

      expect(http.method, "DELETE");
      expect(http.endpoint, "/company/c1/schedules/s1");
      expect(http.body, {"reason": "Imprevisto"});
    });
  });

  group("OwnerSchedulesController", () {
    late _FakeOwnerSchedules service;

    setUp(() {
      service = _FakeOwnerSchedules();
      Get.put<IOwnerScheduleService>(service);
      Get.put<ICompanyService>(_FakeCompany());
    });

    tearDown(Get.reset);

    test("carrega o dia de hoje (00:00 a 23:59) com agendados e concluídos", () async {
      service.items = [Schedule.fromJson(_json("a"))];
      final c = Get.put(OwnerSchedulesController("c1"));
      await pumpEventQueue();

      final call = service.calls.single;
      final from = call["from"] as DateTime;
      final to = call["to"] as DateTime;
      final now = DateTime.now();

      expect(from, DateTime(now.year, now.month, now.day));
      expect(to.hour, 23);
      expect(call["states"], AppointmentFilter.active.states);
      expect(c.items, hasLength(1));
      expect(c.employees, hasLength(2));
    });

    test("trocar de dia e de filtro recarrega", () async {
      final c = Get.put(OwnerSchedulesController("c1"));
      await pumpEventQueue();

      c.shiftDay(1);
      await pumpEventQueue();
      c.setFilter(AppointmentFilter.canceled);
      await pumpEventQueue();
      c.setEmployee("e2");
      await pumpEventQueue();

      final last = service.calls.last;
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      expect((last["from"] as DateTime).day, tomorrow.day);
      expect(last["states"], {ScheduleState.canceled});
      expect(last["employeeId"], "e2");
      expect(service.calls, hasLength(4));
    });

    test("busca ignora o dia e ordena do mais recente ao mais antigo", () async {
      final c = Get.put(OwnerSchedulesController("c1"));
      await pumpEventQueue();

      c.search("maria");
      await pumpEventQueue();

      final call = service.calls.last;
      expect(call["from"], isNull);
      expect(call["to"], isNull);
      expect(call["search"], "maria");
      expect(call["descending"], isTrue);
    });

    test("falha expõe o erro", () async {
      service.failure = ApiResponse.badRequest();
      final c = Get.put(OwnerSchedulesController("c1"));
      await pumpEventQueue();

      expect(c.error.value, "Falhou");
      expect(c.items, isEmpty);
    });

    test("só conclui o que já começou e só cancela o que ainda vai ocorrer", () async {
      final c = Get.put(OwnerSchedulesController("c1"));
      final past = Schedule.fromJson(
        _json("p", startsAt: DateTime.now().subtract(const Duration(hours: 1))),
      );
      final future = Schedule.fromJson(_json("f"));
      final done = Schedule.fromJson(
        _json("d", state: "completed", startsAt: DateTime.now().subtract(const Duration(hours: 1))),
      );
      final canceled = Schedule.fromJson(_json("c", state: "canceled"));

      expect(c.canComplete(past), isTrue);
      expect(c.canComplete(future), isFalse);
      expect(c.canCancel(future), isTrue);
      expect(c.canCancel(past), isFalse);
      expect(c.canComplete(done), isFalse);
      expect(c.canCancel(canceled), isFalse);
    });

    test("concluir e cancelar chamam o serviço e recarregam", () async {
      final c = Get.put(OwnerSchedulesController("c1"));
      await pumpEventQueue();
      final before = service.calls.length;

      expect(await c.complete(Schedule.fromJson(_json("a"))), isTrue);
      expect(await c.cancel(Schedule.fromJson(_json("b")), "Motivo"), isTrue);

      expect(service.completed, ["a"]);
      expect(service.canceled, {"b": "Motivo"});
      expect(service.calls.length, before + 2);
    });
  });

  group("OwnerSchedulesPage", () {
    late _FakeOwnerSchedules service;

    setUp(() {
      service = _FakeOwnerSchedules();
      Get.put<IOwnerScheduleService>(service);
      Get.put<ICompanyService>(_FakeCompany());
    });

    tearDown(Get.reset);

    Future<void> pump(WidgetTester tester) async {
      Get.put(OwnerSchedulesController("c1"));
      await tester.pumpWidget(
        MaterialApp(
          scaffoldMessengerKey: scaffoldMessengerKey,
          home: const OwnerSchedulesPage(),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets("mostra os agendamentos com status", (tester) async {
      service.items = [
        Schedule.fromJson(_json("a")),
        Schedule.fromJson(_json("b", state: "canceled")),
      ];
      await pump(tester);

      expect(find.text("Cliente a"), findsOneWidget);
      expect(find.text("Agendado"), findsOneWidget);
      expect(find.text("Cancelado"), findsWidgets);
    });

    testWidgets("sair encerra a sessão do dono", (tester) async {
      final session = _FakeOwnerSession();
      Get.put<IOwnerSessionService>(session);
      await pump(tester);

      await tester.tap(find.byTooltip("Sair da área administrativa"));
      await tester.pump();

      expect(session.ended, isTrue);
    });

    testWidgets("dia vazio mostra mensagem", (tester) async {
      await pump(tester);

      expect(find.text("Nenhum agendamento neste dia"), findsOneWidget);
    });

    testWidgets("cancelar exige o motivo", (tester) async {
      service.items = [Schedule.fromJson(_json("a"))];
      await pump(tester);

      await tester.tap(find.text("Cliente a"));
      await tester.pumpAndSettle();
      await tester.tap(find.text("Cancelar"));
      await tester.pumpAndSettle();

      await tester.tap(find.text("Cancelar agendamento").last);
      await tester.pumpAndSettle();
      expect(find.text("Informe o motivo do cancelamento"), findsOneWidget);
      expect(service.canceled, isEmpty);

      await tester.enterText(find.byType(TextField).last, "Barbeiro doente");
      await tester.tap(find.text("Cancelar agendamento").last);
      await tester.pumpAndSettle();

      expect(service.canceled, {"a": "Barbeiro doente"});
    });

    testWidgets("concluir aparece só para agendamento já iniciado", (tester) async {
      service.items = [
        Schedule.fromJson(
          _json("p", startsAt: DateTime.now().subtract(const Duration(hours: 1))),
        ),
      ];
      await pump(tester);

      await tester.tap(find.text("Cliente p"));
      await tester.pumpAndSettle();
      expect(find.text("Cancelar"), findsNothing);

      await tester.tap(find.text("Concluir"));
      await tester.pumpAndSettle();

      expect(service.completed, ["p"]);
    });
  });
}
