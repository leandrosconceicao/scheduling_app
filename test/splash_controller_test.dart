import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ltech_core/ltech_core.dart';
import 'package:scheduling_app/src/domain/domain.dart';
import 'package:scheduling_app/src/view/view.dart';

class _FakeCompanyService extends Fake implements ICompanyService {
  final ApiResponse<Company?> response;

  _FakeCompanyService(this.response);

  @override
  Future<ApiResponse<Company?>> getCompanyBySubdomain(String subdomain) async {
    return response;
  }
}

class _FakeNavigation extends Fake implements INavigationService {
  final scheduleCalls = <String>[];

  @override
  void toSchedule(String companyId) => scheduleCalls.add(companyId);
}

void main() {
  late _FakeNavigation navigation;

  setUp(() {
    navigation = _FakeNavigation();
    Get.put<INavigationService>(navigation);
  });

  tearDown(Get.reset);

  test('navigates to the schedule of the resolved company', () async {
    Get.put<ICompanyService>(
      _FakeCompanyService(
        ApiResponse.result(data: Company.fromJson({"_id": "c1"})),
      ),
    );
    final controller = SplashController();

    await controller.navigateToCompanyDomain();

    expect(navigation.scheduleCalls, ["c1"]);
    expect(controller.error.value, isEmpty);
  });

  test('shows an error instead of navigating when no company is found', () async {
    Get.put<ICompanyService>(
      _FakeCompanyService(ApiResponse.notFound(message: "not found")),
    );
    final controller = SplashController();

    await controller.navigateToCompanyDomain();

    expect(navigation.scheduleCalls, isEmpty);
    expect(controller.error.value, isNotEmpty);
  });
}
