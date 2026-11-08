import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../../domain/domain.dart';
import '../../../../shared/shared.dart';

/// Gerencia os barbeiros ([Employee]) da empresa na área administrativa.
final class CompanyEmployeesController extends GetxController {
  /// A busca só aparece quando a lista passa desse tamanho.
  static const searchThreshold = 5;
  static const nameMaxLength = 60;
  static const _highlightDuration = Duration(seconds: 4);

  final String companyId;

  final _service = Get.find<ICompanyService>();

  final employees = <Employee>[].obs;
  final loading = true.obs;
  final loadError = "".obs;
  final query = "".obs;
  final highlightedId = RxnString();
  final deletingId = RxnString();

  final searchController = TextEditingController();

  Timer? _highlightTimer;

  CompanyEmployeesController(this.companyId);

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

  bool get showSearch => employees.length > searchThreshold;

  List<Employee> get visibleEmployees {
    final search = _normalize(query.value);

    if (search.isEmpty) return employees;

    return employees.where((e) => _normalize(e.name).contains(search)).toList();
  }

  Future<void> load() async {
    loading.value = true;
    loadError.value = "";

    final res = await _service.getCompanyEmployees(companyId);

    if (res.result) {
      employees.assignAll(_sorted(res.data ?? []));
    } else {
      loadError.value = res.description;
    }

    loading.value = false;
  }

  String? validateName(String? value, {String? editingId}) {
    final name = value?.trim() ?? "";

    if (name.isEmpty) return "Informe o nome do barbeiro";

    if (name.length < 2) return "Use pelo menos 2 caracteres";

    final isDuplicated = employees.any(
      (e) => e.id != editingId && _normalize(e.name) == _normalize(name),
    );

    return isDuplicated ? "Já existe um barbeiro com esse nome" : null;
  }

  /// Abre a galeria. Substituível nos testes.
  Future<PickedImage?> Function() photoPicker = pickGalleryImage;

  /// Cria o barbeiro e, em seguida, envia a foto escolhida (se houver).
  Future<EmployeeSaveResult> create(String name, {PickedImage? photo}) async {
    final res = await _service.addEmployee(
      companyId,
      Employee(name.trim(), "", companyId),
    );

    var saved = res.data;

    if (!res.result || saved == null) return EmployeeSaveResult(res);

    String? photoError;

    if (photo != null) {
      final photoRes = await _uploadPhoto(saved, photo);
      saved = photoRes.data ?? saved;
      if (!photoRes.result) photoError = _describe(photoRes);
    }

    employees.assignAll(_sorted([...employees, saved]));
    _afterSave(saved);

    return EmployeeSaveResult(res, employee: saved, photoError: photoError);
  }

  /// Só chama a API do que mudou: o nome (PATCH) e/ou a foto (PUT).
  Future<EmployeeSaveResult> edit(
    Employee employee,
    String name, {
    PickedImage? photo,
  }) async {
    var saved = employee;
    var response = ApiResponse<Employee?>.result(data: employee);

    if (name.trim() != employee.name) {
      response = await _service.updateEmployee(
        companyId,
        employee.id,
        name: name.trim(),
      );

      if (!response.result) return EmployeeSaveResult(response);

      saved = response.data ?? employee.copyWith(name: name.trim());
    }

    String? photoError;

    if (photo != null) {
      final photoRes = await _uploadPhoto(saved, photo);
      saved = photoRes.data ?? saved;
      if (!photoRes.result) photoError = _describe(photoRes);
    }

    employees.assignAll(
      _sorted(employees.map((e) => e.id == employee.id ? saved : e).toList()),
    );
    _afterSave(saved);

    return EmployeeSaveResult(
      response,
      employee: saved,
      photoError: photoError,
    );
  }

  Future<ApiResponse<Employee?>> _uploadPhoto(
    Employee employee,
    PickedImage photo,
  ) {
    return _service.uploadEmployeePhoto(
      companyId,
      employee.id,
      bytes: photo.bytes,
      filename: photo.name,
      contentType: photo.contentType,
    );
  }

  String _describe(ApiResponse res) {
    return res.description.hasContent
        ? res.description
        : "Tente novamente mais tarde.";
  }

  Future<ApiResponse<dynamic>> remove(Employee employee) async {
    deletingId.value = employee.id;

    final res = await _service.removeEmployee(companyId, employee.id);

    deletingId.value = null;

    if (res.result) employees.removeWhere((e) => e.id == employee.id);

    return res;
  }

  void _afterSave(Employee saved) {
    // Sem isso, o barbeiro salvo poderia ficar oculto pela busca atual.
    searchController.clear();

    highlightedId.value = saved.id;
    _highlightTimer?.cancel();
    _highlightTimer = Timer(
      _highlightDuration,
      () => highlightedId.value = null,
    );
  }

  List<Employee> _sorted(List<Employee> values) {
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

/// Resultado de criar ou editar. A foto é enviada depois dos dados, então o
/// barbeiro pode ter sido salvo mesmo que a foto tenha falhado ([photoError]).
class EmployeeSaveResult {
  final ApiResponse<Employee?> response;
  final Employee? _employee;
  final String? photoError;

  EmployeeSaveResult(this.response, {Employee? employee, this.photoError})
    : _employee = employee;

  bool get result => response.result;
  String get description => response.description;
  Employee? get employee => _employee ?? response.data;
}
