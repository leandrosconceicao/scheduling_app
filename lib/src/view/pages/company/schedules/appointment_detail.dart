import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../domain/domain.dart';
import '../../../../shared/shared.dart';
import '../../../view.dart';

/// Abre o detalhe do agendamento com as ações disponíveis.
Future<void> showAppointmentDetail(
  BuildContext context,
  OwnerSchedulesController controller,
  Schedule schedule,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    constraints: const BoxConstraints(maxWidth: 560),
    builder: (_) => _AppointmentDetail(controller: controller, schedule: schedule),
  );
}

String _two(int n) => n.toString().padLeft(2, "0");

class _AppointmentDetail extends StatelessWidget {
  final OwnerSchedulesController controller;
  final Schedule schedule;

  const _AppointmentDetail({required this.controller, required this.schedule});

  @override
  Widget build(BuildContext context) {
    final s = schedule;
    final client = s.client;
    final type = s.typeDetail;
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const .all(24.0),
        child: Column(
          crossAxisAlignment: .start,
          spacing: 12,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    client?.name.isNotEmpty == true ? client!.name : "Cliente",
                    style: textTheme.titleLarge,
                  ),
                ),
                StateBadge(schedule: s),
              ],
            ),
            _Line(
              MdiIcons.calendarClockOutline,
              "${_two(s.startsAt.day)}/${_two(s.startsAt.month)}/${s.startsAt.year} · "
              "${s.startsAt.onlyHours} às ${s.endsAt.onlyHours}",
            ),
            if (type != null)
              _Line(MdiIcons.contentCut, "${type.name} · ${type.price.ptBrCoin}"),
            if (s.employee != null && s.employee!.name.isNotEmpty)
              _Line(MdiIcons.accountOutline, s.employee!.name),
            if (client != null && client.phoneNumber.isNotEmpty)
              _Line(MdiIcons.phoneOutline, client.phoneNumber),
            if (s.isCanceled) ...[
              _Line(MdiIcons.closeCircleOutline, _cancelText(s.cancellation)),
              if (s.cancellation?.reason.isNotEmpty == true)
                _Line(MdiIcons.textBoxOutline, s.cancellation!.reason),
            ],
            const SizedBox(height: 4),
            Obx(() {
              final busy = controller.busyId.value == s.id;

              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (client != null && client.phoneNumber.isNotEmpty)
                    OutlinedButton.icon(
                      icon: Icon(MdiIcons.messageTextOutline),
                      label: const Text("WhatsApp"),
                      onPressed: () => openLink(
                        Uri.parse(
                          "https://wa.me/${client.phoneNumber.replaceAll(RegExp(r'\D'), '')}",
                        ),
                      ),
                    ),
                  if (controller.canComplete(s))
                    FilledButton.icon(
                      icon: Icon(MdiIcons.check),
                      label: const Text("Concluir"),
                      onPressed: busy ? null : () => _complete(context),
                    ),
                  if (controller.canCancel(s))
                    OutlinedButton.icon(
                      icon: Icon(MdiIcons.closeCircleOutline),
                      label: const Text("Cancelar"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.error,
                      ),
                      onPressed: busy ? null : () => _cancel(context),
                    ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  static String _cancelText(ScheduleCancellation? c) => switch (c?.canceledBy) {
    CancellationOrigin.company => "Cancelado pelo estabelecimento",
    CancellationOrigin.client => "Cancelado pelo cliente",
    null => "Cancelado",
  };

  Future<void> _complete(BuildContext context) async {
    final navigator = Navigator.of(context);
    if (await controller.complete(schedule)) navigator.pop();
  }

  Future<void> _cancel(BuildContext context) async {
    final navigator = Navigator.of(context);
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => const CancelReasonDialog(),
    );

    if (reason == null) return;
    if (await controller.cancel(schedule, reason)) navigator.pop();
  }
}

class _Line extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Line(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: .start,
      spacing: 12,
      children: [
        Icon(icon, size: 20),
        Expanded(child: Text(text)),
      ],
    );
  }
}

/// Pede o motivo (obrigatório) do cancelamento pela empresa.
class CancelReasonDialog extends StatefulWidget {
  const CancelReasonDialog({super.key});

  static const maxLength = 500;

  @override
  State<CancelReasonDialog> createState() => _CancelReasonDialogState();
}

class _CancelReasonDialogState extends State<CancelReasonDialog> {
  final _text = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _confirm() {
    final reason = _text.text.trim();
    if (reason.isEmpty) {
      setState(() => _error = "Informe o motivo do cancelamento");
      return;
    }
    Navigator.of(context).pop(reason);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Cancelar agendamento"),
      content: TextField(
        controller: _text,
        autofocus: true,
        maxLines: 3,
        maxLength: CancelReasonDialog.maxLength,
        decoration: InputDecoration(
          labelText: "Motivo",
          helperText: "O cliente verá o motivo informado.",
          errorText: _error,
        ),
        onChanged: (_) {
          if (_error != null) setState(() => _error = null);
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("Voltar"),
        ),
        FilledButton(onPressed: _confirm, child: const Text("Cancelar agendamento")),
      ],
    );
  }
}
