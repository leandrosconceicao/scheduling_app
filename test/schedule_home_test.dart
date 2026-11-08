import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ltech_core/ltech_core.dart';
import 'package:scheduling_app/src/domain/domain.dart';
import 'package:scheduling_app/src/view/view.dart';

class _FakeCompanyService extends Fake implements ICompanyService {
  Company? company;
  String failure = "falhou";

  @override
  Future<ApiResponse<Company?>> getCompany(String id) async =>
      ApiResponse.result(data: company, description: failure);

  @override
  Future<ApiResponse<List<ScheduleType>?>> getScheduleTypes(String id) async =>
      ApiResponse.result(data: [ScheduleType(id, "Corte", 40, id: "t1")]);

  @override
  Future<ApiResponse<List<Employee>?>> getEmployees(String id) async =>
      ApiResponse.result(data: [Employee("João", "", id)]);
}

class _FakeAuthService extends Fake implements IAuthService {}

class _FakeCloudService extends Fake implements ICloudService {}

class _FakeNavigation extends Fake implements INavigationService {}

void main() {
  late _FakeCompanyService service;
  late SchedulePageController controller;

  setUp(() {
    service = _FakeCompanyService();
    Get.put<ICompanyService>(service);
    Get.put<IAuthService>(_FakeAuthService());
    Get.put<ICloudService>(_FakeCloudService());
    Get.put<INavigationService>(_FakeNavigation());
    controller = SchedulePageController("c1");
  });

  tearDown(Get.reset);

  test('loadHome fills the page data and stops loading', () async {
    service.company = Company.fromJson({"_id": "c1", "name": "Barbearia X"});

    await controller.loadHome();

    expect(controller.homeLoading.value, isFalse);
    expect(controller.homeError.value, isEmpty);
    expect(controller.companyName, "Barbearia X");
    expect(controller.types, hasLength(1));
    expect(controller.employees, hasLength(1));
    expect(controller.hasContent, isTrue);
  });

  test('loadHome reports an error when the company fails to load', () async {
    service.company = null;

    await controller.loadHome();

    expect(controller.homeLoading.value, isFalse);
    expect(controller.homeError.value, "falhou");
    expect(controller.hasContent, isFalse);
  });

  test('retrying after an error clears it', () async {
    service.company = null;
    await controller.loadHome();

    service.company = Company.fromJson({"_id": "c1", "name": "Barbearia X"});
    await controller.loadHome();

    expect(controller.homeError.value, isEmpty);
    expect(controller.hasContent, isTrue);
  });
}
