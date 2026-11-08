import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../domain/domain.dart';
import '../../../view.dart';
import 'home_section.dart';

/// Lista informativa dos serviços (o agendamento começa pelo botão geral).
class ServicesSection extends StatelessWidget {
  final SchedulePageController controller;

  const ServicesSection({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return HomeSection(
      title: "Nossos serviços",
      child: Obx(() {
        final types = controller.types;
        if (types.isEmpty) {
          return const Text("Nenhum serviço cadastrado no momento.");
        }

        final showValues = controller.showScheduleValues;
        return Column(
          spacing: 12,
          children: [
            for (final type in types)
              HomeCard(
                child: Row(
                  spacing: 12,
                  children: [
                    Icon(MdiIcons.contentCut),
                    Expanded(
                      child: Text(
                        type.name,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    if (showValues)
                      Text(
                        type.price.ptBrCoin,
                        style: TextStyle(
                          color: golden,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
          ],
        );
      }),
    );
  }
}
