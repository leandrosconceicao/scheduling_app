import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:ltech_core/ltech_core.dart';
import 'package:scheduling_app/src/domain/domain.dart';
import 'package:scheduling_app/src/view/view.dart';

class _FakeCompanyService extends Fake implements ICompanyService {
  var removedLocks = 0;

  @override
  Future<ApiResponse> removeLockSchedule(String companyId, Schedule schedule) async {
    removedLocks++;
    return ApiResponse.success();
  }
}

class _FakeAuthService extends Fake implements IAuthService {}

class _FakeCloudService extends Fake implements ICloudService {}

class _FakeNavigation extends Fake implements INavigationService {}

Schedule _schedule() {
  final now = DateTime.now();
  return Schedule(
    startsAt: now,
    endsAt: now.add(const Duration(minutes: 30)),
    companyId: "c1",
    client: null,
    typeId: "t1",
    employeeId: "e1",
  );
}

void main() {
  late _FakeCompanyService companyService;
  late SchedulePageController controller;

  setUp(() {
    companyService = _FakeCompanyService();
    Get.put<ICompanyService>(companyService);
    Get.put<IAuthService>(_FakeAuthService());
    Get.put<ICloudService>(_FakeCloudService());
    Get.put<INavigationService>(_FakeNavigation());
    // Criado sem Get.put para não disparar o onInit (carregamento de dados).
    controller = SchedulePageController("c1");
  });

  tearDown(Get.reset);

  group('handleFormBack', () {
    test('allows leaving on the first step', () {
      expect(controller.handleFormBack(), isTrue);
    });

    test('goes back one step instead of leaving', () {
      controller.activeStep.value = 2;

      expect(controller.handleFormBack(), isFalse);
      expect(controller.activeStep.value, 1);
    });

    test('releases the reserved schedule when leaving the confirmation', () async {
      controller.activeStep.value = 3;
      controller.selectedSchedule.value = _schedule();

      expect(controller.handleFormBack(), isFalse);
      await Future<void>.delayed(Duration.zero);

      expect(companyService.removedLocks, 1);
      expect(controller.activeStep.value, 2);
    });

    test('ignores back while processing', () {
      controller.activeStep.value = 2;
      controller.processing.value = true;

      expect(controller.handleFormBack(), isFalse);
      expect(controller.activeStep.value, 2);
    });
  });

  group('form route onExit', () {
    Future<GoRouter> pumpOnForm(WidgetTester tester) async {
      final router = GoRouter(
        initialLocation: "/c1",
        routes: [
          GoRoute(
            path: "/:companyId",
            builder: (_, _) => const Scaffold(body: Text("schedule")),
            routes: [
              GoRoute(
                path: "agendar",
                onExit: (_, _) => controller.handleFormBack(),
                builder: (_, _) => Scaffold(appBar: AppBar(), body: const Text("form")),
              ),
            ],
          ),
        ],
      );
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      router.push("/c1/agendar");
      await tester.pumpAndSettle();
      return router;
    }

    testWidgets('AppBar and system back step back before closing', (tester) async {
      await pumpOnForm(tester);
      controller.activeStep.value = 2;

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text("form"), findsOneWidget);
      expect(controller.activeStep.value, 1);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text("form"), findsOneWidget);
      expect(controller.activeStep.value, 0);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text("schedule"), findsOneWidget);
    });

    testWidgets('browser back (location change) steps back first', (tester) async {
      final router = await pumpOnForm(tester);
      controller.activeStep.value = 1;

      router.go("/c1");
      await tester.pumpAndSettle();
      expect(find.text("form"), findsOneWidget);
      expect(controller.activeStep.value, 0);

      router.go("/c1");
      await tester.pumpAndSettle();
      expect(find.text("schedule"), findsOneWidget);
    });
  });
}
