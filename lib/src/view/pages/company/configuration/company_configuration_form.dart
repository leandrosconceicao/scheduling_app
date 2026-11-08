import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../domain/domain.dart';
import '../../../../shared/shared.dart';
import '../../../view.dart';

/// Campo de texto da seção. [time] abre o seletor de horário em vez do teclado.
class _Spec {
  final String key;
  final String label;
  final bool half;
  final String? help;
  final bool time;
  final TextInputType? keyboard;
  final List<TextInputFormatter> formatters;
  final bool locked;
  final String? lockedValue;

  const _Spec(
    this.key,
    this.label, {
    this.half = false,
    this.help,
    this.time = false,
    this.keyboard,
    this.formatters = const [],
    this.locked = false,
    this.lockedValue,
  });
}

TextInputFormatter _format(String Function(String) fn) {
  return TextInputFormatter.withFunction((_, next) {
    final text = fn(next.text);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  });
}

/// Formulário da seção aberta (campos, avisos e, no layout largo, ações).
class CompanySectionForm extends StatelessWidget {
  final CompanyConfigurationController controller;
  final bool wide;

  const CompanySectionForm({
    super.key,
    required this.controller,
    required this.wide,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final section = controller.section.value;
      final company = controller.company;
      if (section == null || company == null) return const SizedBox.shrink();

      return Column(
        crossAxisAlignment: .start,
        spacing: 24,
        children: [
          if (controller.formError.value.isNotEmpty)
            Semantics(
              liveRegion: true,
              child: FormAlert(controller.formError.value),
            ),
          if (section == ConfigSection.dados) _LogoRow(controller: controller),
          ..._groups(section, company),
          if (wide) _Actions(controller: controller),
        ],
      );
    });
  }

  List<Widget> _groups(ConfigSection section, Company company) {
    Widget group(String? title, List<Widget> children) =>
        _FormGroup(title: title, children: children);
    Widget fields(List<_Spec> specs) =>
        _Fields(controller: controller, specs: specs);
    const time = true;

    return switch (section) {
      ConfigSection.dados => [
        group(null, [
          fields([
            _Spec(
              CompanySettings.name,
              "Nome da empresa",
              help: "É assim que o cliente verá a empresa",
              formatters: [LengthLimitingTextInputFormatter(200)],
            ),
            _Spec(
              "cnpj",
              "CNPJ",
              locked: true,
              lockedValue: company.cnpj,
              help: "Somente para consulta",
            ),
            _Spec(
              "subdomain",
              "Endereço da página",
              locked: true,
              lockedValue: company.subdomain,
              help: "Somente para consulta",
            ),
          ]),
        ]),
      ],
      ConfigSection.funcionamento => [
        group("Horário de atendimento", [
          fields([
            const _Spec(
              CompanySettings.open,
              "Abertura",
              half: true,
              time: time,
            ),
            const _Spec(
              CompanySettings.close,
              "Fechamento",
              half: true,
              time: time,
            ),
          ]),
        ]),
        group("Intervalo de almoço", [
          fields([
            const _Spec(
              CompanySettings.lunchStart,
              "Início",
              half: true,
              time: time,
            ),
            const _Spec(
              CompanySettings.lunchEnd,
              "Fim",
              half: true,
              time: time,
            ),
          ]),
        ]),
        group("Dias de funcionamento", [_DaysPicker(controller: controller)]),
        group("Duração de cada horário", [
          _PeriodPicker(controller: controller),
        ]),
        _ScheduleNote(controller: controller),
        group("Regras do agendamento", [
          fields([
            _Spec(
              CompanySettings.lock,
              "Reserva temporária do horário (min)",
              keyboard: TextInputType.number,
              help:
                  "Tempo que o horário fica reservado enquanto o cliente "
                  "conclui o agendamento",
              formatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(3),
              ],
            ),
          ]),
        ]),
      ],
      ConfigSection.endereco => [
        group(null, [
          fields([
            _Spec(
              CompanySettings.zip,
              "CEP",
              half: true,
              keyboard: TextInputType.number,
              formatters: [_format(CompanySettings.maskZip)],
            ),
            _Spec(
              CompanySettings.state,
              "Estado",
              half: true,
              formatters: [
                _format(
                  (v) => v
                      .toUpperCase()
                      .replaceAll(RegExp(r"[^A-Z]"), "")
                      .characters
                      .take(2)
                      .toString(),
                ),
              ],
            ),
            const _Spec(CompanySettings.street, "Rua"),
            const _Spec(CompanySettings.number, "Número", half: true),
            const _Spec(
              CompanySettings.complement,
              "Complemento",
              half: true,
              help: "Opcional",
            ),
            const _Spec(CompanySettings.neighborhood, "Bairro"),
            const _Spec(CompanySettings.city, "Cidade"),
          ]),
        ]),
      ],
      ConfigSection.contato => [
        group("Contato", [
          fields([
            _Spec(
              CompanySettings.phone,
              "Telefone",
              help: "Opcional",
              keyboard: TextInputType.phone,
              formatters: [_format(CompanySettings.maskPhone)],
            ),
            _Spec(
              CompanySettings.whatsapp,
              "WhatsApp",
              help: "Opcional",
              keyboard: TextInputType.phone,
              formatters: [_format(CompanySettings.maskPhone)],
            ),
            const _Spec(
              CompanySettings.email,
              "E-mail",
              help: "Opcional",
              keyboard: TextInputType.emailAddress,
            ),
          ]),
        ]),
        group("Redes sociais", [
          fields([
            _Spec(
              CompanySettings.instagram,
              "Instagram",
              help: "Nome de usuário, sem @. Opcional",
              formatters: [_format((v) => v.replaceFirst(RegExp(r"^@"), ""))],
            ),
            const _Spec(
              CompanySettings.facebook,
              "Facebook",
              help: "Nome da página. Opcional",
            ),
          ]),
        ]),
      ],
    };
  }
}

