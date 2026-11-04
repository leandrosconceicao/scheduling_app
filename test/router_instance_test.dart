import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:scheduling_app/src/domain/domain.dart';
import 'package:scheduling_app/src/routes/router.dart';

class _FakeOwnerSession extends ChangeNotifier implements IOwnerSessionService {
  @override
  bool get isAuthenticated => false;

  @override
  String get token => "";

  @override
  Future<void> start(String token) async {}

  @override
  Future<void> end() async {}
}

void main() {
  setUp(() => Get.put<IOwnerSessionService>(_FakeOwnerSession()));
  tearDown(Get.reset);

  test('AppRouter should expose one stable GoRouter instance', () {
    final router = AppRouter();

    expect(identical(router.instance, router.instance), isTrue);
    expect(identical(AppRouter().instance, router.instance), isTrue);
  });
}
