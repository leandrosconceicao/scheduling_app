import 'package:flutter/material.dart';

import '../../../../shared/shared.dart';
import '../../../view.dart';

/// Título de seção da tela inicial.
class HomeSection extends StatelessWidget {
  final String title;
  final Widget child;

  const HomeSection({super.key, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: Colors.white),
          ),
          child,
        ],
      ),
    );
  }
}

/// Moldura padrão dos cartões da tela inicial.
class HomeCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const HomeCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: 8.borderRadius,
        border: Border.all(color: grey),
      ),
      child: child,
    );
  }
}
