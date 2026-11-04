import 'package:flutter/material.dart';
import 'package:ltech_core/ltech_core.dart';

import '../../core/core.dart';

class CustomRadioListTile<T> extends StatelessWidget {
  final T value;
  final bool selected;
  final String Function(T) titleBuilder;
  final Widget Function(T)? subTitleBuilder;
  final Widget Function(T)? leadingBuilder;
  const CustomRadioListTile(
    this.value, {
    super.key,
    required this.titleBuilder,
    this.subTitleBuilder,
    this.leadingBuilder,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return RadioListTile(
      activeColor: golden,
      radioScaleFactor: 1.2,
      contentPadding: const .all(16.0),
      shape: RoundedRectangleBorder(
        borderRadius: 8.borderRadius,
        side: BorderSide(color: selected ? golden : grey),
      ),
      secondary: leadingBuilder != null ? leadingBuilder!(value) : null,
      value: value,
      title: Text(titleBuilder(value), style: TextStyle(fontWeight: .bold)),
      subtitle: subTitleBuilder != null ? subTitleBuilder!(value) : null,
      controlAffinity: .trailing,
    );
  }
}
