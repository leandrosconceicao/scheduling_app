import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../domain/domain.dart';
import '../../../../routes/routes.dart';
import '../../../../shared/shared.dart';
import '../../../view.dart';
import 'company_configuration_form.dart';

/// A partir dessa largura o menu e a seção ficam lado a lado.
const configWideBreakpoint = 960.0;

class CompanyConfigurationPage extends GetView<CompanyConfigurationController> {
  const CompanyConfigurationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= configWideBreakpoint;

    return Obx(() {
      final ready = controller.company != null;
      final section = controller.section.value;

      // Na tela larga sempre há uma seção aberta.
      if (ready && wide && section == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (controller.section.value == null) {
            controller.open(ConfigSection.dados);
          }
        });
      }

      final inSection = ready && !wide && section != null;

      return PopScope(
        // Voltar numa seção (botão, sistema ou navegador) retorna ao menu.
        canPop: !inSection,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) controller.requestOpen(null);
        },
        child: Scaffold(
          appBar: AppBar(
            leading: inSection
                ? IconButton(
                    tooltip: "Voltar para Configurações",
                    icon: Icon(MdiIcons.arrowLeft),
                    onPressed: controller.saving.value
                        ? null
                        : () => controller.requestOpen(null),
                  )
                : null,
            title: Text(inSection ? section.title : "Configurações"),
            actions: [
              if (!inSection)
                IconButton(
                  tooltip: "Agenda",
                  icon: Icon(MdiIcons.calendarMonthOutline),
                  onPressed: () =>
                      GoRouter.of(context).goAdminSchedules(controller.companyId),
                ),
            ],
          ),
          body: _body(context, wide),
          bottomNavigationBar: inSection
              ? SafeArea(
                  child: Padding(
                    padding: const .all(16.0),
                    child: SizedBox(
                      height: 48,
                      child: SaveButton(controller: controller),
                    ),
                  ),
                )
              : null,
        ),
      );
    });
  }

  Widget _body(BuildContext context, bool wide) {
    final res = controller.companyData.value;

    if (res == null) return const _Loading();

    if (!res.result || res.data == null) {
      return _LoadError(
        message: res.description,
        onRetry: controller.loadCompanyData,
      );
    }

    final hub = _Hub(controller: controller, wide: wide);
    final section = controller.section.value;

    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: Padding(
            padding: wide
                ? const .symmetric(horizontal: 24.0, vertical: 32.0)
                : const .fromLTRB(16.0, 8.0, 16.0, 24.0),
            child: wide
                ? Row(
                    crossAxisAlignment: .start,
                    spacing: 32,
                    children: [
                      SizedBox(width: 320, child: hub),
                      Expanded(
                        child: Container(
                          padding: const .all(24.0),
                          decoration: BoxDecoration(
                            border: Border.all(color: grey),
                            borderRadius: 8.borderRadius,
                          ),
                          child: section == null
                              ? const SizedBox.shrink()
                              : Column(
                                  crossAxisAlignment: .start,
                                  spacing: 24,
                                  children: [
                                    Text(
                                      section.title,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleLarge,
                                    ),
                                    CompanySectionForm(
                                      controller: controller,
                                      wide: true,
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  )
                : section == null
                ? hub
                : CompanySectionForm(controller: controller, wide: false),
          ),
        ),
      ),
    );
  }
}

class _Hub extends StatelessWidget {
  final CompanyConfigurationController controller;
  final bool wide;

  const _Hub({required this.controller, required this.wide});

  @override
  Widget build(BuildContext context) {
    final company = controller.company!;
    final config = company.configuration;
    final address = company.address;
    final filled = ConfigSection.contato.keys
        .where(
          (k) => CompanySettings.draftOf(
            company,
            ConfigSection.contato,
          )[k]!.isNotEmpty,
        )
        .length;

    return Column(
      crossAxisAlignment: .start,
      spacing: 24,
      children: [
        Row(
          spacing: 16,
          children: [
            CompanyLogo(company: company),
            Expanded(
              child: Column(
                crossAxisAlignment: .start,
                children: [
                  Text(
                    company.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: .bold,
                      color: white,
                    ),
                  ),
                  if (company.subdomain.isNotEmpty)
                    Text(
                      company.subdomain,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ),
          ],
        ),
        _Group("Empresa", [
          _tile(
            ConfigSection.dados,
            MdiIcons.storefrontOutline,
            "${company.name}${company.cnpj.isEmpty ? "" : " · CNPJ ${company.cnpj}"}",
          ),
          _tile(
            ConfigSection.funcionamento,
            MdiIcons.clockOutline,
            "${config.openingHours} às ${config.closingTime} · "
            "Horários de ${config.defaultPeriodInMinutes} min",
          ),
          _tile(
            ConfigSection.endereco,
            MdiIcons.mapMarkerOutline,
            address.isEmpty
                ? "Não informado"
                : [
                    address.streetLine,
                    address.cityLine,
                  ].where((e) => e.isNotEmpty).join(" · "),
          ),
          _tile(
            ConfigSection.contato,
            MdiIcons.messageTextOutline,
            "$filled de ${ConfigSection.contato.keys.length} preenchidos",
          ),
        ]),
        _Group("Catálogo", [
          _NavTile(
            icon: MdiIcons.contentCut,
            title: "Serviços",
            summary: "Cadastre e edite os serviços oferecidos",
            onTap: () => GoRouter.of(
              context,
            ).goAdminConfigServices(controller.companyId),
          ),
          _NavTile(
            icon: MdiIcons.accountGroupOutline,
            title: "Barbeiros",
            summary: "Cadastre e edite a equipe",
            onTap: () => GoRouter.of(
              context,
            ).goAdminConfigEmployees(controller.companyId),
          ),
        ]),
        TextButton.icon(
          onPressed: controller.logout,
          icon: Icon(MdiIcons.logout, size: 20),
          label: const Text("Sair da área administrativa"),
        ),
      ],
    );
  }

  Widget _tile(ConfigSection target, IconData icon, String summary) {
    return Obx(() {
      // Lê a seção sempre, para o Obx ter o que observar também no celular.
      final isOpen = controller.section.value == target;

      return _NavTile(
        icon: icon,
        title: target.title,
        summary: summary,
        current: wide && isOpen,
        onTap: () => controller.requestOpen(target),
      );
    });
  }
}

class _Group extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Group(this.title, this.children);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: .start,
      spacing: 8,
      children: [
        Semantics(
          header: true,
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: .bold,
              letterSpacing: .4,
              color: white,
            ),
          ),
        ),
        ...children,
      ],
    );
  }
}

