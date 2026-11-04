import 'package:flutter/material.dart';
import 'package:ltech_core/ltech_core.dart';

import '../../domain/domain.dart';
import '../../view/view.dart';

class DefaultAlert extends StatelessWidget {
  final String title;
  final String message;
  final Severity severity;
  const DefaultAlert({
    super.key,
    this.title = "Atenção",
    required this.message,
    this.severity = Severity.success,
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

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Dialog(
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: severity == .error ? Colors.red.withValues(alpha: .6) : Colors.green.withValues(alpha: .6),
          width: 2.0,
        ),
        borderRadius: 8.borderRadius
      ),
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .3),
      child: Padding(
        padding: const .all(16.0),
        child: Column(
          spacing: 16.0,
          children: [
            Row(
              mainAxisAlignment: .end,
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(MdiIcons.close),
                ),
              ],
            ),
            Column(
              spacing: 8.0,
              children: [
                Visibility(
                  replacement: Icon(Icons.error, color: Colors.red, size: 48,),
                  visible: severity == .success,
                  child: Icon(Icons.task_alt, color: Colors.green, size: 48)
                ),
                Text(title, style: textTheme.headlineLarge),
              ],
            ),
            Text(message, style: textTheme.titleLarge, textAlign: .center),
          ],
        ),
      ),
    );
  }
}
