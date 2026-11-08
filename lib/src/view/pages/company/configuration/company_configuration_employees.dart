import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:shimmer/shimmer.dart';

import '../../../../domain/domain.dart';
import '../../../../shared/shared.dart';
import '../../../view.dart';

class CompanyConfigurationEmployees
    extends GetView<CompanyEmployeesController> {
  const CompanyConfigurationEmployees({super.key});

  Future<void> _openForm(BuildContext context, [Employee? employee]) async {
    final result = await CompanyEmployeeForm.show(
      context,
      controller,
      employee: employee,
    );

    final saved = result?.employee;

    if (result == null || saved == null) return;

    final action = employee == null ? "adicionado" : "atualizado";

    if (result.photoError != null) {
      showSnk(
        "Barbeiro “${saved.name}” $action, mas a foto não foi enviada: "
        "${result.photoError}",
      );
      return;
    }

    showSnk("Barbeiro “${saved.name}” $action", icon: MdiIcons.check);
  }

  Future<void> _confirmRemove(Employee employee) async {
    final confirmed = await AppAlertDialog.confirmRequest(
      title: "Excluir barbeiro?",
      message:
          "“${employee.name}” deixará de aparecer para novos agendamentos. "
          "Os agendamentos já feitos com este barbeiro são mantidos.",
      cancelLabel: "Cancelar",
      confirmLabel: "Excluir",
      destructive: true,
    );

    if (confirmed != true) return;

    final res = await controller.remove(employee);

    if (res.result) {
      showSnk("Barbeiro “${employee.name}” excluído", icon: MdiIcons.check);
      return;
    }

    showSnk(
      res.description.hasContent
          ? res.description
          : "Não foi possível excluir “${employee.name}”",
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= servicesWideBreakpoint;

    return Scaffold(
      appBar: AppBar(title: Text("Barbeiros")),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: Obx(() => _content(context, isWide)),
        ),
      ),
      bottomNavigationBar: isWide
          ? null
          : Obx(() {
              if (controller.loading.value ||
                  controller.loadError.value.isNotEmpty) {
                return const SizedBox.shrink();
              }

              return SafeArea(
                child: Padding(
                  padding: const .symmetric(horizontal: 16.0, vertical: 24.0),
                  child: SizedBox(height: 48, child: _newButton(context)),
                ),
              );
            }),
    );
  }

  Widget _newButton(BuildContext context) {
    return FilledButton.icon(
      onPressed: () => _openForm(context),
      icon: Icon(MdiIcons.plus),
      label: Text("Novo barbeiro", style: TextStyle(fontWeight: .bold)),
    );
  }

  Widget _content(BuildContext context, bool isWide) {
    final isLoading = controller.loading.value;
    final error = controller.loadError.value;
    final total = controller.employees.length;
    final visible = controller.visibleEmployees;
    final query = controller.query.value;
    final isReady = !isLoading && error.isEmpty;

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const .fromLTRB(16.0, 8.0, 16.0, 16.0),
          sliver: SliverToBoxAdapter(
            child: _toolbar(context, isWide, isReady, total, visible.length),
          ),
        ),
        if (isLoading)
          const _LoadingList()
        else if (error.isNotEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _ErrorState(message: error, onRetry: controller.load),
          )
        else if (total == 0)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: _MessageState(
              icon: true,
              title: "Nenhum barbeiro cadastrado",
              message:
                  "Cadastre o primeiro barbeiro para que seus clientes possam escolher com quem agendar.",
            ),
          )
        else if (visible.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _MessageState(
              title: "Nenhum resultado",
              message: "Não encontramos barbeiros para “$query”.",
              action: TextButton(
                onPressed: controller.searchController.clear,
                child: const Text("Limpar busca"),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const .fromLTRB(16.0, 0, 16.0, 16.0),
            sliver: isWide
                ? SliverToBoxAdapter(child: _table(context, visible))
                : _cards(context, visible),
          ),
      ],
    );
  }

  Widget _toolbar(
    BuildContext context,
    bool isWide,
    bool isReady,
    int total,
    int visibleCount,
  ) {
    final hasSearch = isReady && controller.showSearch;

    final section = ListTile(
      contentPadding: .zero,
      leading: Icon(MdiIcons.accountGroupOutline, color: golden),
      title: Text("Barbeiros cadastrados", style: TextStyle(fontWeight: .bold)),
      subtitle: Text(_countLabel(isReady, total, visibleCount)),
    );

    if (!isWide) {
      return Column(
        spacing: 8.0,
        children: [section, if (hasSearch) const _SearchField()],
      );
    }

    return Row(
      spacing: 16.0,
      children: [
        Expanded(child: section),
        if (hasSearch) const SizedBox(width: 280, child: _SearchField()),
        if (isReady) SizedBox(height: 48, child: _newButton(context)),
      ],
    );
  }

  String _countLabel(bool isReady, int total, int visibleCount) {
    if (controller.loading.value) return "Carregando…";
    if (!isReady) return "Indisponível";

    final label = "$total ${total == 1 ? "barbeiro" : "barbeiros"}";

    return controller.query.value.trim().isEmpty
        ? label
        : "$visibleCount de $label";
  }

  Widget _rating(Employee employee) {
    if (employee.rating <= 0) return const Text("Sem avaliações");

    return Row(
      mainAxisSize: .min,
      spacing: 4.0,
      children: [
        Icon(MdiIcons.star, color: golden, size: 16),
        Text(employee.rating.toStringAsFixed(1)),
      ],
    );
  }

  Widget _cards(BuildContext context, List<Employee> employees) {
    final highlightedId = controller.highlightedId.value;
    final deletingId = controller.deletingId.value;

    return SliverList.separated(
      itemCount: employees.length,
      separatorBuilder: (_, _) => Padding(padding: const .only(bottom: 16.0)),
      itemBuilder: (_, i) {
        final employee = employees[i];

        return ListTile(
          contentPadding: const .fromLTRB(16.0, 8.0, 8.0, 8.0),
          shape: RoundedRectangleBorder(
            borderRadius: 8.borderRadius,
            side: BorderSide(
              color: employee.id == highlightedId ? golden : grey,
            ),
          ),
          leading: EmployeeAvatar(
            name: employee.name,
            photoUrl: employee.profilePhotoUrl,
          ),
          title: Text(employee.name, style: TextStyle(fontWeight: .bold)),
          subtitle: _rating(employee),
          trailing: _actions(context, employee, deletingId),
        );
      },
    );
  }

  Widget _table(BuildContext context, List<Employee> employees) {
    final highlightedId = controller.highlightedId.value;
    final deletingId = controller.deletingId.value;
    final headerStyle = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(fontWeight: .bold);

    return Container(
      clipBehavior: .antiAlias,
      decoration: BoxDecoration(
        border: Border.all(color: grey),
        borderRadius: 8.borderRadius,
      ),
      child: Column(
        children: [
          _tableRow(
            avatar: const SizedBox.shrink(),
            name: Text("Barbeiro", style: headerStyle),
            rating: Text("Avaliação", style: headerStyle),
            updatedAt: Text("Atualizado em", style: headerStyle),
            actions: Text("Ações", style: headerStyle, textAlign: .end),
          ),
          for (final employee in employees)
            DecoratedBox(
              decoration: BoxDecoration(
                color: employee.id == highlightedId
                    ? golden.withValues(alpha: .14)
                    : null,
                border: Border(top: BorderSide(color: grey)),
              ),
              child: _tableRow(
                avatar: EmployeeAvatar(
                  name: employee.name,
                  photoUrl: employee.profilePhotoUrl,
                  radius: 20.0,
                ),
                name: Text(employee.name, style: TextStyle(fontWeight: .bold)),
                rating: _rating(employee),
                updatedAt: Text(_dateLabel(employee.updatedAt)),
                actions: _actions(context, employee, deletingId),
              ),
            ),
        ],
      ),
    );
  }

  Widget _tableRow({
    required Widget avatar,
    required Widget name,
    required Widget rating,
    required Widget updatedAt,
    required Widget actions,
  }) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56),
      child: Padding(
        padding: const .fromLTRB(16.0, 4.0, 8.0, 4.0),
        child: Row(
          spacing: 16.0,
          children: [
            SizedBox(width: 40, child: avatar),
            Expanded(child: name),
            SizedBox(width: 140, child: rating),
            SizedBox(width: 110, child: updatedAt),
            SizedBox(
              width: 96,
              child: Align(alignment: .centerRight, child: actions),
            ),
          ],
        ),
      ),
    );
  }

  String _dateLabel(DateTime? date) {
    return date == null ? "" : DateFormat("dd/MM/yyyy").format(date.toLocal());
  }

  Widget _actions(BuildContext context, Employee employee, String? deletingId) {
    final isBusy = deletingId != null;

    return Row(
      mainAxisSize: .min,
      children: [
        IconButton(
          tooltip: "Editar ${employee.name}",
          onPressed: isBusy ? null : () => _openForm(context, employee),
          icon: Icon(MdiIcons.pencilOutline),
        ),
        if (deletingId == employee.id)
          const SizedBox(width: 48, height: 48, child: LoadingIcon())
        else
          IconButton(
            tooltip: "Excluir ${employee.name}",
            color: white,
            onPressed: isBusy ? null : () => _confirmRemove(employee),
            icon: Icon(MdiIcons.trashCanOutline),
          ),
      ],
    );
  }
}

