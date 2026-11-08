import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:scheduling_app/src/application/application.dart';
import 'package:scheduling_app/src/core/core.dart';
import 'package:scheduling_app/src/domain/domain.dart';
import 'package:scheduling_app/src/shared/shared.dart';
import 'package:scheduling_app/src/view/view.dart'
    show CompanyConfigurationController, CompanyConfigurationPage, ConfigSaveResult;

Map<String, dynamic> _companyJson({List<dynamic>? days}) => {
  "_id": "c1",
  "cnpj": "00.000.000/0001-00",
  "name": "Barbearia Exemplo",
  "subdomain": "barbeariaexemplo",
  "address": {
    "zipCode": "01000-000",
    "street": "Rua Exemplo",
    "number": "100",
    "neighborhood": "Centro",
    "city": "São Paulo",
    "state": "SP",
  },
  "configuration": {
    "openingHours": "08:00",
    "closingTime": "18:00",
    "lunchBreak": {"start": "12:00", "end": "13:00"},
    "defaultPeriodInMinutes": 30,
    "lockSchedulePeriodInMinutes": 10,
    "workingDays": ?days,
  },
  "social": {"phone": "1133330000", "whatsapp": "11900000000", "instagram": "@barbearia"},
};

class _FakeCompanyService implements ICompanyService {
  ApiResponse<Company?>? companyResponse;
  ApiResponse<dynamic>? updateResponse;
  Map<String, dynamic>? sent;
  var updates = 0;
  var loads = 0;
  Map<String, dynamic> json = _companyJson();

  @override
  Future<ApiResponse<Company?>> getCompany(String id) async {
    loads++;
    return companyResponse ?? ApiResponse.result(data: Company.fromJson(json));
  }

  @override
  Future<ApiResponse<dynamic>> updateCompany(
    String companyId,
    CompanyDto request,
  ) async {
    updates++;
    sent = request.toJson();
    return updateResponse ?? ApiResponse.success();
  }

