import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

/// Vincula o ciclo de vida de um [GetxController] ao widget (rota) que o envolve.
///
/// O controller é criado uma única vez ao montar, substituindo qualquer instância
/// anterior do mesmo tipo/tag, e removido ao desmontar, o que dispara o `onClose`.
class ControllerScope<T extends GetxController> extends StatefulWidget {
  final T Function() create;
  final Widget child;
  final String? tag;

  const ControllerScope({
    super.key,
    required this.create,
    required this.child,
    this.tag,
  });

  @override
  State<ControllerScope<T>> createState() => _ControllerScopeState<T>();
}

class _ControllerScopeState<T extends GetxController>
    extends State<ControllerScope<T>> {
  late final T _controller;

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<T>(tag: widget.tag)) {
      Get.delete<T>(tag: widget.tag, force: true);
    }
    _controller = Get.put<T>(widget.create(), tag: widget.tag);
  }

  @override
  void dispose() {
    final isCurrent = Get.isRegistered<T>(tag: widget.tag) &&
        identical(Get.find<T>(tag: widget.tag), _controller);
    if (isCurrent) {
      Get.delete<T>(tag: widget.tag);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
