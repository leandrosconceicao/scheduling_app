import 'package:flutter/foundation.dart' show setEquals;
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../../application/application.dart';
import '../../../../domain/domain.dart';
import '../../../../shared/shared.dart';

/// Resultado de [CompanyConfigurationController.save].
enum ConfigSaveResult { invalid, unchanged, saved, failed }

/// Editor das configurações da empresa: uma seção por vez, com rascunho,
/// validação e aviso ao descartar alterações.
final class CompanyConfigurationController extends GetxController {
  final String companyId;

  final companyData = Rxn<ApiResponse<Company?>>();

  /// Seção aberta; `null` é o menu (só no layout estreito).
  final section = Rxn<ConfigSection>();
  final saving = false.obs;
  final logoBusy = false.obs;
  final formError = "".obs;

  /// Só depois da primeira tentativa de salvar os erros aparecem.
  final submitted = false.obs;

  /// Muda a cada edição, para os widgets reavaliarem erros e alterações.
  final _revision = 0.obs;

  final workingDays = <int>{}.obs;

  final _service = Get.find<ICompanyService>();
  final _fields = <String, TextEditingController>{};

  /// Trocáveis nos testes.
  Future<PickedImage?> Function() logoPicker = pickGalleryImage;
  Future<bool> Function() confirmDiscard = _askDiscard;

  CompanyConfigurationController(this.companyId);

  @override
  void onInit() {
    loadCompanyData();
    super.onInit();
  }

  @override
  void onClose() {
    for (final field in _fields.values) {
      field.dispose();
    }
    super.onClose();
  }

  Company? get company => companyData.value?.data;

  /// Controlador do campo [key], criado sob demanda.
  TextEditingController field(String key) {
    return _fields.putIfAbsent(
      key,
      () => TextEditingController()..addListener(() => _revision.value++),
    );
  }

  Map<String, String> get draft {
    final current = section.value;
    if (current == null) return const {};
    return {for (final key in current.keys) key: field(key).text};
  }

  Map<String, String> get errors {
    _revision.value;
    final current = section.value;
    if (!submitted.value || current == null) return const {};
    return CompanySettings.errors(
      current,
      draft,
      workingDays: workingDays.toSet(),
    );
  }

  /// Texto de apoio da duração dos horários ("até N horários por dia").
  String? get slotsLabel {
    _revision.value;
    return CompanySettings.slotsLabel(draft);
  }

  /// A duração e a mudança de horário valem só para novos agendamentos.
  bool get scheduleChanged {
    _revision.value;
    final saved = _saved;
    if (section.value != ConfigSection.funcionamento || saved == null) {
      return false;
    }
    return [
          CompanySettings.open,
          CompanySettings.close,
          CompanySettings.lunchStart,
          CompanySettings.lunchEnd,
          CompanySettings.period,
        ].any((k) => field(k).text != saved[k]) ||
        _daysChanged;
  }

  bool get isDirty {
    _revision.value;
    final saved = _saved;
    final current = section.value;
    if (saved == null || current == null) return false;
    return current.keys.any((k) => field(k).text != saved[k]) || _daysChanged;
  }

  Map<String, String>? get _saved {
    final c = company, s = section.value;
    return c == null || s == null ? null : CompanySettings.draftOf(c, s);
  }

  Set<int> get _savedDays =>
      company?.configuration.workingDays.map((e) => e.day).toSet() ?? {};

  bool get _daysChanged =>
      section.value == ConfigSection.funcionamento &&
      !setEquals(workingDays.toSet(), _savedDays);

  /// Encerra a sessão do dono; o roteador leva de volta ao login da empresa.
  void logout() => Get.find<IOwnerSessionService>().end();

  Future<void> loadCompanyData() async {
    companyData.value = null;

    if (!companyId.hasContent) {
      companyData.value = ApiResponse.notFound(
        message: "Empresa não localizada",
      );
      return;
    }

    companyData.value = await _service.getCompany(companyId);
  }

  void toggleDay(int day, bool selected) {
    if (saving.value) return;
    selected ? workingDays.add(day) : workingDays.remove(day);
    _revision.value++;
  }

  void setPeriod(int minutes) {
    if (saving.value) return;
    field(CompanySettings.period).text = "$minutes";
  }

  /// Abre [target] (ou o menu, com `null`) pedindo confirmação se houver
  /// alterações não salvas. Retorna `false` se o usuário continuou editando.
  Future<bool> requestOpen(ConfigSection? target) async {
    if (saving.value) return false;
    if (target == section.value) return true;
    if (isDirty && !await confirmDiscard()) return false;
    open(target);
    return true;
  }

  void open(ConfigSection? target) {
    section.value = target;
    submitted.value = false;
    formError.value = "";
    _resetDraft();
  }

  /// Descarta as alterações da seção aberta, após confirmar.
  Future<void> discard() async {
    if (saving.value || !isDirty) return;
    if (await confirmDiscard()) _resetDraft();
  }