class _SearchField extends GetView<CompanyEmployeesController> {
  const _SearchField();

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller.searchController,
      textInputAction: .search,
      decoration: InputDecoration(
        hintText: "Buscar barbeiro",
        prefixIcon: Icon(MdiIcons.magnify),
        suffixIcon: Obx(() {
          if (controller.query.value.isEmpty) return const SizedBox.shrink();

          return IconButton(
            tooltip: "Limpar busca",
            color: white,
            onPressed: controller.searchController.clear,
            icon: Icon(MdiIcons.close),
          );
        }),
      ),
    );
  }
}

class _LoadingList extends StatelessWidget {
  const _LoadingList();

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const .symmetric(horizontal: 16.0),
      sliver: SliverToBoxAdapter(
        child: Semantics(
          label: "Carregando barbeiros",
          child: Shimmer.fromColors(
            baseColor: grey,
            highlightColor: softBlack,
            child: Column(
              spacing: 16.0,
              children: List.generate(
                5,
                (_) => Container(
                  height: 74,
                  decoration: BoxDecoration(
                    color: grey,
                    borderRadius: 8.borderRadius,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const .all(16.0),
      child: Column(
        mainAxisAlignment: .center,
        spacing: 16.0,
        children: [
          FormAlert(
            message.hasContent
                ? message
                : "Não foi possível carregar os barbeiros.",
          ),
          SizedBox(
            height: 48,
            child: OutlinedButton.icon(
              onPressed: onRetry,
              icon: Icon(MdiIcons.refresh),
              label: Text(
                "Tentar novamente",
                style: TextStyle(color: Colors.white, fontWeight: .bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  final String title;
  final String message;
  final bool icon;
  final Widget? action;

  const _MessageState({
    required this.title,
    required this.message,
    this.icon = false,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const .all(32.0),
      child: Column(
        mainAxisAlignment: .center,
        spacing: 16.0,
        children: [
          if (icon) Icon(MdiIcons.accountGroupOutline, color: golden, size: 48),
          Text(
            title,
            textAlign: .center,
            style: textTheme.titleMedium?.copyWith(fontWeight: .bold),
          ),
          Text(message, textAlign: .center),
          ?action,
        ],
      ),
    );
  }
}
