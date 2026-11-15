import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../domain/domain.dart';
import '../../../shared/shared.dart';
import '../../view.dart';

final class SignupController extends GetxController {
  final email = TextEditingController();
  final password = TextEditingController();
  final confirmPassword = TextEditingController();
  final name = TextEditingController();

  final authService = Get.find<IAuthService>();

  final phoneNumber = MaskedTextController(
    mask: "(00) 00000-0000"
  );

  final hidePassword = true.obs;
  final hideShowConfPassword = true.obs;

  final processing = false.obs;

  final formKey = GlobalKey<FormState>();

  void signup() async {
    if (!formKey.currentState!.validateAndScroll()) {
      return;
    }

    processing.toggle();

    final response = await authService.signUpWithEmail(email.text, password.text, name.text);

    processing.toggle();

    if (!response.result) {
      AppAlertDialog.show(body: response.description);
      return;
    }

    AppAlertDialog.show(body: "Usuário cadastrado com sucesso!");

    clearValues();

  }

  void clearValues() {
    email.clear();
    password.clear();
    confirmPassword.clear();
    name.clear();
    phoneNumber.clear();
    formKey.currentState?.reset();
  }

  @override
  void onClose() {
    email.dispose();
    password.dispose();
    confirmPassword.dispose();
    name.dispose();
    phoneNumber.dispose();
    super.onClose();
  }

  String? validatePassword(String? text) {
    if (text == null || text.isEmpty) return "Obrigatório";

    if (text.length < 8) {
      return "A senha deve ter no mínimo 8 caracteres";
    }

    if (text.length > 4096) {
      return "A senha deve ter no máximo 4096 caracteres";
    }

    if (!RegExp(r'(?=.*[A-Z])').hasMatch(text)) {
      return "A senha deve conter pelo menos uma letra maiúscula";
    }

    if (!RegExp(r'(?=.*[a-z])').hasMatch(text)) {
      return "A senha deve conter pelo menos uma letra minúscula";
    }

    if (!RegExp(r'(?=.*\d)').hasMatch(text)) {
      return "A senha deve conter pelo menos um número";
    }

    return null;
  }

  String? validateConfirmPassword(String? text) {
    if (text!.isEmpty) {
      return "Obrigatório";
    }
    if (text != password.text) {
      return "Senhas não são iguais";
    }

    return null;
  }
}