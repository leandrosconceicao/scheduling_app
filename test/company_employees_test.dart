import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:scheduling_app/src/core/core.dart';
import 'package:scheduling_app/src/domain/domain.dart';
import 'package:scheduling_app/src/shared/shared.dart';
import 'package:scheduling_app/src/view/view.dart'
    show CompanyConfigurationEmployees, CompanyEmployeesController;

Employee _employee(String id, String name, {num rating = 5}) {
  return Employee.fromJson({
    "_id": id,
    "name": name,
    "profilePhotoUrl": "",
    "companyId": "c1",
    "rating": rating,
    "updatedAt": "2026-10-28T14:30:00.000Z",
  });
}

class _FakeCompanyService implements ICompanyService {
  List<Employee> stored = [];
  ApiResponse<List<Employee>?>? listResponse;
  ApiResponse<Employee?>? saveResponse;
  ApiResponse<dynamic>? removeResponse;
  Completer<void>? listGate;
  String? removedId;
  String? updatedName;
  ({String id, String contentType, int size})? uploaded;
  ApiResponse<Employee?>? uploadResponse;

  @override
  Future<ApiResponse<List<Employee>?>> getCompanyEmployees(String id) async {
    await listGate?.future;
    return listResponse ?? ApiResponse.result(data: stored);
  }

  @override
  Future<ApiResponse<Employee?>> addEmployee(
    String companyId,
    Employee employee,
  ) async {
    uploadedName["new"] = employee.name;
    return saveResponse ??
        ApiResponse.result(
          data: Employee.fromJson({
            "_id": "new",
            "name": employee.name,
            "profilePhotoUrl": "",
            "companyId": companyId,
            "rating": 5,
          }),
        );
  }

  @override
  Future<ApiResponse<Employee?>> uploadEmployeePhoto(
    String companyId,
    String employeeId, {
    required Uint8List bytes,
    required String filename,
    required String contentType,
  }) async {
    uploaded = (id: employeeId, contentType: contentType, size: bytes.length);
    return uploadResponse ??
        ApiResponse.result(
          data: Employee.fromJson({
            "_id": employeeId,
            "name": uploadedName[employeeId] ?? "",
            "profilePhotoUrl": "https://cdn.test/$employeeId.webp",
            "companyId": companyId,
            "rating": 5,
          }),
        );
  }

  final uploadedName = <String, String>{};

  @override
  Future<ApiResponse<Employee?>> updateEmployee(
    String companyId,
    String employeeId, {
    String? name,
  }) async {
    updatedName = name;
    uploadedName[employeeId] = name ?? "";
    return saveResponse ??
        ApiResponse.result(
          data: Employee.fromJson({
            "_id": employeeId,
            "name": name,
            "profilePhotoUrl": "",
            "companyId": companyId,
            "rating": 5,
          }),
        );
  }

