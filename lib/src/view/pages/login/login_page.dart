import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../../routes/routes.dart';
import '../../../shared/shared.dart';
import '../../view.dart';

class LoginPage extends GetView<LoginPageController> with FormValidators {
  const LoginPage({super.key});

  /// Devolve `true` para quem abriu o login; sem histórico (deep link), segue
  /// para o agendamento.
  Future<void> _submit(BuildContext context, {bool google = false}) async {
    final authorized = google
        ? await controller.authorizeWithGoogle()
        : await controller.authorize();

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
          width: MediaQuery.sizeOf(context).width * .75,
          child: Form(
            key: controller.formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: .center,
                spacing: 24.0,
                children: [
                  Image.asset("assets/images/app_logo-dourado.png", height: 110,),
                  Text("Faça o seu login", style: Theme.of(context).textTheme.titleLarge),
                  Column(
                    crossAxisAlignment: .start,
                    spacing: 8.0,
                    children: [
                      Text("Email"),
                      TextFormField(
                        autofocus: true,
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
                  Obx(() {
                    return Visibility(
                      visible: controller.error.value.hasContent,
                      child: FormAlert(controller.error.value),
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
                        child: Obx(
                          () => OutlinedButton.icon(
                            onPressed: !controller.loading.value
                                ? () => _submit(context, google: true)
                                : null,
                            icon: Icon(MdiIcons.accountCircleOutline),
                            label: Text("Continuar com Google"),
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
      ),
    );
  }
}
