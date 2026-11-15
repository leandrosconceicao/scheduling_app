import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../domain/domain.dart';
import '../../../shared/shared.dart';
import '../../view.dart';

final class LoginPageController extends GetxController {
  final String companyId;
  bool enableCnpjInput;

  LoginPageController(this.companyId, {this.enableCnpjInput = false});

  final authService = Get.find<IAuthService>();

  final formKey = GlobalKey<FormState>();
  final loginAdmin = false.obs;
  final cnpjMask = MaskedTextController(mask: "00.000.000/0000-00");
  final email = TextEditingController();
  final password = TextEditingController();

  final error = "".obs;

  final hidePassword = true.obs;

  final loading = false.obs;

  /// Retorna `true` quando o login foi concluído.
  Future<bool> authorize() async {
    if (!formKey.currentState!.validateAndScroll()) {
      return false;
    }

    error.trigger("");
    loading.toggle();

    final response = await authService.loginWithEmail(
      email.text,
      password.text,
    );

    loading.toggle();

    if (!response.result) {
      error.trigger("Email ou senha são inválidos");
      return false;
    }

    clearData();
    return true;
  }

  @override
  void onClose() {
    email.dispose();
    password.dispose();
    cnpjMask.dispose();
    super.onClose();
  }

  void clearData() {
    email.clear();
    cnpjMask.clear();
    password.clear();
    loginAdmin.trigger(false);
    error.trigger("");
  }
}