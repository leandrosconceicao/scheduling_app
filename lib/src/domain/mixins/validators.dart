import 'package:get/get.dart';
import 'package:ltech_core/ltech_core.dart';

mixin Validators {
  String? validEmail(String? text) {
    if (text == null) return "Obrigatório";

    if (!GetUtils.isEmail(text)) {
      return "E-mail inválido";
    }

    return null;
  }

  String? validPhone(String? text) {
    if (!(text?.hasContent ?? false)) return "Obrigatório";

    final digits = text!.clearPhone();

    // DDD (2 dígitos) + número (8 ou 9 dígitos)
    if (digits.length < 10 || digits.length > 11) {
      return "Telefone inválido";
    }

    return null;
  }
}