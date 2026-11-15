import 'package:flutter/material.dart';

import '../../domain/domain.dart';
import '../../view/view.dart';

/// Dialog padrão do app (erro, sucesso e confirmação compartilham o mesmo visual).
///
/// Com [confirmLabel] vira um dialog de confirmação (Não/Sim); sem ele, mostra
/// apenas o botão "Ok".
class DefaultAlert extends StatelessWidget {
  final String title;
  final String message;
  final Severity severity;
  final String? confirmLabel;
  final String cancelLabel;
  final bool destructive;

  const DefaultAlert({
    super.key,
    this.title = "Atenção",
    required this.message,
    this.severity = Severity.success,
    this.confirmLabel,
    this.cancelLabel = "Não",
    this.destructive = false,
  });

  /// Abre o alerta no navigator raiz (útil para chamadas fora da árvore de widgets).
  static Future<void> show({
    String title = "Atenção",
    required String message,
    Severity severity = Severity.success,
  }) {
    return showDialog<void>(
      context: rootNavigatorKey.currentContext!,
      builder: (_) => DefaultAlert(title: title, message: message, severity: severity),
    );
  }

  /// Dialog de confirmação; retorna `true` ao confirmar.
  static Future<bool?> confirm({
    String title = "Atenção",
    required String message,
    String cancelLabel = "Não",
    String confirmLabel = "Sim",
    bool destructive = false,
  }) {
    return showDialog<bool>(
      context: rootNavigatorKey.currentContext!,
      builder: (_) => DefaultAlert(
        title: title,
        message: message,
        severity: destructive ? Severity.error : Severity.success,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        destructive: destructive,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isError = severity == Severity.error;
    final isConfirm = confirmLabel != null;

    return AlertDialog(
      constraints: const BoxConstraints(minWidth: 280, maxWidth: 480),
      icon: Icon(
        isError ? Icons.error : Icons.task_alt,
        color: isError ? Colors.red : Colors.green,
        size: 48,
      ),
      title: Text(title, textAlign: TextAlign.center),
      content: SingleChildScrollView(
        child: Text(message, textAlign: TextAlign.center),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: isConfirm
          ? [
              Row(
                spacing: 8,
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
                          ? FilledButton.styleFrom(
                              backgroundColor: Colors.red.shade700,
                              foregroundColor: Colors.white,
                            )
                          : null,
                      onPressed: () => Navigator.of(context).pop(true),
                      child: Text(confirmLabel!),
                    ),
                  ),
                ],
              ),
            ]
          : [
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("Ok"),
              ),
            ],
    );
  }
}
