import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:scheduling_app/src/routes/routes.dart';

class _FakeController extends GetxController {
  final String id;
  bool closed = false;

  _FakeController(this.id);

  @override
  void onClose() {
    closed = true;
    super.onClose();
  }
}

Widget _scope(String id, {Key? key, void Function()? onCreate}) {
  return ControllerScope<_FakeController>(
    key: key,
    create: () {
      onCreate?.call();
      return _FakeController(id);
    },
    child: const SizedBox(),
  );
}

void main() {
  tearDown(Get.reset);

  testWidgets('creates the controller once across rebuilds', (tester) async {
    var creations = 0;

    await tester.pumpWidget(_scope("A", onCreate: () => creations++));
    await tester.pumpWidget(_scope("A", onCreate: () => creations++));

    expect(creations, 1);
    expect(Get.find<_FakeController>().id, "A");
  });

  testWidgets('deletes and closes the controller when unmounted', (tester) async {
    await tester.pumpWidget(_scope("A"));
    final controller = Get.find<_FakeController>();

    await tester.pumpWidget(const SizedBox());

    expect(controller.closed, isTrue);
    expect(Get.isRegistered<_FakeController>(), isFalse);
  });

  testWidgets('replaces a previous instance instead of reusing it', (tester) async {
    await tester.pumpWidget(_scope("A", key: const ValueKey("A")));
    final first = Get.find<_FakeController>();

    await tester.pumpWidget(_scope("B", key: const ValueKey("B")));

    expect(first.closed, isTrue);
    expect(Get.find<_FakeController>().id, "B");
  });
}