  @override
  Future<ApiResponse<Company?>> uploadCompanyLogo(
    String companyId, {
    required Uint8List bytes,
    required String filename,
    required String contentType,
  }) async {
    return ApiResponse.result(
      data: Company.fromJson({...json, "logoUrl": "https://x/logo.png"}),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group("CompanySettings", () {
    final company = Company.fromJson(_companyJson());

    test("monta o rascunho com máscaras", () {
      final d = CompanySettings.draftOf(company, ConfigSection.contato);

      expect(d[CompanySettings.phone], "(11) 3333-0000");
      expect(d[CompanySettings.whatsapp], "(11) 90000-0000");
      expect(d[CompanySettings.instagram], "barbearia");
    });

    test("valida horários de funcionamento", () {
      final d = CompanySettings.draftOf(company, ConfigSection.funcionamento)
        ..[CompanySettings.close] = "07:00"
        ..[CompanySettings.lunchEnd] = "11:00"
        ..[CompanySettings.lock] = "";

      final errors = CompanySettings.errors(
        ConfigSection.funcionamento,
        d,
        workingDays: {1},
      );

      expect(errors[CompanySettings.close], isNotNull);
      expect(errors[CompanySettings.lunchEnd], isNotNull);
      expect(errors[CompanySettings.lock], isNotNull);
      expect(errors.containsKey(CompanySettings.open), isFalse);
    });

    test("exige ao menos um dia de funcionamento", () {
      final d = CompanySettings.draftOf(company, ConfigSection.funcionamento);

      expect(
        CompanySettings.errors(ConfigSection.funcionamento, d)
            .containsKey(CompanySettings.days),
        isTrue,
      );
    });

    test("valida endereço e contato", () {
      expect(
        CompanySettings.errors(ConfigSection.endereco, {
          for (final k in ConfigSection.endereco.keys) k: "",
        }).keys,
        containsAll([
          CompanySettings.zip,
          CompanySettings.street,
          CompanySettings.state,
        ]),
      );

      final contact = CompanySettings.errors(ConfigSection.contato, {
        CompanySettings.phone: "(11) 333",
        CompanySettings.whatsapp: "",
        CompanySettings.email: "x@",
        CompanySettings.instagram: "a b",
        CompanySettings.facebook: "",
      });
      expect(contact.keys, containsAll([
        CompanySettings.phone,
        CompanySettings.email,
        CompanySettings.instagram,
      ]));
    });

    test("calcula quantos horários cabem por dia", () {
      final d = CompanySettings.draftOf(company, ConfigSection.funcionamento);

      // 4 h antes do almoço + 5 h depois, em blocos de 30 min.
      expect(CompanySettings.slotsLabel(d), contains("até 18 horários"));
      expect(
        CompanySettings.slotsLabel({...d, CompanySettings.close: "07:00"}),
        isNull,
      );
    });
  });

  group("CompanyConfigurationController", () {
    late _FakeCompanyService service;
    late CompanyConfigurationController controller;
    var discardAnswer = true;

    setUp(() async {
      service = _FakeCompanyService();
      discardAnswer = true;
      Get.put<ICompanyService>(service);
      controller = Get.put(CompanyConfigurationController("c1"))
        ..confirmDiscard = () async => discardAnswer;
      await pumpEventQueue();
    });

    tearDown(Get.reset);

    test("carrega a empresa e abre uma seção com o rascunho", () {
      expect(controller.company?.name, "Barbearia Exemplo");

      controller.open(ConfigSection.dados);

      expect(controller.field(CompanySettings.name).text, "Barbearia Exemplo");
      expect(controller.isDirty, isFalse);
    });

    test("não envia nada quando não há alteração", () async {
      controller.open(ConfigSection.dados);

      expect(await controller.save(), ConfigSaveResult.unchanged);
      expect(service.updates, 0);
    });

    test("barra o envio e mostra os erros", () async {
      controller.open(ConfigSection.dados);
      controller.field(CompanySettings.name).text = "  ";

      expect(await controller.save(), ConfigSaveResult.invalid);
      expect(controller.errors[CompanySettings.name], isNotNull);
      expect(service.updates, 0);
    });

    test("salva só os campos da seção e recarrega a empresa", () async {
      controller.open(ConfigSection.contato);
      controller.field(CompanySettings.facebook).text = "barbearia";
      controller.field(CompanySettings.phone).text = "(11) 3333-1111";
      service.json = {
        ..._companyJson(),
        "social": {"facebook": "barbearia"},
      };

      expect(await controller.save(), ConfigSaveResult.saved);

      expect(service.sent, {
        "social": {
          "phone": "1133331111",
          "whatsapp": "11900000000",
          "email": "",
          "instagram": "barbearia",
          "facebook": "barbearia",
        },
      });
      expect(controller.company?.social.facebook, "barbearia");
      expect(controller.isDirty, isFalse);
    });

    test("endereço limpa o complemento enviando vazio", () async {
      controller.open(ConfigSection.endereco);
      controller.field(CompanySettings.number).text = "250";

      await controller.save();

      final address = service.sent!["address"] as Map;
      expect(address["number"], "250");
      expect(address["complement"], "");
    });

    test("funcionamento envia horários e só reenvia os dias se mudarem", () async {
      controller.open(ConfigSection.funcionamento);
      controller.setPeriod(45);

      await controller.save();

      final config = service.sent!["configuration"] as Map;
      expect(config["defaultPeriodInMinutes"], 45);
      expect(config["openingHours"], "08:00");
      expect(config["lunchBreak"], {"start": "12:00", "end": "13:00"});
      expect(config["lockSchedulePeriodInMinutes"], 10);
      expect(config.containsKey("workingDays"), isFalse);
    });

    test("preserva o horário próprio dos dias que continuam abertos", () async {
      service.json = _companyJson(
        days: [
          1,
          2,
          {"day": 6, "openingHours": "08:00", "closingTime": "12:00", "lunchBreak": null},
        ],
      );
      await controller.loadCompanyData();
      controller.open(ConfigSection.funcionamento);

      controller.toggleDay(2, false);
      controller.toggleDay(3, true);
      await controller.save();

      expect((service.sent!["configuration"] as Map)["workingDays"], [
        {"day": 1},
        {"day": 3},
        {"day": 6, "openingHours": "08:00", "closingTime": "12:00", "lunchBreak": null},
      ]);
    });

    test("falha ao salvar mantém o rascunho e mostra a mensagem", () async {
      service.updateResponse = ApiResponse.badRequest(
        errorDescription: "Fechamento inválido",
      );
      controller.open(ConfigSection.dados);
      controller.field(CompanySettings.name).text = "Novo nome";

      expect(await controller.save(), ConfigSaveResult.failed);

      expect(controller.formError.value, "Fechamento inválido");
      expect(controller.field(CompanySettings.name).text, "Novo nome");
      expect(controller.saving.value, isFalse);
    });

    test("trocar de seção com alterações pede confirmação", () async {
      controller.open(ConfigSection.dados);
      controller.field(CompanySettings.name).text = "Outro";

      discardAnswer = false;
      expect(await controller.requestOpen(null), isFalse);
      expect(controller.section.value, ConfigSection.dados);

      discardAnswer = true;
      expect(await controller.requestOpen(null), isTrue);
      expect(controller.section.value, isNull);

      controller.open(ConfigSection.dados);
      expect(controller.field(CompanySettings.name).text, "Barbearia Exemplo");
    });

    test("descartar restaura os valores salvos", () async {
      controller.open(ConfigSection.dados);
      controller.field(CompanySettings.name).text = "Outro";

      await controller.discard();

      expect(controller.field(CompanySettings.name).text, "Barbearia Exemplo");
      expect(controller.isDirty, isFalse);
    });

    test("troca a logo e recusa imagem grande demais", () async {
      controller.logoPicker = () async => PickedImage(
        bytes: Uint8List(10),
        name: "a.png",
        contentType: "image/png",
      );

      final ok = await controller.changeLogo();
      expect(ok?.result, isTrue);
      expect(controller.company?.logoUrl, "https://x/logo.png");

      controller.logoPicker = () async => PickedImage(
        bytes: Uint8List(PickedImage.maxBytes + 1),
        name: "a.png",
        contentType: "image/png",
      );
      expect((await controller.changeLogo())?.result, isFalse);
    });
  });

  group("CompanyConfigurationPage", () {
    late _FakeCompanyService service;

    setUp(() {
      service = _FakeCompanyService();
      Get.put<ICompanyService>(service);
    });

    tearDown(Get.reset);

    Future<void> pumpPage(WidgetTester tester, Size size) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      Get.put(CompanyConfigurationController("c1"));

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: rootNavigatorKey,
          scaffoldMessengerKey: scaffoldMessengerKey,
          theme: appTheme,
          home: const CompanyConfigurationPage(),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets("celular: menu, abre a seção e volta", (tester) async {
      await pumpPage(tester, const Size(390, 844));

      expect(find.text("Barbearia Exemplo"), findsWidgets);
      expect(find.text("Funcionamento"), findsOneWidget);
      expect(find.text("Serviços"), findsOneWidget);
      expect(find.text("Salvar alterações"), findsNothing);

      await tester.tap(find.text("Funcionamento"));
      await tester.pumpAndSettle();

      expect(find.text("Salvar alterações"), findsOneWidget);
      expect(find.text("Abertura"), findsOneWidget);
      expect(find.textContaining("até 18 horários"), findsOneWidget);

      await tester.tap(find.byTooltip("Voltar para Configurações"));
      await tester.pumpAndSettle();

      expect(find.text("Salvar alterações"), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets("celular: erro de validação aparece ao salvar", (tester) async {
      await pumpPage(tester, const Size(390, 844));

      await tester.tap(find.text("Dados da empresa"));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, "");
      await tester.tap(find.text("Salvar alterações"));
      await tester.pumpAndSettle();

      expect(find.text("Informe o nome da empresa"), findsOneWidget);
      expect(service.updates, 0);
    });

    testWidgets("tela larga: menu e seção lado a lado", (tester) async {
      await pumpPage(tester, const Size(1280, 800));

      expect(find.text("Dados da empresa"), findsWidgets);
      expect(find.text("Nome da empresa"), findsOneWidget);
      expect(find.text("Descartar alterações"), findsOneWidget);

      await tester.tap(find.text("Endereço"));
      await tester.pumpAndSettle();

      expect(find.text("CEP"), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets("falha ao carregar permite tentar de novo", (tester) async {
      service.companyResponse = ApiResponse.badRequest(
        errorDescription: "Sem conexão",
      );
      await pumpPage(tester, const Size(390, 844));

      expect(find.text("Sem conexão"), findsOneWidget);

      service.companyResponse = null;
      await tester.tap(find.text("Tentar novamente"));
      await tester.pumpAndSettle();

      expect(find.text("Funcionamento"), findsOneWidget);
    });
  });
}
