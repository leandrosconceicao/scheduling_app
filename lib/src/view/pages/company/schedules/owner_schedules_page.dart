import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../domain/domain.dart';
import '../../../../routes/routes.dart';
import '../../../../shared/shared.dart';
import '../../../view.dart';

class OwnerSchedulesPage extends GetView<OwnerSchedulesController> {
  const OwnerSchedulesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Agenda"),
        actions: [
          IconButton(
            tooltip: "Configurações",
            icon: Icon(MdiIcons.cogOutline),
            onPressed: () => GoRouter.of(context).goAdminConfig(controller.companyId),
          ),
        ],
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            children: [
              _SearchField(controller: controller),
              Obx(
                () => controller.searching
                    ? const SizedBox.shrink()
                    : _DayBar(controller: controller),
              ),
              _Filters(controller: controller),
              Expanded(child: _List(controller: controller)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final OwnerSchedulesController controller;

  const _SearchField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const .fromLTRB(16, 12, 16, 0),
      child: Obx(
        () => TextField(
          controller: controller.searchController,
          textInputAction: TextInputAction.search,
          onSubmitted: controller.search,
          decoration: InputDecoration(
            hintText: "Buscar cliente por nome ou telefone",
            prefixIcon: Icon(MdiIcons.magnify),
            suffixIcon: controller.query.value.isEmpty
                ? null
                : IconButton(
                    tooltip: "Limpar busca",
                    icon: Icon(MdiIcons.close),
                    onPressed: controller.clearSearch,
                  ),
          ),
        ),
      ),
    );
  }
}

String _two(int n) => n.toString().padLeft(2, "0");

String _dayLabel(DateTime d) =>
    "${WeekDays.name(WeekDays.of(d))}, ${_two(d.day)}/${_two(d.month)}/${d.year}";

class _DayBar extends StatelessWidget {
  final OwnerSchedulesController controller;

  const _DayBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const .symmetric(horizontal: 8.0, vertical: 4.0),
      child: Obx(() {
        final day = controller.day.value;

        return Row(
          children: [
            IconButton(
              tooltip: "Dia anterior",
              icon: Icon(MdiIcons.chevronLeft),
              onPressed: () => controller.shiftDay(-1),
            ),
            Expanded(
              child: TextButton(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: day,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) controller.goToDay(picked);
                },
                child: Text(
                  controller.isToday ? "Hoje · ${_dayLabel(day)}" : _dayLabel(day),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            if (!controller.isToday)
              IconButton(
                tooltip: "Ir para hoje",
                icon: Icon(MdiIcons.calendarToday),
                onPressed: controller.goToToday,
              ),
            IconButton(
              tooltip: "Próximo dia",
              icon: Icon(MdiIcons.chevronRight),
              onPressed: () => controller.shiftDay(1),
            ),
          ],
        );
      }),
    );
  }
}

class _Filters extends StatelessWidget {
  final OwnerSchedulesController controller;

  const _Filters({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final selected = controller.filter.value;
      final employees = controller.employees.toList();

      return SizedBox(
        height: 48,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const .symmetric(horizontal: 16.0),
          children: [
            for (final f in AppointmentFilter.values)
              Padding(
                padding: const .only(right: 8.0),
                child: ChoiceChip(
                  label: Text(f.label),
                  selected: selected == f,
                  onSelected: (_) => controller.setFilter(f),
                ),
              ),
            if (employees.length > 1) ...[
              const SizedBox(width: 8),
              Padding(
                padding: const .only(right: 8.0),
                child: ChoiceChip(
                  label: const Text("Todos os barbeiros"),
                  selected: controller.employeeId.value == null,
                  onSelected: (_) => controller.setEmployee(null),
                ),
              ),
              for (final e in employees)
                Padding(
                  padding: const .only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(e.name),
                    selected: controller.employeeId.value == e.id,
                    onSelected: (_) => controller.setEmployee(e.id),
                  ),
                ),
            ],
          ],
        ),
      );
    });
  }
}

class _List extends StatelessWidget {
  final OwnerSchedulesController controller;