class _NavTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String summary;
  final bool current;
  final VoidCallback onTap;

  const _NavTile({
    required this.icon,
    required this.title,
    required this.summary,
    required this.onTap,
    this.current = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      selected: current,
      selectedColor: white,
      selectedTileColor: golden.withValues(alpha: .14),
      iconColor: golden,
      minVerticalPadding: 12,
      shape: RoundedRectangleBorder(
        borderRadius: 8.borderRadius,
        side: BorderSide(color: current ? golden : grey),
      ),
      leading: Icon(icon, color: golden),
      title: Text(title, style: const TextStyle(fontWeight: .bold)),
      subtitle: Text(summary),
      trailing: Icon(MdiIcons.chevronRight),
      onTap: onTap,
    );
  }
}

/// Logo da empresa; sem imagem, mostra as iniciais do nome.
class CompanyLogo extends StatelessWidget {
  final Company company;

  const CompanyLogo({super.key, required this.company});

  String get _initials => company.name
      .split(RegExp(r"\s+"))
      .where((e) => e.isNotEmpty)
      .take(2)
      .map((e) => e[0].toUpperCase())
      .join();

  @override
  Widget build(BuildContext context) {
    final initials = Center(
      child: Text(
        _initials,
        style: const TextStyle(fontSize: 22, fontWeight: .bold, color: golden),
      ),
    );

    return Container(
      width: 72,
      height: 72,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: golden),
      ),
      child: company.logoUrl.isEmpty
          ? initials
          : CachedNetworkImage(
              imageUrl: company.logoUrl,
              fit: BoxFit.cover,
              errorWidget: (_, _, _) => initials,
              placeholder: (_, _) => initials,
            ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    Widget bone(double height, {double? width}) => Container(
      height: height,
      width: width,
      decoration: BoxDecoration(color: grey, borderRadius: 8.borderRadius),
    );

    return Semantics(
      label: "Carregando configurações",
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: Padding(
            padding: const .all(16.0),
            child: Shimmer.fromColors(
              baseColor: grey,
              highlightColor: softBlack,
              child: Column(
                spacing: 8,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: bone(72, width: 260),
                  ),
                  const SizedBox(height: 8),
                  for (var i = 0; i < 6; i++) bone(72),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _LoadError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const .all(16.0),
        child: Column(
          mainAxisSize: .min,
          spacing: 16,
          children: [
            FormAlert(
              message.hasContent
                  ? message
                  : "Não foi possível carregar as configurações. "
                        "Verifique sua conexão e tente novamente.",
            ),
            OutlinedButton(
              onPressed: onRetry,
              child: const Text("Tentar novamente"),
            ),
          ],
        ),
      ),
    );
  }
}
