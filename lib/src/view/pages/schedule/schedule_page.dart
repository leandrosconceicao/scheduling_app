import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../../routes/routes.dart';
import '../../view.dart';
import 'home/employees_section.dart';
import 'home/home_states.dart';
import 'home/services_section.dart';
import 'home/store_hero.dart';
import 'home/store_info_section.dart';
import 'schedule_drawer.dart';

/// Tela inicial da loja: informações, serviços, barbeiros e o botão que
/// inicia o agendamento.
class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  final controller = Get.find<SchedulePageController>();

  final _servicesKey = GlobalKey();
  final _employeesKey = GlobalKey();

  void _scrollTo(GlobalKey key) {
    final target = key.currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Title(
      title: "Faça seu agendamento",
      color: golden,
      child: Scaffold(
        key: controller.scaffoldKey,
        backgroundColor: Colors.black,
        drawer: ScheduleDrawer(controller: controller),
        appBar: AppBar(
          backgroundColor: Colors.black,
          actions: [
            IconButton(onPressed: () {}, icon: Icon(MdiIcons.bellOutline)),
          ],
        ),
        body: Obx(() {
          if (controller.homeLoading.value) return const HomeSkeleton();

          final error = controller.homeError.value;
          if (error.isNotEmpty) {
            return HomeError(message: error, onRetry: controller.loadHome);
          }

          return _content();
        }),
        bottomNavigationBar: Obx(() {
          // Sem a loja carregada não há o que agendar.
          if (!controller.hasContent) return const SizedBox.shrink();
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: () => GoRouter.of(
                    context,
                  ).pushScheduleForm(controller.companyId),
                  icon: Icon(MdiIcons.calendarMultiselectOutline),
                  label: const Text("Agendar horário"),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _content() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StoreHero(controller: controller),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              children: [
                ActionChip(
                  avatar: Icon(MdiIcons.contentCut, size: 18),
                  label: const Text("Serviços"),
                  side: BorderSide(color: golden),
                  onPressed: () => _scrollTo(_servicesKey),
                ),
                ActionChip(
                  avatar: Icon(MdiIcons.accountOutline, size: 18),
                  label: const Text("Barbeiros"),
                  side: BorderSide(color: golden),
                  onPressed: () => _scrollTo(_employeesKey),
                ),
              ],
            ),
          ),
          StoreInfoSection(controller: controller),
          KeyedSubtree(
            key: _servicesKey,
            child: ServicesSection(controller: controller),
          ),
          KeyedSubtree(
            key: _employeesKey,
            child: EmployeesSection(controller: controller),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
