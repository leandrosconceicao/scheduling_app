import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../../../domain/domain.dart';
import '../../../../shared/shared.dart';
import '../../../view.dart';

/// Cria ou edita um barbeiro. Retorna o resultado, ou `null` se nada mudou.
class CompanyEmployeeForm extends StatefulWidget {
  final CompanyEmployeesController controller;
  final Employee? employee;

  const CompanyEmployeeForm({
    super.key,
    required this.controller,
    this.employee,
  });

  static Future<EmployeeSaveResult?> show(
    BuildContext context,
    CompanyEmployeesController controller, {
    Employee? employee,
  }) {
    final form = CompanyEmployeeForm(
      controller: controller,
      employee: employee,
    );

    if (MediaQuery.sizeOf(context).width >= servicesWideBreakpoint) {
      return showDialog<EmployeeSaveResult>(
        context: context,
        builder: (_) => Dialog(
          constraints: const BoxConstraints(maxWidth: 480),
          child: form,
        ),
      );
    }

    return showModalBottomSheet<EmployeeSaveResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      // Arrastar fecharia o formulário sem passar pelo aviso de descarte.
      enableDrag: false,
      builder: (_) => form,
    );
  }

  @override
  State<CompanyEmployeeForm> createState() => _CompanyEmployeeFormState();
}

class _CompanyEmployeeFormState extends State<CompanyEmployeeForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameFocus = FocusNode();

  late final TextEditingController _name;

  PickedImage? _photo;
  var _saving = false;
  var _confirmingDiscard = false;
  var _formError = "";

  Employee? get _employee => widget.employee;
  CompanyEmployeesController get _controller => widget.controller;

  bool get _isDirty {
    return _name.text.trim() != (_employee?.name ?? "") || _photo != null;
  }

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: _employee?.name ?? "");
    _name.addListener(_onChanged);
  }

  @override
  void dispose() {
    _name.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  void _onChanged() => setState(() {});

  String? _validateName(String? value) {
    return _controller.validateName(value, editingId: _employee?.id);
  }

  Future<void> _pickPhoto() async {
    if (_saving) return;

    setState(() => _formError = "");

    try {
      final picked = await _controller.photoPicker();

      if (!mounted || picked == null) return;

      if (picked.isTooLarge) {
        setState(() => _formError = "A imagem deve ter no máximo 2 MB.");
        return;
      }

      setState(() => _photo = picked);
    } on FormatException catch (e) {
      if (mounted) setState(() => _formError = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _formError = "Não foi possível abrir a imagem.");
      }
    }
  }

  Future<void> _submit() async {
    if (_saving) return;

    setState(() => _formError = "");

    if (!_formKey.currentState!.validate()) {
      _nameFocus.requestFocus();
      return;
    }

    final employee = _employee;

    if (employee != null && !_isDirty) {
      Navigator.of(context).pop();
      return;
    }

    setState(() => _saving = true);

    final res = employee == null
        ? await _controller.create(_name.text, photo: _photo)
        : await _controller.edit(employee, _name.text, photo: _photo);

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

    Navigator.of(context).pop(res);
  }

  Future<void> _confirmDiscard(bool didPop, EmployeeSaveResult? _) async {
    if (didPop || _saving || _confirmingDiscard) return;

    _confirmingDiscard = true;

    final discard = await AppAlertDialog.confirmRequest(
      title: "Descartar alterações?",
      message: "As alterações feitas neste barbeiro não serão salvas.",
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
    final updatedAt = _employee?.updatedAt;

    return PopScope<EmployeeSaveResult>(
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
                        _employee == null ? "Novo barbeiro" : "Editar barbeiro",
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
                Row(
                  spacing: 16.0,
                  children: [
                    EmployeeAvatar(
                      name: _name.text,
                      photoUrl: _employee?.profilePhotoUrl ?? "",
                      previewBytes: _photo?.bytes,
                      radius: 40.0,
                    ),
                    Expanded(
                      child: Align(
                        alignment: .centerLeft,
                        child: OutlinedButton.icon(
                          onPressed: _saving ? null : _pickPhoto,
                          icon: Icon(MdiIcons.imageOutline),
                          label: Text(
                            _photo != null ||
                                    (_employee?.profilePhotoUrl.hasContent ??
                                        false)
                                ? "Trocar foto"
                                : "Adicionar foto",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: .bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                TextFormField(
                  controller: _name,
                  focusNode: _nameFocus,
                  autofocus: true,
                  readOnly: _saving,
                  maxLength: CompanyEmployeesController.nameMaxLength,
                  textInputAction: .done,
                  textCapitalization: .words,
                  autovalidateMode: .onUserInteractionIfError,
                  validator: _validateName,
                  onFieldSubmitted: (_) => _submit(),
                  decoration: const InputDecoration(
                    labelText: "Nome do barbeiro",
                    helperText: "É assim que o cliente verá o barbeiro",
                  ),
                ),
                Text(
                  "JPEG, PNG ou WebP, até 2 MB. A foto é ajustada automaticamente.",
                  style: textTheme.bodySmall,
                ),
                Row(
                  spacing: 8.0,
                  children: [
                    Icon(MdiIcons.informationOutline, size: 20),
                    Expanded(
                      child: Text(
                        _employee == null
                            ? "A avaliação aparece depois dos primeiros atendimentos."
                            : "A avaliação vem dos atendimentos e não pode ser editada.",
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
