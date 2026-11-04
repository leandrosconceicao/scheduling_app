import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NotFoundPage extends StatelessWidget {
  /// Erro de roteamento; exibido apenas em modo debug.
  final Exception? error;

  const NotFoundPage({super.key, this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: .min,
          spacing: 16,
          children: [
            Text("Página não localizada"),
            if (kDebugMode && error != null)
              Text(
                error.toString(),
                textAlign: .center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            FilledButton(
              onPressed: () => context.go("/"),
              child: Text("Voltar ao início"),
            ),
          ],
        ),
      ),
    );
  }
}
