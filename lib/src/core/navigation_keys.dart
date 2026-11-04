import 'package:flutter/material.dart';

/// Navigator raiz do app (o mesmo usado pelo GoRouter).
///
/// Use apenas para overlays disparados fora da árvore de widgets (diálogos
/// abertos por controllers). Widgets devem usar o próprio `context`.
final rootNavigatorKey = GlobalKey<NavigatorState>();

final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
