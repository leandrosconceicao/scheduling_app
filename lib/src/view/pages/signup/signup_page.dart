import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/domain.dart';
import '../../../routes/routes.dart';
import '../../../shared/shared.dart';
import '../../view.dart';

class SignupPage extends GetView<SignupController>
    with Validators, FormValidators {
  const SignupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SizedBox(
          width: MediaQuery.sizeOf(context).width * .65,
          child: Column(
            mainAxisAlignment: .center,
            spacing: 32.0,
            children: [
              Center(child: FlutterLogo(size: 120)),
              Text("Faça seu cadastro", style: Theme.of(context).textTheme.titleLarge),
              Form(
                key: controller.formKey,
                child: Obx(
                  () => Column(
                    spacing: 24.0,
                    children: [
                      TextFormField(
                        readOnly: controller.processing.value,
                        decoration: InputDecoration(labelText: "Nome"),
                        controller: controller.name,
                        validator: notAllowedEmptyText,
                        keyboardType: .text,
                        textInputAction: .next,
                      ),
                      TextFormField(
                        readOnly: controller.processing.value,
                        decoration: InputDecoration(labelText: "E-mail"),
                        controller: controller.email,
                        validator: validEmail,
                        keyboardType: .emailAddress,
                        textInputAction: .next,
                      ),
                      TextFormField(
                        readOnly: controller.processing.value,
                        controller: controller.password,
                        validator: controller.validatePassword,
                        keyboardType: .visiblePassword,
                        textInputAction: .next,
                        obscureText: controller.hidePassword.value,
                        decoration: InputDecoration(
                          labelText: "Senha",
                          suffixIcon: IconButton(
                            onPressed: controller.hidePassword.toggle,
                            icon: Icon(
                              !controller.hidePassword.value
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                          ),
                        ),
                      ),
                      TextFormField(
                        readOnly: controller.processing.value,
                        controller: controller.confirmPassword,
                        validator: controller.validateConfirmPassword,
                        keyboardType: .visiblePassword,
                        textInputAction: .next,
                        obscureText: controller.hideShowConfPassword.value,
                        decoration: InputDecoration(
                          labelText: "Confirme a senha",
                          suffixIcon: IconButton(
                            onPressed: controller.hideShowConfPassword.toggle,
                            icon: Icon(
                              !controller.hideShowConfPassword.value
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                          ),
                        ),
                      ),
                      Column(
                        spacing: 8.0,
                        children: [
                          SizedBox(
                            height: 48,
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: controller.processing.value ? null : controller.signup,
                              child: controller.processing.value ? LoadingIcon() : Text("Confirmar cadastro"),
                            ),
                          ),
                          SizedBox(
                            height: 48,
                            width: double.infinity,
                            child: TextButton(
                              onPressed: controller.processing.value ? null : () {
                                final router = GoRouter.of(context);
                                if (router.canPop()) {
                                  router.pop();
                                  return;
                                }
                                router.goLogin(
                                  GoRouterState.of(context).pathParameters["companyId"] ?? "",
                                );
                              },
                              child: Text("Login"),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
