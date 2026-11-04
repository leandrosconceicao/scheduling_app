import 'package:flutter/material.dart';
import 'package:ltech_core/ltech_core.dart';

import '../../view/view.dart';

class FormAlert extends StatelessWidget {
  final String message;
  const FormAlert(this.message, {super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      tileColor: Colors.red.withValues(alpha: .2),
      shape: RoundedRectangleBorder(
        borderRadius: 8.borderRadius,
        side: BorderSide(
          color: Colors.red,
        ),
      ),
      leading: Icon(MdiIcons.alertCircleOutline),
      title: Text(message)
    );
  }
}