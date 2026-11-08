import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../domain/domain.dart';
import '../../../../shared/shared.dart';
import '../../../view.dart';
import 'home_section.dart';

/// Barbeiros da loja, em carrossel horizontal.
class EmployeesSection extends StatelessWidget {
  final SchedulePageController controller;

  const EmployeesSection({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return HomeSection(
      title: "Nossos barbeiros",
      child: Obx(() {
        final employees = controller.employees;
        if (employees.isEmpty) {
          return const Text("Nenhum barbeiro cadastrado no momento.");
        }

        return SizedBox(
          height: 150,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: employees.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (_, i) => _EmployeeCard(employee: employees[i]),
          ),
        );
      }),
    );
  }
}

class _EmployeeCard extends StatelessWidget {
  final Employee employee;

  const _EmployeeCard({required this.employee});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: 8.borderRadius,
        border: Border.all(color: grey),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 8,
        children: [
          EmployeeAvatar(
            name: employee.name,
            photoUrl: employee.profilePhotoUrl,
            radius: 32,
          ),
          Text(
            employee.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white),
          ),
          if (employee.rating > 0)
            Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 4,
              children: [
                Icon(MdiIcons.star, color: golden, size: 16),
                Text(employee.rating.toStringAsFixed(1)),
              ],
            ),
        ],
      ),
    );
  }
}
