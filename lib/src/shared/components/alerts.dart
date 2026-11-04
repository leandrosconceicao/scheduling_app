import 'package:flutter/material.dart';
import 'package:ltech_core/ltech_core.dart';

import '../../core/core.dart';

class AppAlertDialog extends StatelessWidget {
  final String? title;
  final String? body;
  final String? tecnical;

  const AppAlertDialog({super.key, this.title, this.body, this.tecnical});

  /// Contexto do navigator raiz, para diálogos abertos fora da árvore de widgets.
  static BuildContext get _rootContext => rootNavigatorKey.currentContext!;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AlertDialog(
      // alignment: Alignment.topCenter,
      title: ListTile(
        contentPadding: EdgeInsets.zero,
        title: SelectableText(
          title ?? "Atenção",
          style: textTheme.titleLarge,
        ),
        subtitle: SelectableText(
          "Data: ${DateTime.now().toDefaultDateWithHour}",
          style: textTheme.labelSmall,
        ),
      ),
      content: alertBody(body, tecnical: tecnical),
      actions: <Widget>[
        TextButton(
          child: const Text(
            "Ok",
            style: TextStyle(color: Colors.blue, fontSize: 16),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  static Widget alertBody(String? body, {String? tecnical}) {
    return SingleChildScrollView(
      child: Column(
        children: [
          SelectableText(body ?? 'Ocorreu um problema com requisição'),
        ],
      ),
    );
  }

  static Widget wait({String? message}) {
    return Material(
      color: Colors.black26,
      child: AlertDialog(
        title: Center(child: Text(message ?? 'Aguarde um instante')),
        content: const LinearProgressIndicator(backgroundColor: Colors.white),
      ),
    );
  }

  static Future<void> show({
    String? title,
    String? body,
    String? tecnical,
  }) async {
    await showDialog<void>(
      context: _rootContext,
      builder: (_) => AppAlertDialog(title: title, body: body, tecnical: tecnical),
    );
  }

  static Future<void> successAlert({String? title, String? body}) async {
    await showDialog<void>(
      context: _rootContext,
      builder: (_) => AppAlertDialog(title: title, body: body),
    );
  }

  static Future<bool?> confirmRequest({
    String? title,
    required String message,
    String cancelLabel = "Não",
    String confirmLabel = "Sim",
    bool destructive = false,
  }) async {
    return await showDialog<bool>(
      context: _rootContext,
      builder: (context) => AlertDialog(
        title: Text(title ?? "Atenção"),
        content: Text(message),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(cancelLabel),
                ),
              ),
              Expanded(
                child: FilledButton(
                  style: destructive
                      ? ButtonStyle(
                          backgroundColor: WidgetStatePropertyAll(
                            Colors.red.shade700,
                          ),
                          foregroundColor: const WidgetStatePropertyAll(
                            Colors.white,
                          ),
                        )
                      : null,
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(confirmLabel),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Future<T> onOverlay<T>({
    required Future<T> Function() callback,
    String? message,
  }) async {
    final navigator = rootNavigatorKey.currentState!;
    showDialog<void>(
      context: navigator.context,
      barrierDismissible: false,
      builder: (_) => PopScope(canPop: false, child: wait(message: message)),
    );
    try {
      return await callback();
    } finally {
      navigator.pop();
    }
  }

  static Future<T?> onSlideDialog<T>({required Widget child}) async {
    return showGeneralDialog<T>(
      context: _rootContext,
      barrierDismissible: true,
      barrierLabel: "slideDialog",
      pageBuilder: (_, _, _) => SizedBox(),
      transitionBuilder: (context, animation, _, _) {
        final width = MediaQuery.sizeOf(context).width;
        final offsetAnimation = Tween<Offset>(
          begin: const Offset(1.0, 0.0), // Começa fora da tela à direita
          end: Offset.zero, // Fim no centro da tela
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeInOut));

        return SlideTransition(
          position: offsetAnimation,
          child: SafeArea(
            child: Material(
              color: Colors.transparent,
              child: Align(
                alignment: Alignment.centerRight,
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: width * .25,
                        color: Colors.transparent,
                      ),
                    ),
                    Flexible(
                      child: Container(
                        width: width * .75,
                        color: Colors.white,
                        child: child,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
