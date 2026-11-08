import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../domain/domain.dart';
import '../../../../shared/shared.dart';
import '../../../view.dart';

/// Topo da tela inicial: logo, nome, situação (aberto/fechado) e slogan.
class StoreHero extends StatelessWidget {
  final SchedulePageController controller;

  const StoreHero({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;

    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/barber_bg.jpg'),
                fit: BoxFit.cover,
                opacity: .4,
              ),
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black],
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 12,
            children: [
              Row(
                spacing: 16,
                children: [
                  Obx(
                    () => EmployeeAvatar(
                      name: controller.companyName,
                      photoUrl: controller.companyLogo,
                      radius: 40,
                    ),
                  ),
                  Expanded(
                    child: Obx(
                      () => Text(
                        controller.companyName,
                        style: theme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Obx(() {
                final status = controller.storeStatus;
                if (status == null) return const SizedBox.shrink();
                return StatusBadge(status: status);
              }),
              RichText(
                text: TextSpan(
                  style: theme.headlineMedium?.copyWith(color: Colors.white),
                  children: [
                    const TextSpan(text: "Seu estilo,\n"),
                    TextSpan(
                      text: "nossa paixão.",
                      style: TextStyle(color: golden),
                    ),
                  ],
                ),
              ),
              Text(
                "Agende seu horário e viva a melhor experiência de barbearia.",
                style: theme.bodyLarge?.copyWith(color: Colors.white),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class StatusBadge extends StatelessWidget {
  final StoreStatus status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status.kind) {
      StoreStatusKind.open => Colors.greenAccent.shade400,
      StoreStatusKind.lunch => Colors.amber,
      StoreStatusKind.closed => Colors.redAccent,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: 20.borderRadius,
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 8,
        children: [
          Icon(Icons.circle, size: 10, color: color),
          Flexible(
            child: Text(
              status.label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
