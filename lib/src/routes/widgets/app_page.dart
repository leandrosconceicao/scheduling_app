import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Página padrão das rotas: sem transição na web (comportamento esperado de um
/// site) e com a transição da plataforma no mobile.
Page<void> appPage(GoRouterState state, Widget child, {bool isWeb = kIsWeb}) {
  if (isWeb) {
    return NoTransitionPage<void>(key: state.pageKey, child: child);
  }
  return MaterialPage<void>(key: state.pageKey, child: child);
}
