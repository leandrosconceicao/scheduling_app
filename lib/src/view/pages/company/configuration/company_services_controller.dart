import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../../domain/domain.dart';
import '../../../../shared/shared.dart';

/// Gerencia os serviços ([ScheduleType]) da empresa na área administrativa.
final class CompanyServicesController extends GetxController {
  /// A busca só aparece quando a lista passa desse tamanho.
  static const searchThreshold = 5;
  static const nameMaxLength = 60;
  static const _highlightDuration = Duration(seconds: 4);

  final String companyId;

  final _service = Get.find<ICompanyService>();

  final types = <ScheduleType>[].obs;
  final loading = true.obs;
  final loadError = "".obs;
  final query = "".obs;
  final defaultPeriodInMinutes = 0.obs;
  final highlightedId = RxnString();
  final deletingId = RxnString();

  final searchController = TextEditingController();

  Timer? _highlightTimer;

  CompanyServicesController(this.companyId);

  @override
  void onInit() {
    searchController.addListener(() => query.value = searchController.text);
    load();
    super.onInit();
  }

  @override
  void onClose() {
    _highlightTimer?.cancel();
    searchController.dispose();
    super.onClose();
  }

  bool get showSearch => types.length > searchThreshold;

  List<ScheduleType> get visibleTypes {
    final search = _normalize(query.value);

    if (search.isEmpty) return types;

    return types.where((e) => _normalize(e.name).contains(search)).toList();
  }

  Future<void> load() async {
    loading.value = true;
    loadError.value = "";

    final companyRequest = _service.getCompany(companyId);
    final typesResponse = await _service.getScheduleTypes(companyId);
    final companyResponse = await companyRequest;

    defaultPeriodInMinutes.value =
        companyResponse.data?.configuration.defaultPeriodInMinutes ?? 0;

    if (typesResponse.result) {
      types.assignAll(_sorted(typesResponse.data ?? []));
    } else {
      loadError.value = typesResponse.description;
    }

    loading.value = false;
  }

  String? validateName(String? value, {String? editingId}) {
    final name = value?.trim() ?? "";

    if (name.isEmpty) return "Informe o nome do serviço";

    if (name.length < 2) return "Use pelo menos 2 caracteres";

    final isDuplicated = types.any(
      (e) => e.id != editingId && _normalize(e.name) == _normalize(name),
    );

    return isDuplicated ? "Já existe um serviço com esse nome" : null;
  }

  String? validatePrice(num price) {
    return price > 0 ? null : "Informe um valor maior que zero";
  }

  Future<ApiResponse<ScheduleType?>> create(String name, num price) async {
    final res = await _service.addNewScheduleType(
      companyId,
      ScheduleType(companyId, name.trim(), price),
    );

    final saved = res.data;

    if (!res.result || saved == null) return res;

    types.assignAll(_sorted([...types, saved]));
    _afterSave(saved);

    return res;
  }

  Future<ApiResponse<ScheduleType?>> edit(
    ScheduleType type,
    String name,
    num price,
  ) async {
    final res = await _service.updateScheduleType(
      companyId,
      type.id ?? "",
      name: name.trim(),
      price: price,
    );

    if (!res.result) return res;

    final saved =
        res.data ?? ScheduleType(companyId, name.trim(), price, id: type.id);

    types.assignAll(
      _sorted(types.map((e) => e.id == type.id ? saved : e).toList()),
    );
    _afterSave(saved);

    return ApiResponse.result(data: saved);
  }

  Future<ApiResponse<dynamic>> remove(ScheduleType type) async {
    deletingId.value = type.id;

    final res = await _service.removeScheduleType(companyId, type.id ?? "");

    deletingId.value = null;

    if (res.result) types.removeWhere((e) => e.id == type.id);

    return res;
  }

  void _afterSave(ScheduleType saved) {
    // Sem isso, o serviço salvo poderia ficar oculto pela busca atual.
    searchController.clear();

    highlightedId.value = saved.id;
    _highlightTimer?.cancel();
    _highlightTimer = Timer(
      _highlightDuration,
      () => highlightedId.value = null,
    );
  }

  List<ScheduleType> _sorted(List<ScheduleType> values) {
    return [...values]
      ..sort((a, b) => _normalize(a.name).compareTo(_normalize(b.name)));
  }

  /// Compara nomes ignorando maiúsculas e acentos.
  static String _normalize(String text) {
    const accents = {
      "á": "a",
      "à": "a",
      "â": "a",
      "ã": "a",
      "ä": "a",
      "é": "e",
      "è": "e",
      "ê": "e",
      "ë": "e",
      "í": "i",
      "ì": "i",
      "î": "i",
      "ï": "i",
      "ó": "o",
      "ò": "o",
      "ô": "o",
      "õ": "o",
      "ö": "o",
      "ú": "u",
      "ù": "u",
      "û": "u",
      "ü": "u",
      "ç": "c",
      "ñ": "n",
    };

    return text
        .trim()
        .toLowerCase()
        .split("")
        .map((char) => accents[char] ?? char)
        .join();
  }
}
