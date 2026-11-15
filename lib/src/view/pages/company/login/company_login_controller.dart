import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../application/application.dart';
import '../../../../domain/domain.dart';
import '../../../../shared/shared.dart';

final class CompanyLoginController extends GetxController with AlertActions {
  final String companyId;

  /// Destino após o login (definido pela guarda da área administrativa).
  final String? from;

  CompanyLoginController(this.companyId, {this.from});

  final formKey = GlobalKey<FormState>();
  final username = TextEditingController();
  final password = TextEditingController();

  final service = Get.find<IAuthService>();

  final ownerSession = Get.find<IOwnerSessionService>();

  final error = "".obs;

  final hidePassword = true.obs;

  final loading = false.obs;

  /// Retorna `true` quando a sessão do proprietário foi iniciada.
  Future<bool> authorize() async {
    if (!formKey.currentState!.validateAndScroll()) {
      return false;
    }

    error.trigger("");
    loading.toggle();

    final res = await service.authorizeOwner(OwnerAuthorizationDto(username.text, password.text));
    
    loading.toggle();

    if (!res.result) {
      showErrorAlert(res.description, title: "Falha na autenticação!");
      return false;
    }

    final token = res.data?.token ?? "";

    if (token.isEmpty) {
      showErrorAlert("Token de acesso não retornado", title: "Falha na autenticação!");
      return false;
    }

    await ownerSession.start(token);
    return true;
  }

  @override
  void onClose() {
    username.dispose();
    password.dispose();
    super.onClose();
  }

  void clearData() {
    username.clear();
    password.clear();
    error.trigger("");
  }
}