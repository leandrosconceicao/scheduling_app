import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../../../domain/domain.dart';
import '../../../../shared/shared.dart';
import '../../../view.dart';

/// A partir dessa largura, a lista vira tabela e o formulário vira diálogo.
const servicesWideBreakpoint = 720.0;

/// Cria ou edita um serviço. Retorna o serviço salvo, ou `null` se nada mudou.
class CompanyServiceForm extends StatefulWidget {
  final CompanyServicesController controller;
  final ScheduleType? type;

  const CompanyServiceForm({super.key, required this.controller, this.type});

  static Future<ScheduleType?> show(
    BuildContext context,
    CompanyServicesController controller, {
    ScheduleType? type,
  }) {
    final form = CompanyServiceForm(controller: controller, type: type);

    if (MediaQuery.sizeOf(context).width >= servicesWideBreakpoint) {
      return showDialog<ScheduleType>(
        context: context,
        builder: (_) => Dialog(
          constraints: const BoxConstraints(maxWidth: 480),
          child: form,
        ),
      );
    }

    return showModalBottomSheet<ScheduleType>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      // Arrastar fecharia o formulário sem passar pelo aviso de descarte.
      enableDrag: false,
      builder: (_) => form,
    );
  }

  @override
  State<CompanyServiceForm> createState() => _CompanyServiceFormState();
}

class _CompanyServiceFormState extends State<CompanyServiceForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameFocus = FocusNode();
  final _priceFocus = FocusNode();

  late final TextEditingController _name;
  late final MoneyMaskedTextController _price;

  var _saving = false;
  var _confirmingDiscard = false;
  var _formError = "";

  ScheduleType? get _type => widget.type;
  CompanyServicesController get _controller => widget.controller;

  bool get _isDirty {
    return _name.text.trim() != (_type?.name ?? "") ||
        _price.numberValue != (_type?.price ?? 0);
  }

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: _type?.name ?? "");
    _price = MoneyMaskedTextController(
      decimalSeparator: ",",
      thousandSeparator: ".",
      leftSymbol: "R\$ ",
      initialValue: (_type?.price ?? 0).toDouble(),
    );
    _name.addListener(_onChanged);
    _price.addListener(_onChanged);
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _nameFocus.dispose();
    _priceFocus.dispose();
    super.dispose();
  }

  void _onChanged() => setState(() {});

  String? _validateName(String? value) {
    return _controller.validateName(value, editingId: _type?.id);
  }

  String? _validatePrice(String? _) {
    return _controller.validatePrice(_price.numberValue);
  }

  Future<void> _submit() async {
    if (_saving) return;

    setState(() => _formError = "");

    if (!_formKey.currentState!.validate()) {
      final firstInvalid = _validateName(_name.text) != null
          ? _nameFocus
          : _priceFocus;
      firstInvalid.requestFocus();
      return;
    }

    final type = _type;

    if (type != null && !_isDirty) {
      Navigator.of(context).pop();
      return;
    }

    setState(() => _saving = true);

    final res = type == null
        ? await _controller.create(_name.text, _price.numberValue)
        : await _controller.edit(type, _name.text, _price.numberValue);

    if (!mounted) return;

    if (!res.result) {
      setState(() {
        _saving = false;
        _formError = res.description.hasContent
            ? res.description
            : "Não foi possível salvar. Tente novamente.";
      });
      return;
    }

    Navigator.of(context).pop(res.data);
  }

  Future<void> _confirmDiscard(bool didPop, ScheduleType? _) async {
    if (didPop || _saving || _confirmingDiscard) return;

    _confirmingDiscard = true;

    final discard = await AppAlertDialog.confirmRequest(
      title: "Descartar alterações?",
      message: "As alterações feitas neste serviço não serão salvas.",
      cancelLabel: "Continuar",
      confirmLabel: "Descartar",
      destructive: true,
    );

    _confirmingDiscard = false;

    if (discard == true && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final updatedAt = _type?.updatedAt;
    final period = _controller.defaultPeriodInMinutes.value;

    return PopScope<ScheduleType>(
      canPop: !_saving && !_isDirty,
      onPopInvokedWithResult: _confirmDiscard,
      child: Padding(
        padding: .only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: SingleChildScrollView(
          padding: const .all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: .min,
              crossAxisAlignment: .stretch,
              spacing: 16.0,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _type == null ? "Novo serviço" : "Editar serviço",
                        style: textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      tooltip: "Fechar",
                      color: white,
                      onPressed: _saving
                          ? null
                          : () => Navigator.of(context).maybePop(),
                      icon: Icon(MdiIcons.close),
                    ),
                  ],
                ),
                if (_formError.isNotEmpty) FormAlert(_formError),
                TextFormField(
                  controller: _name,
                  focusNode: _nameFocus,
                  autofocus: true,
                  readOnly: _saving,
                  maxLength: CompanyServicesController.nameMaxLength,
                  textInputAction: .next,
                  textCapitalization: .sentences,
                  autovalidateMode: .onUserInteractionIfError,
                  validator: _validateName,
                  decoration: const InputDecoration(
                    labelText: "Nome do serviço",
                    helperText: "É assim que o cliente verá o serviço",
                  ),
                ),
                TextFormField(
                  controller: _price,
                  focusNode: _priceFocus,
                  readOnly: _saving,
                  keyboardType: .number,
                  textInputAction: .done,
                  autovalidateMode: .onUserInteractionIfError,
                  validator: _validatePrice,
                  onFieldSubmitted: (_) => _submit(),
                  decoration: const InputDecoration(
                    labelText: "Preço",
                    helperText: "Valor cobrado do cliente",
                  ),
                ),
                if (period > 0)
                  Row(
                    spacing: 8.0,
                    children: [
                      Icon(MdiIcons.clockOutline, size: 20),
                      Expanded(
                        child: Text(
                          "Duração de $period min, padrão para todos os serviços da empresa.",
                          style: textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                if (updatedAt != null)
                  Text(
                    "Atualizado em ${DateFormat("dd/MM/yyyy 'às' HH:mm").format(updatedAt.toLocal())}",
                    style: textTheme.bodySmall,
                  ),
                Row(
                  spacing: 8.0,
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          onPressed: _saving
                              ? null
                              : () => Navigator.of(context).maybePop(),
                          child: Text(
                            "Cancelar",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: .bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: FilledButton(
                          onPressed: _saving ? null : _submit,
                          child: _saving
                              ? const LoadingIcon()
                              : Text(
                                  "Salvar",
                                  style: TextStyle(fontWeight: .bold),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
