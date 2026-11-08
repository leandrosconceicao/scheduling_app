import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';

import '../../../domain/domain.dart';
import '../../../shared/shared.dart';
import '../../view.dart';

class MySchedulesPage extends GetView<MySchedulesController> {
  const MySchedulesPage({super.key});

  @override
  Widget build(BuildContext context) {
    if (!controller.isLogged) {
      return Scaffold(
        appBar: AppBar(title: const Text("Meus agendamentos")),
        body: const _Message(
          title: "Faça login para ver seus agendamentos",
          message: "Entre na sua conta para consultar seus horários.",
        ),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Builder(
        builder: (context) {
          final tabs = DefaultTabController.of(context);
          tabs.addListener(() {
            if (tabs.index == 1) controller.ensureLoaded(controller.history);
          });

          return Scaffold(
            appBar: AppBar(
              title: const Text("Meus agendamentos"),
              bottom: const TabBar(
                tabs: [
                  Tab(text: "Próximos"),
                  Tab(text: "Histórico"),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                _FeedView(
                  controller: controller,
                  feed: controller.upcoming,
                  emptyTitle: "Nenhum agendamento por vir",
                  emptyMessage:
                      "Quando você agendar um horário, ele aparecerá aqui.",
                ),
                _FeedView(
                  controller: controller,
                  feed: controller.history,
                  emptyTitle: "Nenhum agendamento anterior",
                  emptyMessage:
                      "Seus atendimentos passados e cancelamentos aparecem aqui.",
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _FeedView extends StatelessWidget {
  final MySchedulesController controller;
  final ScheduleFeed feed;
  final String emptyTitle;
  final String emptyMessage;

  const _FeedView({
    required this.controller,
    required this.feed,
    required this.emptyTitle,
    required this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final items = feed.items.toList();
      final loading = feed.loading.value;
      final error = feed.error.value;

      if (loading && items.isEmpty) return const _Loading();

      if (error.isNotEmpty && items.isEmpty) {
        return _Message(
          title: error,
          action: OutlinedButton(
            onPressed: () => controller.load(feed),
            child: const Text("Tentar novamente"),
          ),
        );
      }

      if (feed.loaded.value && items.isEmpty) {
        return _Message(title: emptyTitle, message: emptyMessage);
      }

      return RefreshIndicator(
        onRefresh: () => controller.load(feed),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const .all(16.0),
              itemCount: items.length + 1,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (_, i) => i < items.length
                  ? ScheduleCard(schedule: items[i])
                  : _MoreFooter(controller: controller, feed: feed),
            ),
          ),
        ),
      );
    });
  }
}

class _MoreFooter extends StatelessWidget {
  final MySchedulesController controller;
  final ScheduleFeed feed;

  const _MoreFooter({required this.controller, required this.feed});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (feed.loadingMore.value) {
        return const Center(
          child: Padding(padding: EdgeInsets.all(8), child: LoadingIcon()),
        );
      }
      if (!feed.hasMore.value) return const SizedBox.shrink();

      return Column(
        spacing: 8,
        children: [
          if (feed.error.value.isNotEmpty)
            Text(
              feed.error.value,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          OutlinedButton(
            onPressed: () => controller.load(feed, more: true),
            child: const Text("Carregar mais"),
          ),
        ],
      );
    });
  }
}

/// Cartão de um agendamento do cliente.
class ScheduleCard extends StatelessWidget {
  final Schedule schedule;

  const ScheduleCard({super.key, required this.schedule});

  static String _two(int n) => n.toString().padLeft(2, "0");

  static String dateLabel(DateTime d) =>
      "${WeekDays.shortName(WeekDays.of(d))}, ${_two(d.day)}/${_two(d.month)}/${d.year}";

  static String timeLabel(DateTime d) => "${_two(d.hour)}:${_two(d.minute)}";

  @override
  Widget build(BuildContext context) {
    final company = schedule.companyDetail;
    final type = schedule.typeDetail;
    final employee = schedule.employee;
    final canceled = schedule.isCanceled;
    final muted = canceled ? white.withValues(alpha: .6) : white;

    return Container(
      padding: const .all(16.0),
      decoration: BoxDecoration(
        border: Border.all(color: canceled ? grey : golden.withValues(alpha: .6)),
        borderRadius: 8.borderRadius,
      ),
      child: Column(
        crossAxisAlignment: .start,
        spacing: 8,
        children: [
          Row(
            spacing: 8,
            children: [
              Expanded(
                child: Text(
                  company?.name.isNotEmpty == true
                      ? company!.name
                      : "Estabelecimento",
                  style: TextStyle(
                    color: muted,
                    fontWeight: .bold,
                    fontSize: 16,
                  ),
                ),
              ),
              if (canceled) _CancelChip(cancellation: schedule.cancellation!),
            ],
          ),
          Row(
            spacing: 8,
            children: [
              Icon(MdiIcons.calendarClockOutline, size: 20),
              Expanded(
                child: Text(
                  "${dateLabel(schedule.startsAt)} · "
                  "${timeLabel(schedule.startsAt)} às ${timeLabel(schedule.endsAt)}",
                  style: TextStyle(
                    color: muted,
                    fontWeight: .w600,
                    decoration: canceled ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
            ],
          ),
          if (type != null)
            Row(
              spacing: 8,
              children: [
                Icon(MdiIcons.contentCut, size: 20),
                Expanded(child: Text(type.name)),
                Text(
                  type.price.ptBrCoin,
                  style: const TextStyle(fontWeight: .bold),
                ),
              ],
            ),
          if (employee != null && employee.name.isNotEmpty)
            Row(
              spacing: 8,
              children: [
                Icon(MdiIcons.accountOutline, size: 20),
                Expanded(child: Text(employee.name)),
              ],
            ),
          if (canceled && schedule.cancellation!.reason.isNotEmpty)
            Text(
              "Motivo: ${schedule.cancellation!.reason}",
              style: Theme.of(context).textTheme.bodySmall,
            ),
        ],
      ),
    );
  }
}

class _CancelChip extends StatelessWidget {
  final ScheduleCancellation cancellation;

  const _CancelChip({required this.cancellation});

  @override
  Widget build(BuildContext context) {
    final label = switch (cancellation.canceledBy) {
      CancellationOrigin.company => "Cancelado pelo estabelecimento",
      CancellationOrigin.client => "Cancelado por você",
      null => "Cancelado",
    };

    return Container(
      padding: const .symmetric(horizontal: 8.0, vertical: 2.0),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.error),
        borderRadius: 12.borderRadius,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: Theme.of(context).colorScheme.error,
        ),
      ),
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
                height: 120,
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