class _FormGroup extends StatelessWidget {
  final String? title;
  final List<Widget> children;

  const _FormGroup({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: .start,
      spacing: 12,
      children: [
        if (title != null)
          Semantics(
            header: true,
            child: Text(
              title!,
              style: const TextStyle(fontWeight: .bold, color: white),
            ),
          ),
        ...children,
      ],
    );
  }
}

class _Fields extends StatelessWidget {
  final CompanyConfigurationController controller;
  final List<_Spec> specs;

  const _Fields({required this.controller, required this.specs});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final half = (box.maxWidth - 12) / 2;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final spec in specs)
              SizedBox(
                width: spec.half ? half : box.maxWidth,
                child: spec.locked
                    ? _LockedField(spec: spec)
                    : _Field(controller: controller, spec: spec),
              ),
          ],
        );
      },
    );
  }
}

class _Field extends StatelessWidget {
  final CompanyConfigurationController controller;
  final _Spec spec;

  const _Field({required this.controller, required this.spec});

  Future<void> _pickTime(
    BuildContext context,
    TextEditingController text,
  ) async {
    final parts = text.text.split(":");
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.tryParse(parts.first) ?? 8,
        minute: parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
      ),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked == null) return;

    text.text =
        "${picked.hour.toString().padLeft(2, "0")}:"
        "${picked.minute.toString().padLeft(2, "0")}";
  }

  @override
  Widget build(BuildContext context) {
    final text = controller.field(spec.key);

    return Obx(() {
      final error = controller.errors[spec.key];
      final saving = controller.saving.value;

      return TextField(
        controller: text,
        readOnly: saving || spec.time,
        keyboardType: spec.keyboard,
        inputFormatters: spec.formatters,
        textInputAction: TextInputAction.next,
        onTap: spec.time && !saving ? () => _pickTime(context, text) : null,
        decoration: InputDecoration(
          labelText: spec.label,
          errorText: error,
          helperText: error == null ? spec.help : null,
          helperMaxLines: 3,
          errorMaxLines: 3,
          suffixIcon: spec.time ? Icon(MdiIcons.clockOutline) : null,
        ),
      );
    });
  }
}

class _LockedField extends StatelessWidget {
  final _Spec spec;

  const _LockedField({required this.spec});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: ValueKey("${spec.key}:${spec.lockedValue}"),
      initialValue: spec.lockedValue,
      readOnly: true,
      decoration: InputDecoration(
        labelText: spec.label,
        helperText: spec.help,
        filled: false,
        suffixIcon: Icon(MdiIcons.lockOutline, color: white),
      ),
    );
  }
}

class _DaysPicker extends StatelessWidget {
  final CompanyConfigurationController controller;

  const _DaysPicker({required this.controller});

  // Semana começando na segunda.
  static const _order = [1, 2, 3, 4, 5, 6, 0];

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final selected = controller.workingDays;
      final error = controller.errors[CompanySettings.days];

      return Column(
        crossAxisAlignment: .start,
        spacing: 8,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final day in _order)
                FilterChip(
                  label: Text(WeekDays.shortName(day)),
                  tooltip: WeekDays.name(day),
                  selected: selected.contains(day),
                  showCheckmark: false,
                  selectedColor: golden,
                  labelStyle: TextStyle(
                    fontWeight: selected.contains(day) ? .bold : .w500,
                    color: selected.contains(day) ? black : white,
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.padded,
                  onSelected: controller.saving.value
                      ? null
                      : (value) => controller.toggleDay(day, value),
                ),
            ],
          ),
          if (error != null)
            Text(
              error,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 12,
              ),
            ),
        ],
      );
    });
  }
}

