import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:scheduling_app/src/core/core.dart';
import 'package:scheduling_app/src/domain/domain.dart';
import 'package:scheduling_app/src/shared/shared.dart';
import 'package:scheduling_app/src/view/view.dart'
    show CompanyConfigurationServices, CompanyServicesController;

class _FakeCompanyService implements ICompanyService {
  List<ScheduleType> stored = [];
  ApiResponse<List<ScheduleType>?>? listResponse;
  ApiResponse<ScheduleType?>? saveResponse;
  ApiResponse<dynamic>? removeResponse;
  Completer<void>? listGate;
  String? removedId;
  ({String? name, num? price})? updated;

  @override
  Future<ApiResponse<Company?>> getCompany(String id) async {
    return ApiResponse.notFound();
  }

  @override
  Future<ApiResponse<List<ScheduleType>?>> getScheduleTypes(String id) async {
    await listGate?.future;
    return listResponse ?? ApiResponse.result(data: stored);
  }

  @override
  Future<ApiResponse<ScheduleType?>> addNewScheduleType(
    String companyId,
    ScheduleType type,
  ) async {
    return saveResponse ??
        ApiResponse.result(
          data: ScheduleType(companyId, type.name, type.price, id: "new"),
        );
  }

  @override
  Future<ApiResponse<ScheduleType?>> updateScheduleType(
    String companyId,
    String typeId, {
    String? name,
    num? price,
  }) async {
    updated = (name: name, price: price);
    return saveResponse ??
        ApiResponse.result(
          data: ScheduleType(companyId, name ?? "", price ?? 0, id: typeId),
        );
  }

