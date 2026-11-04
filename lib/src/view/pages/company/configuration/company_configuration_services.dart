import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:shimmer/shimmer.dart';

import '../../../../domain/domain.dart';
import '../../../../shared/shared.dart';
import '../../../view.dart';

class CompanyConfigurationServices extends GetView<CompanyServicesController> {
  const CompanyConfigurationServices({super.key});

  Future<void> _openForm(BuildContext context, [ScheduleType? type]) async {
    final saved = await CompanyServiceForm.show(
      context,
      controller,
      type: type,
    );

    if (saved == null) return;

    final action = type == null ? "adicionado" : "atualizado";
    showSnk("Serviço “${saved.name}” $action", icon: MdiIcons.check);
  }

  Future<void> _confirmRemove(ScheduleType type) async {
    final confirmed = await AppAlertDialog.confirmRequest(
      title: "Excluir serviço?",
      message:
          "“${type.name}” deixará de aparecer para novos agendamentos. "
          "Os agendamentos já feitos com este serviço são mantidos.",
      cancelLabel: "Cancelar",
      confirmLabel: "Excluir",
      destructive: true,
    );

    if (confirmed != true) return;

    final res = await controller.remove(type);

    if (res.result) {
      showSnk("Serviço “${type.name}” excluído", icon: MdiIcons.check);
      return;
    }

    showSnk(
      res.description.hasContent
          ? res.description
          : "Não foi possível excluir “${type.name}”",
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= servicesWideBreakpoint;

    return Scaffold(
      appBar: AppBar(title: Text("Serviços")),
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
      label: Text("Novo serviço", style: TextStyle(fontWeight: .bold)),
    );
  }

  Widget _content(BuildContext context, bool isWide) {
    final isLoading = controller.loading.value;
    final error = controller.loadError.value;
    final total = controller.types.length;
    final visible = controller.visibleTypes;
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
              title: "Nenhum serviço cadastrado",
              message:
                  "Cadastre o primeiro serviço para que seus clientes possam fazer agendamentos.",
            ),
          )
        else if (visible.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _MessageState(
              title: "Nenhum resultado",
              message: "Não encontramos serviços para “$query”.",
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
      leading: Icon(MdiIcons.contentCut, color: golden),
      title: Text("Serviços cadastrados", style: TextStyle(fontWeight: .bold)),
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

    final label = "$total ${total == 1 ? "serviço" : "serviços"}";

    return controller.query.value.trim().isEmpty
        ? label
        : "$visibleCount de $label";
  }

  Widget _cards(BuildContext context, List<ScheduleType> types) {
    final highlightedId = controller.highlightedId.value;
    final deletingId = controller.deletingId.value;

    return SliverList.separated(
      itemCount: types.length,
      separatorBuilder: (_, _) => Padding(padding: const .only(bottom: 16.0)),
      itemBuilder: (_, i) {
        final type = types[i];

        return ListTile(
          contentPadding: const .fromLTRB(16.0, 8.0, 8.0, 8.0),
          shape: RoundedRectangleBorder(
            borderRadius: 8.borderRadius,
            side: BorderSide(color: type.id == highlightedId ? golden : grey),
          ),
          title: Text(type.name, style: TextStyle(fontWeight: .bold)),
          subtitle: Text(type.price.ptBrCoin),
          trailing: _actions(context, type, deletingId),
        );
      },
    );
  }

  Widget _table(BuildContext context, List<ScheduleType> types) {
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
            name: Text("Serviço", style: headerStyle),
            price: Text("Preço", style: headerStyle, textAlign: .end),
            updatedAt: Text("Atualizado em", style: headerStyle),
            actions: Text("Ações", style: headerStyle, textAlign: .end),
          ),
          for (final type in types)
            DecoratedBox(
              decoration: BoxDecoration(
                color: type.id == highlightedId
                    ? golden.withValues(alpha: .14)
                    : null,
                border: Border(top: BorderSide(color: grey)),
              ),
              child: _tableRow(
                name: Text(type.name, style: TextStyle(fontWeight: .bold)),
                price: Text(type.price.ptBrCoin, textAlign: .end),
                updatedAt: Text(_dateLabel(type.updatedAt)),
                actions: _actions(context, type, deletingId),
              ),
            ),
        ],
      ),
    );
  }

  Widget _tableRow({
    required Widget name,
    required Widget price,
    required Widget updatedAt,
    required Widget actions,
  }) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: Padding(
        padding: const .fromLTRB(16.0, 4.0, 8.0, 4.0),
        child: Row(
          spacing: 16.0,
          children: [
            Expanded(child: name),
            SizedBox(width: 130, child: price),
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

  Widget _actions(BuildContext context, ScheduleType type, String? deletingId) {
    final isBusy = deletingId != null;

    return Row(
      mainAxisSize: .min,
      children: [
        IconButton(
          tooltip: "Editar ${type.name}",
          onPressed: isBusy ? null : () => _openForm(context, type),
          icon: Icon(MdiIcons.pencilOutline),
        ),
        if (deletingId == type.id)
          const SizedBox(width: 48, height: 48, child: LoadingIcon())
        else
          IconButton(
            tooltip: "Excluir ${type.name}",
            color: white,
            onPressed: isBusy ? null : () => _confirmRemove(type),
            icon: Icon(MdiIcons.trashCanOutline),
          ),
      ],
    );
  }
}

class _SearchField extends GetView<CompanyServicesController> {
  const _SearchField();

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller.searchController,
      textInputAction: .search,
      decoration: InputDecoration(
        hintText: "Buscar serviço",
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
          label: "Carregando serviços",
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
                : "Não foi possível carregar os serviços.",
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
          if (icon) Icon(MdiIcons.contentCut, color: golden, size: 48),
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
