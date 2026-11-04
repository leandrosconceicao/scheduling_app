import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../../routes/routes.dart';
import '../../../shared/shared.dart';
import 'login_controller.dart';

class LoginPage extends GetView<LoginPageController> with FormValidators {
  const LoginPage({super.key});

  /// Devolve `true` para quem abriu o login; sem histórico (deep link), segue
  /// para o agendamento.
  Future<void> _submit(BuildContext context) async {
    final authorized = await controller.authorize();

    if (!authorized || !context.mounted) return;

    final router = GoRouter.of(context);

    router.canPop() ? router.pop(true) : router.goSchedule(controller.companyId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: SizedBox(
          width: MediaQuery.sizeOf(context).width * .65,
          child: Form(
            key: controller.formKey,
            child: Column(
              mainAxisAlignment: .center,
              spacing: 24.0,
              children: [
                FlutterLogo(size: 64),
                Text("Faça o seu login", style: Theme.of(context).textTheme.titleLarge),
                Column(
                  crossAxisAlignment: .start,
                  spacing: 8.0,
                  children: [
                    Text("Email"),
                    TextFormField(
                      controller: controller.email,
                      validator: notAllowedEmptyText,
                      keyboardType: .emailAddress,
                      textInputAction: .next,
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: .start,
                  spacing: 8.0,
                  children: [
                    Text("Senha"),
                    Obx(
                      () => TextFormField(
                        controller: controller.password,
                        obscureText: controller.hidePassword.value,
                        validator: notAllowedEmptyText,
                        keyboardType: .visiblePassword,
                        textInputAction: .continueAction,
                        onFieldSubmitted: (_) => _submit(context),
                        decoration: InputDecoration(
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
                    ),
                  ],
                ),
                Obx(
                  () => Column(
                    spacing: 8,
                    children: [
                      Visibility(
                        visible: controller.loginAdmin.value,
                        child: Column(
                          crossAxisAlignment: .start,
                          spacing: 8.0,
                          children: [
                            Text("CNPJ"),
                            TextFormField(
                              textInputAction: .next,
                              controller: controller.cnpjMask,
                              validator: (text) {
                                if (!GetUtils.isCnpj(text!)) {
                                  return "CNPJ inválido";
                                }
                                return null;
                              },
                              keyboardType: .text,
                            ),
                          ],
                        ),
                      ),
                      if (controller.enableCnpjInput) ...{
                        SwitchListTile(
                          value: controller.loginAdmin.value,
                          title: Text("Login como administrador"),
                          onChanged: (_) => controller.loginAdmin.toggle(),
                        ),
                      },
                    ],
                  ),
                ),
                Obx(() {
                  return Visibility(
                    visible: controller.error.value.hasContent,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: .4),
                        border: Border.all(color: Colors.red),
                        borderRadius: 8.borderRadius
                      ),
                      height: 40,
                      width: double.infinity,
                      child: Center(
                        child: Text(
                          controller.error.value,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.red,
                            fontWeight: .bold,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
                Column(
                  spacing: 8,
                  children: [
                    Divider(),
                    SizedBox(
                      height: 48,
                      width: double.infinity,
                      child: Obx(
                        () => FilledButton(
                          onPressed: !controller.loading.value ? () => _submit(context) : null,
                          child: controller.loading.value
                          ? LoadingIcon()
                          : Text("Acessar"),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 48,
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () => GoRouter.of(context).pushSignup(controller.companyId),
                        child: Text("Faça seu cadastro"),
                      )
                    )
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
