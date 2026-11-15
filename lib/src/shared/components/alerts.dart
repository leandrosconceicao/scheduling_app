import 'package:flutter/material.dart';

import '../../core/core.dart';
import '../../domain/domain.dart';
import 'alert_dialogs.dart';

class AppAlertDialog {
  const AppAlertDialog._();

  /// Contexto do navigator raiz, para diálogos abertos fora da árvore de widgets.
  static BuildContext get _rootContext => rootNavigatorKey.currentContext!;

  static Widget wait({String? message}) {
    return Material(
      color: Colors.black26,
      child: AlertDialog(
        title: Center(child: Text(message ?? 'Aguarde um instante')),
        content: const LinearProgressIndicator(backgroundColor: Colors.white),
      ),
    );
  }

  /// Alerta de erro (visual padrão de [DefaultAlert]).
  static Future<void> show({String? title, String? body, String? tecnical}) {
    return DefaultAlert.show(
      title: title ?? "Atenção",
      message: body ?? 'Ocorreu um problema com requisição',
      severity: Severity.error,
    );
  }

  static Future<void> successAlert({String? title, String? body}) {
    return DefaultAlert.show(title: title ?? "Atenção", message: body ?? "");
  }

  static Future<bool?> confirmRequest({
    String? title,
    required String message,
    String cancelLabel = "Não",
    String confirmLabel = "Sim",
    bool destructive = false,
  }) {
    return DefaultAlert.confirm(
      title: title ?? "Atenção",
      message: message,
      cancelLabel: cancelLabel,
      confirmLabel: confirmLabel,
      destructive: destructive,
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