  @override
  Future<ApiResponse<dynamic>> removeEmployee(
    String companyId,
    String employeeId,
  ) async {
    removedId = employeeId;
    return removeResponse ?? ApiResponse.success();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

PickedImage _photo({int size = 10}) => PickedImage(
  bytes: Uint8List(size),
  name: "foto.png",
  contentType: "image/png",
);

List<Employee> _seed() => [
  _employee("1", "Rafael Souza", rating: 4.8),
  _employee("2", "Anderson Lima", rating: 4.9),
  _employee("3", "Gustavo Alves", rating: 0),
];

void main() {
  late _FakeCompanyService service;

  setUp(() {
    service = _FakeCompanyService()..stored = _seed();
    Get.put<ICompanyService>(service);
  });

  tearDown(Get.reset);

  group("CompanyEmployeesController", () {
    late CompanyEmployeesController controller;

    Future<void> loaded() async {
      controller = Get.put(CompanyEmployeesController("c1"));
      await pumpEventQueue();
    }

    test("carrega em ordem alfabética", () async {
      await loaded();

      expect(controller.loading.value, isFalse);
      expect(controller.employees.map((e) => e.name), [
        "Anderson Lima",
        "Gustavo Alves",
        "Rafael Souza",
      ]);
    });

    test("expõe o erro de carregamento", () async {
      service.listResponse = ApiResponse.badRequest(errorDescription: "Falhou");

      await loaded();

      expect(controller.loadError.value, "Falhou");
      expect(controller.employees, isEmpty);
    });

    test("a busca ignora acentos e maiúsculas", () async {
      service.stored = [_employee("9", "José Antônio")];
      await loaded();

      controller.searchController.text = "JOSE ANTONIO";

      expect(controller.visibleEmployees.map((e) => e.name), ["José Antônio"]);
    });

    test("a busca só aparece com mais de 5 barbeiros", () async {
      await loaded();
      expect(controller.showSearch, isFalse);

      controller.employees.addAll([
        _employee("a", "A"),
        _employee("b", "B"),
        _employee("c", "C"),
      ]);
      expect(controller.showSearch, isTrue);
    });

    test("valida o nome, inclusive duplicado sem diferenciar acento", () async {
      await loaded();

      expect(controller.validateName("  "), "Informe o nome do barbeiro");
      expect(controller.validateName("A"), "Use pelo menos 2 caracteres");
      expect(
        controller.validateName(" anderson lima "),
        "Já existe um barbeiro com esse nome",
      );
      expect(controller.validateName("Anderson Lima", editingId: "2"), isNull);
      expect(controller.validateName("Diego Martins"), isNull);
    });

    test("reconhece o tipo da imagem só para JPEG, PNG e WebP", () {
      expect(PickedImage.contentTypeOf("a.JPG"), "image/jpeg");
      expect(PickedImage.contentTypeOf("a.jpeg"), "image/jpeg");
      expect(PickedImage.contentTypeOf("a.png"), "image/png");
      expect(PickedImage.contentTypeOf("a.webp"), "image/webp");
      expect(PickedImage.contentTypeOf("a.gif"), isNull);
      expect(PickedImage.contentTypeOf("semextensao"), isNull);
    });

    test("criar insere na ordem, limpa a busca e destaca", () async {
      await loaded();
      controller.searchController.text = "rafael";

      final res = await controller.create(" Bruno ");

      expect(res.result, isTrue);
      expect(controller.query.value, isEmpty);
      expect(controller.employees.map((e) => e.name), [
        "Anderson Lima",
        "Bruno",
        "Gustavo Alves",
        "Rafael Souza",
      ]);
      expect(controller.highlightedId.value, "new");
      controller.onClose();
    });

    test("falha ao salvar não altera a lista", () async {
      await loaded();
      service.saveResponse = ApiResponse.badRequest(errorDescription: "Erro");

      final res = await controller.create("Bruno");

      expect(res.result, isFalse);
      expect(controller.employees, hasLength(3));
    });

    test("editar o nome reordena e não envia foto", () async {
      await loaded();

      await controller.edit(controller.employees.first, "Zeca");

      expect(service.updatedName, "Zeca");
      expect(service.uploaded, isNull);
      expect(controller.employees.last.name, "Zeca");
      controller.onClose();
    });

    test("editar só a foto não chama a API de nome", () async {
      await loaded();
      final first = controller.employees.first;

      final res = await controller.edit(first, first.name, photo: _photo());

      expect(res.result, isTrue);
      expect(service.updatedName, isNull);
      expect(service.uploaded?.id, first.id);
      expect(service.uploaded?.contentType, "image/png");
      expect(
        res.employee?.profilePhotoUrl,
        "https://cdn.test/${first.id}.webp",
      );
      controller.onClose();
    });

    test("criar com foto envia a foto depois de salvar", () async {
      await loaded();

      final res = await controller.create("Bruno", photo: _photo());

      expect(res.result, isTrue);
      expect(res.photoError, isNull);
      expect(service.uploaded?.id, "new");
      expect(controller.employees.map((e) => e.id), contains("new"));
      controller.onClose();
    });

    test("falha na foto mantém o barbeiro salvo e informa o erro", () async {
      await loaded();
      service.uploadResponse = ApiResponse.badRequest(
        errorDescription: "Arquivo enviado não é uma imagem válida",
      );

      final res = await controller.create("Bruno", photo: _photo());

      expect(res.result, isTrue);
      expect(res.photoError, "Arquivo enviado não é uma imagem válida");
      expect(controller.employees.map((e) => e.name), contains("Bruno"));
      controller.onClose();
    });

    test("excluir só remove da lista quando a API confirma", () async {
      await loaded();
      service.removeResponse = ApiResponse.badRequest();

      await controller.remove(controller.employees.first);
      expect(controller.employees, hasLength(3));
      expect(controller.deletingId.value, isNull);

      service.removeResponse = null;
      await controller.remove(controller.employees.first);
      expect(controller.employees, hasLength(2));
      expect(service.removedId, "2");
    });
  });

  group("Employee.copyWith", () {
    test("troca o nome preservando o resto", () {
      final copy = _employee("1", "Rafael", rating: 4.8).copyWith(name: "Rafa");

      expect(copy.id, "1");
      expect(copy.name, "Rafa");
      expect(copy.rating, 4.8);
      expect(copy.updatedAt, isNotNull);
    });
  });

  group("EmployeeAvatar.initialsOf", () {
    test("usa as duas primeiras palavras", () {
      expect(EmployeeAvatar.initialsOf("anderson lima"), "AL");
      expect(EmployeeAvatar.initialsOf("  Rafael  "), "R");
      expect(EmployeeAvatar.initialsOf("Ana Maria Souza"), "AM");
      expect(EmployeeAvatar.initialsOf(""), "");
    });
  });

  group("CompanyConfigurationEmployees", () {
    Future<void> pumpPage(
      WidgetTester tester, {
      Size size = const Size(390, 844),
      bool settle = true,
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      Get.put(CompanyEmployeesController("c1"));

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: rootNavigatorKey,
          scaffoldMessengerKey: scaffoldMessengerKey,
          home: const CompanyConfigurationEmployees(),
        ),
      );

      if (settle) await tester.pumpAndSettle();
    }

    // O destaque do item salvo usa um Timer, cancelado ao fechar o controller.
    Future<void> finish(WidgetTester tester) async {
      Get.find<CompanyEmployeesController>().onClose();
      await tester.pump(const Duration(seconds: 5));
    }

    testWidgets("lista os barbeiros com avaliação e ações", (tester) async {
      await pumpPage(tester);

      expect(find.text("Anderson Lima"), findsOneWidget);
      expect(find.text("3 barbeiros"), findsOneWidget);
      expect(find.text("4.9"), findsOneWidget);
      expect(find.text("Sem avaliações"), findsOneWidget);
      expect(find.byTooltip("Editar Anderson Lima"), findsOneWidget);
      expect(find.byTooltip("Excluir Anderson Lima"), findsOneWidget);
      expect(find.text("Novo barbeiro"), findsOneWidget);
      expect(find.text("Buscar barbeiro"), findsNothing);
    });

    testWidgets("na web mostra a tabela sem estourar", (tester) async {
      await pumpPage(tester, size: const Size(1280, 800));

      expect(find.text("Atualizado em"), findsOneWidget);
      expect(find.text("Avaliação"), findsOneWidget);
      expect(find.text("Anderson Lima"), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets("mostra carregamento e depois o estado vazio", (tester) async {
      service
        ..stored = []
        ..listGate = Completer();

      await pumpPage(tester, settle: false);
      await tester.pump();

      expect(find.text("Carregando…"), findsOneWidget);
      expect(find.text("Novo barbeiro"), findsNothing);

      service.listGate!.complete();
      await tester.pumpAndSettle();

      expect(find.text("Nenhum barbeiro cadastrado"), findsOneWidget);
      expect(find.text("Novo barbeiro"), findsOneWidget);
    });

    testWidgets("erro ao carregar permite tentar novamente", (tester) async {
      service.listResponse = ApiResponse.badRequest(errorDescription: "Falhou");

      await pumpPage(tester);

      expect(find.text("Falhou"), findsOneWidget);
      expect(find.text("Novo barbeiro"), findsNothing);

      service.listResponse = null;
      await tester.tap(find.text("Tentar novamente"));
      await tester.pumpAndSettle();

      expect(find.text("Anderson Lima"), findsOneWidget);
    });

    testWidgets("formulário valida o nome e cria com a foto", (tester) async {
      await pumpPage(tester);
      Get.find<CompanyEmployeesController>().photoPicker = () async => _photo();

      await tester.tap(find.text("Novo barbeiro"));
      await tester.pumpAndSettle();

      await tester.tap(find.text("Salvar"));
      await tester.pumpAndSettle();
      expect(find.text("Informe o nome do barbeiro"), findsOneWidget);
      expect(find.text("Informe o endereço da foto"), findsNothing);

      await tester.tap(find.text("Adicionar foto"));
      await tester.pumpAndSettle();
      expect(find.text("Trocar foto"), findsOneWidget);

      await tester.enterText(find.byType(TextFormField), "Bruno");
      await tester.tap(find.text("Salvar"));
      await tester.pumpAndSettle();

      expect(service.uploaded?.id, "new");
      expect(find.text("Barbeiro “Bruno” adicionado"), findsOneWidget);

      await finish(tester);
    });

    testWidgets("imagem acima de 2 MB é recusada no formulário", (
      tester,
    ) async {
      await pumpPage(tester);
      Get.find<CompanyEmployeesController>().photoPicker = () async =>
          _photo(size: PickedImage.maxBytes + 1);

      await tester.tap(find.text("Novo barbeiro"));
      await tester.pumpAndSettle();
      await tester.tap(find.text("Adicionar foto"));
      await tester.pumpAndSettle();

      expect(find.text("A imagem deve ter no máximo 2 MB."), findsOneWidget);
      expect(find.text("Adicionar foto"), findsOneWidget);
    });

    testWidgets("formato inválido mostra o erro do seletor", (tester) async {
      await pumpPage(tester);
      Get.find<CompanyEmployeesController>().photoPicker = () async =>
          throw const FormatException("Escolha uma imagem JPEG, PNG ou WebP");

      await tester.tap(find.text("Novo barbeiro"));
      await tester.pumpAndSettle();
      await tester.tap(find.text("Adicionar foto"));
      await tester.pumpAndSettle();

      expect(find.text("Escolha uma imagem JPEG, PNG ou WebP"), findsOneWidget);
    });

    testWidgets("foto que falha avisa mas mantém o barbeiro", (tester) async {
      service.uploadResponse = ApiResponse.badRequest(errorDescription: "Ruim");
      await pumpPage(tester);
      Get.find<CompanyEmployeesController>().photoPicker = () async => _photo();

      await tester.tap(find.text("Novo barbeiro"));
      await tester.pumpAndSettle();
      await tester.tap(find.text("Adicionar foto"));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), "Bruno");
      await tester.tap(find.text("Salvar"));
      await tester.pumpAndSettle();

      expect(
        find.text(
          "Barbeiro “Bruno” adicionado, mas a foto não foi enviada: Ruim",
        ),
        findsOneWidget,
      );
      expect(find.text("Bruno"), findsOneWidget);

      await finish(tester);
    });

    testWidgets("falha ao salvar mantém o formulário aberto", (tester) async {
      service.saveResponse = ApiResponse.badRequest(
        errorDescription: "Barbeiro duplicado",
      );
      await pumpPage(tester);

      await tester.tap(find.byTooltip("Editar Anderson Lima"));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), "Anderson Novo");
      await tester.tap(find.text("Salvar"));
      await tester.pumpAndSettle();

      expect(find.text("Barbeiro duplicado"), findsOneWidget);
      expect(find.text("Salvar"), findsOneWidget);
    });

    testWidgets("cancelar com alterações pede confirmação", (tester) async {
      await pumpPage(tester);

      await tester.tap(find.byTooltip("Editar Anderson Lima"));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), "Anderson Novo");
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
      expect(find.text("Anderson Lima"), findsOneWidget);
    });

    testWidgets("cancelar sem alterações fecha direto", (tester) async {
      await pumpPage(tester);

      await tester.tap(find.byTooltip("Editar Anderson Lima"));
      await tester.pumpAndSettle();
      await tester.tap(find.text("Cancelar"));
      await tester.pumpAndSettle();

      expect(find.text("Descartar alterações?"), findsNothing);
      expect(find.text("Salvar"), findsNothing);
    });

    testWidgets("excluir exige confirmação", (tester) async {
      await pumpPage(tester);

      await tester.tap(find.byTooltip("Excluir Anderson Lima"));
      await tester.pumpAndSettle();
      await tester.tap(find.text("Cancelar"));
      await tester.pumpAndSettle();
      expect(service.removedId, isNull);

      await tester.tap(find.byTooltip("Excluir Anderson Lima"));
      await tester.pumpAndSettle();
      await tester.tap(find.text("Excluir"));
      await tester.pumpAndSettle();

      expect(service.removedId, "2");
      expect(find.text("Anderson Lima"), findsNothing);
      expect(find.text("Barbeiro “Anderson Lima” excluído"), findsOneWidget);

      await finish(tester);
    });
  });
}
