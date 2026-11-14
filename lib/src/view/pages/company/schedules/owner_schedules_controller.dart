import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../../domain/domain.dart';
import '../../../../shared/shared.dart';

/// Filtro de status da agenda do dono.
enum AppointmentFilter {
  active("Todos", {ScheduleState.scheduled, ScheduleState.completed}),
  scheduled("Agendados", {ScheduleState.scheduled}),
  completed("Concluídos", {ScheduleState.completed}),
  canceled("Cancelados", {ScheduleState.canceled});

  final String label;
  final Set<ScheduleState> states;

  const AppointmentFilter(this.label, this.states);
}

/// Agenda do dono: agendamentos do dia, com filtros e ações.
final class OwnerSchedulesController extends GetxController {
  static const pageSize = 50;

  final String companyId;

  final _service = Get.find<IOwnerScheduleService>();
  final _company = Get.find<ICompanyService>();

  final day = DateTime.now().obs;
  final filter = AppointmentFilter.active.obs;
  final employeeId = RxnString();
  final employees = <Employee>[].obs;

  final items = <Schedule>[].obs;
  final loading = false.obs;
  final loadingMore = false.obs;
  final hasMore = false.obs;
  final loaded = false.obs;
  final error = "".obs;

  /// Id do agendamento com uma ação em andamento.
  final busyId = RxnString();

  final query = "".obs;
  final searchController = TextEditingController();

  int _page = 1;

  OwnerSchedulesController(this.companyId);

  @override
  void onInit() {
    super.onInit();
    load();
    _loadEmployees();
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  /// Com busca, a consulta ignora o dia e traz do mais recente ao mais antigo.
  bool get searching => query.value.trim().isNotEmpty;

  bool get isToday => _sameDay(day.value, DateTime.now());

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> _loadEmployees() async {
    final res = await _company.getCompanyEmployees(companyId);
    if (res.result) employees.assignAll(res.data ?? const []);
  }

  void goToDay(DateTime value) {
    day.value = DateTime(value.year, value.month, value.day);
    load();
  }

  void shiftDay(int days) {
    final d = day.value;
    goToDay(DateTime(d.year, d.month, d.day + days));
  }

  void goToToday() => goToDay(DateTime.now());

  void setFilter(AppointmentFilter value) {
    if (filter.value == value) return;
    filter.value = value;
    load();
  }

  void setEmployee(String? id) {
    if (employeeId.value == id) return;
    employeeId.value = id;
    load();
  }

  void search(String text) {
    query.value = text;
    load();
  }

  void clearSearch() {
    searchController.clear();
    if (query.value.isNotEmpty) search("");
  }

  Future<void> load({bool more = false}) async {
    if (loading.value || loadingMore.value) return;
    if (more && !hasMore.value) return;

    more ? loadingMore.value = true : loading.value = true;
    error.value = "";

    final page = more ? _page + 1 : 1;
    final d = day.value;

    final res = await _service.getAppointments(
      companyId,
      from: searching ? null : DateTime(d.year, d.month, d.day),
      to: searching ? null : DateTime(d.year, d.month, d.day, 23, 59, 59, 999),
      employeeId: employeeId.value,
      states: filter.value.states,
      search: query.value,
      descending: searching,
      page: page,
      limit: pageSize,
    );

    if (res.result) {
      final received = res.data ?? const <Schedule>[];
      more ? items.addAll(received) : items.assignAll(received);
      _page = page;
      hasMore.value = received.length >= pageSize;
      loaded.value = true;
    } else {
      error.value = res.description.hasContent
          ? res.description
          : "Não foi possível carregar os agendamentos";
    }

    loading.value = false;
    loadingMore.value = false;
  }

  bool canComplete(Schedule s) =>
      s.isScheduled && !s.isCanceled && !s.startsAt.isAfter(DateTime.now());

  bool canCancel(Schedule s) =>
      s.isScheduled && !s.isCanceled && s.startsAt.isAfter(DateTime.now());

  /// Retorna `true` quando concluiu.
  Future<bool> complete(Schedule s) async {
    busyId.value = s.id;
    final res = await _service.completeAppointment(companyId, s.id);
    busyId.value = null;

    if (!res.result) {
      showSnk(
        res.description.hasContent
            ? res.description
            : "Não foi possível concluir o agendamento",
        response: res,
      );
      return false;
    }

    await _reload();
    return true;
  }

  /// Retorna `true` quando cancelou.
  Future<bool> cancel(Schedule s, String reason) async {
    busyId.value = s.id;
    final res = await _service.cancelAppointment(companyId, s.id, reason);
    busyId.value = null;

    if (!res.result) {
      showSnk(
        res.description.hasContent
            ? res.description
            : "Não foi possível cancelar o agendamento",
        response: res,
      );
      return false;
    }

    await _reload();
    return true;
  }

  Future<void> _reload() async {
    // Aguarda uma carga em andamento antes de recarregar com o estado novo.
    while (loading.value || loadingMore.value) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    await load();
  }
}