  void _resetDraft() {
    final c = company, s = section.value;
    if (c == null || s == null) return;
    CompanySettings.draftOf(c, s).forEach((k, v) => field(k).text = v);
    workingDays
      ..clear()
      ..addAll(_savedDays);
    submitted.value = false;
    formError.value = "";
  }

  Future<ConfigSaveResult> save() async {
    final current = section.value;
    if (current == null || saving.value) return ConfigSaveResult.invalid;

    submitted.value = true;
    formError.value = "";
    _revision.value++;

    if (errors.isNotEmpty) return ConfigSaveResult.invalid;
    if (!isDirty) return ConfigSaveResult.unchanged;

    saving.value = true;
    final res = await _service.updateCompany(companyId, _request(current));

    if (!res.result) {
      saving.value = false;
      formError.value = res.description.hasContent
          ? res.description
          : "Não foi possível salvar. Seus dados foram mantidos; tente novamente.";
      return ConfigSaveResult.failed;
    }

    final fresh = await _service.getCompany(companyId);
    if (fresh.data != null) companyData.value = fresh;

    saving.value = false;
    submitted.value = false;
    _resetDraft();
    return ConfigSaveResult.saved;
  }

  CompanyDto _request(ConfigSection current) {
    final d = draft;
    String v(String key) => (d[key] ?? "").trim();

    return switch (current) {
      ConfigSection.dados => CompanyDto(name: v(CompanySettings.name)),
      ConfigSection.funcionamento => CompanyDto(
        configuration: CompanyConfigurationDto(
          openingHours: v(CompanySettings.open),
          closingTime: v(CompanySettings.close),
          lunchBreak: LunchBreak(
            start: v(CompanySettings.lunchStart),
            end: v(CompanySettings.lunchEnd),
          ),
          defaultPeriodInMinutes: int.parse(v(CompanySettings.period)),
          lockSchedulePeriodInMinutes: int.parse(v(CompanySettings.lock)),
          // Só reenvia os dias se mudaram, preservando o horário próprio de
          // cada dia que continua aberto.
          workingDays: _daysChanged ? _workingDaysToSend() : null,
        ),
      ),
      ConfigSection.endereco => CompanyDto(
        address: AddressDto(
          zipCode: v(CompanySettings.zip),
          street: v(CompanySettings.street),
          number: v(CompanySettings.number),
          complement: v(CompanySettings.complement),
          neighborhood: v(CompanySettings.neighborhood),
          city: v(CompanySettings.city),
          state: v(CompanySettings.state),
        ),
      ),
      ConfigSection.contato => CompanyDto(
        social: SocialDto(
          phone: CompanySettings.digits(v(CompanySettings.phone), 11),
          whatsapp: CompanySettings.digits(v(CompanySettings.whatsapp), 11),
          email: v(CompanySettings.email),
          instagram: v(CompanySettings.instagram).replaceFirst("@", ""),
          facebook: v(CompanySettings.facebook),
        ),
      ),
    };
  }

  List<WorkingDay> _workingDaysToSend() {
    final saved = {
      for (final day in company?.configuration.workingDays ?? <WorkingDay>[])
        day.day: day,
    };
    final days = workingDays.toList()..sort();
    return [for (final day in days) saved[day] ?? WorkingDay(day)];
  }

  /// Escolhe e envia a logo. Retorna `null` se cancelou, senão o resultado.
  Future<ApiResponse<Company?>?> changeLogo() async {
    if (logoBusy.value || saving.value) return null;

    PickedImage? image;
    try {
      image = await logoPicker();
    } on FormatException catch (e) {
      return ApiResponse.badRequest(errorDescription: e.message);
    }
    if (image == null) return null;

    if (image.isTooLarge) {
      return ApiResponse.badRequest(
        errorDescription: "A imagem deve ter no máximo 2 MB",
      );
    }

    logoBusy.value = true;
    final res = await _service.uploadCompanyLogo(
      companyId,
      bytes: image.bytes,
      filename: image.name,
      contentType: image.contentType,
    );

    if (res.result) await _refreshAfterLogo(res.data);
    logoBusy.value = false;
    return res;
  }

  Future<void> _refreshAfterLogo(Company? updated) async {
    // Só a logo muda: mantém o resto do que já está carregado.
    final fresh = updated ?? (await _service.getCompany(companyId)).data;
    if (fresh != null) {
      companyData.value = ApiResponse.result(data: fresh);
    }
  }

  static Future<bool> _askDiscard() async {
    final discard = await AppAlertDialog.confirmRequest(
      title: "Descartar alterações?",
      message: "As alterações feitas nesta seção não serão salvas.",
      cancelLabel: "Continuar",
      confirmLabel: "Descartar",
      destructive: true,
    );
    return discard == true;
  }
}