  @override
  Future<ApiResponse<dynamic>> removeScheduleType(
    String companyId,
    String typeId,
  ) async {
    removedId = typeId;
    return removeResponse ?? ApiResponse.success();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

List<ScheduleType> _seed() => [
  ScheduleType("c1", "Sobrancelha", 15, id: "1"),
  ScheduleType("c1", "Barba", 35, id: "2"),
  ScheduleType("c1", "Hidratação", 40, id: "3"),
];

void main() {
  late _FakeCompanyService service;

  setUp(() {
    service = _FakeCompanyService()..stored = _seed();
    Get.put<ICompanyService>(service);
  });

  tearDown(Get.reset);

  group("CompanyServicesController", () {
    late CompanyServicesController controller;

    Future<void> loaded() async {
      controller = Get.put(CompanyServicesController("c1"));
      await pumpEventQueue();
    }

    test("carrega em ordem alfabética", () async {
      await loaded();

      expect(controller.loading.value, isFalse);
      expect(controller.types.map((e) => e.name), [
        "Barba",
        "Hidratação",
        "Sobrancelha",
      ]);
    });

    test("expõe o erro de carregamento", () async {
      service.listResponse = ApiResponse.badRequest(errorDescription: "Falhou");

      await loaded();

      expect(controller.loadError.value, "Falhou");
      expect(controller.types, isEmpty);
    });

    test("a busca ignora acentos e maiúsculas", () async {
      await loaded();

      controller.searchController.text = "HIDRATACAO";

      expect(controller.visibleTypes.map((e) => e.name), ["Hidratação"]);
    });

    test("a busca só aparece com mais de 5 serviços", () async {
      await loaded();
      expect(controller.showSearch, isFalse);

      controller.types.addAll([
        ScheduleType("c1", "A", 1, id: "a"),
        ScheduleType("c1", "B", 1, id: "b"),
        ScheduleType("c1", "C", 1, id: "c"),
      ]);
      expect(controller.showSearch, isTrue);
    });

    test("valida o nome, inclusive duplicado sem diferenciar acento", () async {
      await loaded();

      expect(controller.validateName("  "), "Informe o nome do serviço");
      expect(controller.validateName("A"), "Use pelo menos 2 caracteres");
      expect(
        controller.validateName(" hidratacao "),
        "Já existe um serviço com esse nome",
      );
      expect(controller.validateName("Hidratação", editingId: "3"), isNull);
      expect(controller.validateName("Corte"), isNull);
    });

    test("não aceita preço zerado", () async {
      await loaded();

      expect(controller.validatePrice(0), isNotNull);
      expect(controller.validatePrice(0.01), isNull);
    });

    test("criar insere na ordem, limpa a busca e destaca", () async {
      await loaded();
      controller.searchController.text = "barba";

      final res = await controller.create(" Corte ", 45);

      expect(res.result, isTrue);
      expect(controller.query.value, isEmpty);
      expect(controller.types.map((e) => e.name), [
        "Barba",
        "Corte",
        "Hidratação",
        "Sobrancelha",
      ]);
      expect(controller.highlightedId.value, "new");
      controller.onClose();
    });

    test("falha ao salvar não altera a lista", () async {
      await loaded();
      service.saveResponse = ApiResponse.badRequest(errorDescription: "Erro");

      final res = await controller.create("Corte", 45);

      expect(res.result, isFalse);
      expect(controller.types, hasLength(3));
    });

    test("editar envia os campos e reordena", () async {
      await loaded();

      await controller.edit(controller.types.first, "Zero", 50);

      expect(service.updated?.name, "Zero");
      expect(service.updated?.price, 50);
      expect(controller.types.last.name, "Zero");
      controller.onClose();
    });

    test("excluir só remove da lista quando a API confirma", () async {
      await loaded();
      service.removeResponse = ApiResponse.badRequest();

      await controller.remove(controller.types.first);
      expect(controller.types, hasLength(3));
      expect(controller.deletingId.value, isNull);

      service.removeResponse = null;
      await controller.remove(controller.types.first);
      expect(controller.types.map((e) => e.name), contains("Sobrancelha"));
      expect(controller.types, hasLength(2));
      expect(service.removedId, "2");
    });
  });

  group("CompanyConfigurationServices", () {
    Future<void> pumpPage(
      WidgetTester tester, {
      Size size = const Size(390, 844),
      bool settle = true,
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      Get.put(CompanyServicesController("c1"));

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: rootNavigatorKey,
          scaffoldMessengerKey: scaffoldMessengerKey,
          home: const CompanyConfigurationServices(),
        ),
      );

      if (settle) await tester.pumpAndSettle();
    }

    // O destaque do item salvo usa um Timer, cancelado ao fechar o controller.
    Future<void> finish(WidgetTester tester) async {
      Get.find<CompanyServicesController>().onClose();
      await tester.pump(const Duration(seconds: 5));
    }

    testWidgets("lista os serviços com ações", (tester) async {
      await pumpPage(tester);

      expect(find.text("Barba"), findsOneWidget);
      expect(find.text("3 serviços"), findsOneWidget);
      expect(find.byTooltip("Editar Barba"), findsOneWidget);
      expect(find.byTooltip("Excluir Barba"), findsOneWidget);
      expect(find.text("Novo serviço"), findsOneWidget);
      expect(find.text("Buscar serviço"), findsNothing);
    });

    testWidgets("na web mostra a tabela sem estourar", (tester) async {
      await pumpPage(tester, size: const Size(1280, 800));

      expect(find.text("Atualizado em"), findsOneWidget);
      expect(find.text("Barba"), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets("mostra carregamento e depois o estado vazio", (tester) async {
      service
        ..stored = []
        ..listGate = Completer();

      await pumpPage(tester, settle: false);
      await tester.pump();

      expect(find.text("Carregando…"), findsOneWidget);
      expect(find.text("Novo serviço"), findsNothing);

      service.listGate!.complete();
      await tester.pumpAndSettle();

      expect(find.text("Nenhum serviço cadastrado"), findsOneWidget);
      expect(find.text("Novo serviço"), findsOneWidget);
    });

    testWidgets("erro ao carregar permite tentar novamente", (tester) async {
      service.listResponse = ApiResponse.badRequest(errorDescription: "Falhou");

      await pumpPage(tester);

      expect(find.text("Falhou"), findsOneWidget);
      expect(find.text("Novo serviço"), findsNothing);

      service.listResponse = null;
      await tester.tap(find.text("Tentar novamente"));
      await tester.pumpAndSettle();

      expect(find.text("Barba"), findsOneWidget);
    });

    testWidgets("formulário valida e depois cria o serviço", (tester) async {
      await pumpPage(tester);

      await tester.tap(find.text("Novo serviço"));
      await tester.pumpAndSettle();

      await tester.tap(find.text("Salvar"));
      await tester.pumpAndSettle();

      expect(find.text("Informe o nome do serviço"), findsOneWidget);
      expect(find.text("Informe um valor maior que zero"), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).first, "Corte");
      await tester.enterText(find.byType(TextFormField).last, "4500");
      await tester.pump();

      expect(find.text("R\$ 45,00"), findsOneWidget);

      await tester.tap(find.text("Salvar"));
      await tester.pumpAndSettle();

      expect(find.text("Corte"), findsOneWidget);
      expect(find.text("Salvar"), findsNothing);
      expect(find.text("Serviço “Corte” adicionado"), findsOneWidget);

      await finish(tester);
    });

    testWidgets("falha ao salvar mantém o formulário aberto", (tester) async {
      service.saveResponse = ApiResponse.badRequest(
        errorDescription: "Serviço duplicado",
      );
      await pumpPage(tester);

      await tester.tap(find.byTooltip("Editar Barba"));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, "Barba nova");
      await tester.tap(find.text("Salvar"));
      await tester.pumpAndSettle();

      expect(find.text("Serviço duplicado"), findsOneWidget);
      expect(find.text("Salvar"), findsOneWidget);
    });

    testWidgets("cancelar com alterações pede confirmação", (tester) async {
      await pumpPage(tester);

      await tester.tap(find.byTooltip("Editar Barba"));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).first, "Barba nova");
      await tester.pump();

      await tester.tap(find.text("Cancelar"));
      await tester.pumpAndSettle();
      expect(find.text("Descartar alterações?"), findsOneWidget);

      await tester.tap(find.text("Continuar"));
      await tester.pumpAndSettle();
      expect(find.text("Salvar"), findsOneWidget);

      await tester.tap(find.text("Cancelar"));
      await tester.pumpAndSettle();
      await tester.tap(find.text("Descartar"));
      await tester.pumpAndSettle();

      expect(find.text("Salvar"), findsNothing);
      expect(find.text("Barba"), findsOneWidget);
    });

    testWidgets("cancelar sem alterações fecha direto", (tester) async {
      await pumpPage(tester);

      await tester.tap(find.byTooltip("Editar Barba"));
      await tester.pumpAndSettle();
      await tester.tap(find.text("Cancelar"));
      await tester.pumpAndSettle();

      expect(find.text("Descartar alterações?"), findsNothing);
      expect(find.text("Salvar"), findsNothing);
    });

    testWidgets("excluir exige confirmação", (tester) async {
      await pumpPage(tester);

      await tester.tap(find.byTooltip("Excluir Barba"));
      await tester.pumpAndSettle();
      await tester.tap(find.text("Cancelar"));
      await tester.pumpAndSettle();
      expect(service.removedId, isNull);

      await tester.tap(find.byTooltip("Excluir Barba"));
      await tester.pumpAndSettle();
      await tester.tap(find.text("Excluir"));
      await tester.pumpAndSettle();

      expect(service.removedId, "2");
      expect(find.text("Barba"), findsNothing);
      expect(find.text("Serviço “Barba” excluído"), findsOneWidget);
    });
  });
}
