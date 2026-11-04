import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../domain/domain.dart';
import '../app_routes.dart';

/// Protege a área administrativa da empresa.
final class OwnerGuard {
  final IOwnerSessionService session;

  const OwnerGuard(this.session);

  /// Sem sessão de proprietário, envia para o login guardando o destino em `from`.
  String? requireOwner(BuildContext _, GoRouterState state) {
    if (session.isAuthenticated) return null;

    return state.namedLocation(
      AppRoutes.adminLogin,
      pathParameters: state.pathParameters,
      queryParameters: {"from": state.uri.toString()},
    );
  }

  /// Proprietário já autenticado não precisa ver a tela de login.
  String? skipLoginWhenAuthenticated(BuildContext _, GoRouterState state) {
    if (!session.isAuthenticated) return null;

    return safeFrom(state.uri.queryParameters["from"]) ??
        state.namedLocation(
          AppRoutes.adminConfig,
          pathParameters: state.pathParameters,
        );
  }

  /// Aceita apenas destinos internos para evitar redirecionamentos abertos.
  static String? safeFrom(String? from) {
    if (from == null || !from.startsWith("/") || from.startsWith("//")) {
      return null;
    }
    return from;
  }
}
