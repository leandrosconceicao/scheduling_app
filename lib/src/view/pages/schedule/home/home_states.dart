import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../shared/shared.dart';
import '../../../view.dart';

/// Esqueleto exibido enquanto a loja carrega.
class HomeSkeleton extends StatelessWidget {
  const HomeSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    Widget block(double height, {double? width}) => Container(
      height: height,
      width: width,
      decoration: BoxDecoration(color: grey, borderRadius: 8.borderRadius),
    );

    return Shimmer.fromColors(
      baseColor: grey,
      highlightColor: softBlack,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 16,
          children: [
            Row(
              spacing: 16,
              children: [
                const CircleAvatar(radius: 40, backgroundColor: grey),
                block(24, width: 180),
              ],
            ),
            block(28, width: 220),
            block(60),
            block(90),
            block(90),
            block(90),
          ],
        ),
      ),
    );
  }
}

/// Erro ao carregar a loja, com nova tentativa.
class HomeError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const HomeError({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 16,
          children: [
            Icon(MdiIcons.storeAlertOutline, size: 48),
            Text(message, textAlign: TextAlign.center),
            FilledButton(
              onPressed: onRetry,
              child: const Text("Tentar novamente"),
            ),
          ],
        ),
      ),
    );
  }
}