class _PeriodPicker extends StatelessWidget {
  final CompanyConfigurationController controller;

  const _PeriodPicker({required this.controller});

  @override
  Widget build(BuildContext context) {
    final text = controller.field(CompanySettings.period);

    return Obx(() {
      // Lê a revisão (via slotsLabel) para acompanhar a duração escolhida.
      final slots = controller.slotsLabel;
      final current = int.tryParse(text.text) ?? 0;
      final saved =
          controller.company?.configuration.defaultPeriodInMinutes ?? 0;

      return Column(
        crossAxisAlignment: .start,
        spacing: 12,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final minutes in CompanySettings.periodOptions(saved))
                ChoiceChip(
                  label: Text("$minutes min"),
                  selected: current == minutes,
                  showCheckmark: false,
                  selectedColor: golden,
                  labelStyle: TextStyle(
                    fontWeight: current == minutes ? .bold : .w500,
                    color: current == minutes ? black : white,
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.padded,
                  onSelected: controller.saving.value
                      ? null
                      : (_) => controller.setPeriod(minutes),
                ),
            ],
          ),
          if (slots != null)
            Semantics(
              liveRegion: true,
              child: Text(slots, style: Theme.of(context).textTheme.bodySmall),
            ),
        ],
      );
    });
  }
}

class _ScheduleNote extends StatelessWidget {
  final CompanyConfigurationController controller;

  const _ScheduleNote({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!controller.scheduleChanged) return const SizedBox.shrink();

      return Semantics(
        liveRegion: true,
        child: Container(
          padding: const .symmetric(horizontal: 16.0, vertical: 12.0),
          decoration: BoxDecoration(
            border: Border.all(color: golden),
            borderRadius: 8.borderRadius,
          ),
          child: Row(
            crossAxisAlignment: .start,
            spacing: 12,
            children: [
              Icon(MdiIcons.informationOutline),
              const Expanded(
                child: Text(
                  "Os agendamentos já feitos continuam valendo. "
                  "A mudança vale para os novos agendamentos.",
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

class _LogoRow extends StatelessWidget {
  final CompanyConfigurationController controller;

  const _LogoRow({required this.controller});

  Future<void> _change() async {
    final res = await controller.changeLogo();
    if (res == null) return;

    if (res.result) {
      showSnk("Logo atualizada", icon: MdiIcons.check);
      return;
    }

    showSnk(
      res.description.hasContent
          ? res.description
          : "Não foi possível enviar a logo",
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 16,
      children: [
        CompanyLogo(company: controller.company!),
        Obx(() {
          final busy = controller.logoBusy.value;

          return OutlinedButton(
            onPressed: busy || controller.saving.value ? null : _change,
            child: busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text("Alterar logo"),
          );
        }),
      ],
    );
  }
}

class _Actions extends StatelessWidget {
  final CompanyConfigurationController controller;

  const _Actions({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Obx(
        () => Row(
          mainAxisSize: .min,
          spacing: 8,
          children: [
            TextButton(
              onPressed: controller.saving.value || !controller.isDirty
                  ? null
                  : controller.discard,
              child: const Text("Descartar alterações"),
            ),
            SizedBox(height: 48, child: SaveButton(controller: controller)),
          ],
        ),
      ),
    );
  }
}

/// Botão "Salvar alterações" (rodapé no celular, ações na tela larga).
class SaveButton extends StatelessWidget {
  final CompanyConfigurationController controller;

  const SaveButton({super.key, required this.controller});

  Future<void> _save(bool wide) async {
    final title = controller.section.value?.title ?? "";
    final result = await controller.save();

    switch (result) {
      case ConfigSaveResult.saved:
        if (!wide) controller.open(null);
        showSnk("$title: alterações salvas", icon: MdiIcons.check);
      case ConfigSaveResult.unchanged:
        if (wide) {
          showSnk("Nenhuma alteração para salvar", icon: MdiIcons.check);
        } else {
          controller.open(null);
        }
      case ConfigSaveResult.invalid || ConfigSaveResult.failed:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= configWideBreakpoint;

    return Obx(() {
      final saving = controller.saving.value;

      return FilledButton(
        onPressed: saving ? null : () => _save(wide),
        child: saving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text(
                "Salvar alterações",
                style: TextStyle(fontWeight: .bold),
              ),
      );
    });
  }
}