  const _List({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final items = controller.items.toList();
      final error = controller.error.value;

      if (controller.loading.value && items.isEmpty) return const _Loading();

      if (error.isNotEmpty && items.isEmpty) {
        return _Message(
          title: error,
          action: OutlinedButton(
            onPressed: controller.load,
            child: const Text("Tentar novamente"),
          ),
        );
      }

      if (controller.loaded.value && items.isEmpty) {
        return _Message(
          title: controller.searching
              ? "Nenhum agendamento encontrado"
              : "Nenhum agendamento neste dia",
          message: controller.searching
              ? "Tente outro nome ou telefone."
              : "Use os filtros ou troque o dia para ver outros horários.",
        );
      }

      return RefreshIndicator(
        onRefresh: controller.load,
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const .all(16.0),
          itemCount: items.length + 1,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (_, i) => i < items.length
              ? AppointmentCard(
                  schedule: items[i],
                  showDate: controller.searching,
                  onTap: () => showAppointmentDetail(
                    context,
                    controller,
                    items[i],
                  ),
                )
              : _MoreFooter(controller: controller),
        ),
      );
    });
  }
}

class _MoreFooter extends StatelessWidget {
  final OwnerSchedulesController controller;

  const _MoreFooter({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.loadingMore.value) {
        return const Center(
          child: Padding(padding: EdgeInsets.all(8), child: LoadingIcon()),
        );
      }
      if (!controller.hasMore.value) return const SizedBox.shrink();

      return OutlinedButton(
        onPressed: () => controller.load(more: true),
        child: const Text("Carregar mais"),
      );
    });
  }
}

/// Cartão de um agendamento na agenda do dono.
class AppointmentCard extends StatelessWidget {
  final Schedule schedule;
  final bool showDate;
  final VoidCallback? onTap;

  const AppointmentCard({
    super.key,
    required this.schedule,
    this.showDate = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final canceled = schedule.isCanceled;
    final muted = canceled ? white.withValues(alpha: .6) : white;
    final type = schedule.typeDetail;
    final employee = schedule.employee;
    final time =
        "${schedule.startTime.hour.toString().padLeft(2, "0")}:"
        "${schedule.startTime.minute.toString().padLeft(2, "0")}";

    return InkWell(
      borderRadius: 8.borderRadius,
      onTap: onTap,
      child: Container(
        padding: const .all(16.0),
        decoration: BoxDecoration(
          border: Border.all(
            color: canceled ? grey : golden.withValues(alpha: .6),
          ),
          borderRadius: 8.borderRadius,
        ),
        child: Row(
          crossAxisAlignment: .start,
          spacing: 16,
          children: [
            Column(
              children: [
                Text(
                  time,
                  style: TextStyle(
                    color: muted,
                    fontWeight: .bold,
                    fontSize: 18,
                    decoration: canceled ? TextDecoration.lineThrough : null,
                  ),
                ),
                if (showDate)
                  Text(
                    "${_two(schedule.startsAt.day)}/${_two(schedule.startsAt.month)}",
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: .start,
                spacing: 4,
                children: [
                  Text(
                    schedule.client?.name.isNotEmpty == true
                        ? schedule.client!.name
                        : "Cliente",
                    style: TextStyle(
                      color: muted,
                      fontWeight: .bold,
                      fontSize: 16,
                    ),
                  ),
                  if (type != null)
                    Text("${type.name} · ${type.price.ptBrCoin}"),
                  if (employee != null && employee.name.isNotEmpty)
                    Text(
                      employee.name,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ),
            StateBadge(schedule: schedule),
          ],
        ),
      ),
    );
  }
}

/// Selo do status do agendamento.
class StateBadge extends StatelessWidget {
  final Schedule schedule;

  const StateBadge({super.key, required this.schedule});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final (label, color) = schedule.isCanceled
        ? ("Cancelado", scheme.error)
        : schedule.isCompleted
        ? ("Concluído", Colors.green)
        : ("Agendado", golden);

    return Container(
      padding: const .symmetric(horizontal: 8.0, vertical: 2.0),
      decoration: BoxDecoration(
        border: Border.all(color: color),
        borderRadius: 12.borderRadius,
      ),
      child: Text(label, style: TextStyle(fontSize: 12, color: color)),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: "Carregando agendamentos",
      child: Padding(
        padding: const .all(16.0),
        child: Shimmer.fromColors(
          baseColor: grey,
          highlightColor: softBlack,
          child: Column(
            spacing: 12,
            children: List.generate(
              4,
              (_) => Container(
                height: 88,
                decoration: BoxDecoration(
                  color: grey,
                  borderRadius: 8.borderRadius,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  final String title;
  final String? message;
  final Widget? action;

  const _Message({required this.title, this.message, this.action});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const .all(24.0),
        child: Column(
          mainAxisSize: .min,
          spacing: 12,
          children: [
            Icon(MdiIcons.calendarBlankOutline, size: 48),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (message != null) Text(message!, textAlign: TextAlign.center),
            ?action,
          ],
        ),
      ),
    );
  }
}
