import 'package:flutter/material.dart';

import '../../../core/core.dart';

class ScheduleStepSession extends StatelessWidget {
  final IconData icon;
  final String label;
  const ScheduleStepSession(this.label, this.icon, {super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: .zero,
      leading: Icon(icon, color: golden),
      title: Text(label, style: TextStyle(fontWeight: .bold)),
    );
  }
}