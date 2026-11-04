import 'package:flutter/material.dart';
import 'package:ltech_core/ltech_core.dart';

import '../../core/core.dart';

Future<void> showSnk(
  String msg, {
  String? actionLabel,
  void Function()? onPressed,
  Duration? duration,
  ApiResponse? response,
  IconData icon = Icons.priority_high,
}) async {
  scaffoldMessengerKey.currentState?.showSnackBar(
    appSnackBar(
      msg,
      onPressed: onPressed,
      duration: duration,
      response: response,
      actionLabel: actionLabel,
      icon: icon,
    ),
  );
}

SnackBar appSnackBar(
  String msg, {
  String? actionLabel,
  void Function()? onPressed,
  Duration? duration,
  ApiResponse? response,
  IconData icon = Icons.priority_high,
}) {
  return SnackBar(
    duration: duration ?? const Duration(seconds: 5),
    content: Row(
      spacing: 12,
      children: [
        Icon(icon),
        Expanded(child: Text(msg)),
      ],
    ),
    // behavior: SnackBarBehavior.floating,
    action: onPressed == null
        ? null
        : SnackBarAction(label: actionLabel ?? 'Fechar', onPressed: onPressed),
  );
}
