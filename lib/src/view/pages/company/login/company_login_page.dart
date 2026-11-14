import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../../../routes/routes.dart';
import '../../../../shared/shared.dart';
import '../../../view.dart';

class CompanyLoginPage extends GetView<CompanyLoginController>
    with FormValidators {
  const CompanyLoginPage({super.key});

  Future<void> _submit(BuildContext context) async {
    final authorized = await controller.authorize();

    if (!authorized || !context.mounted) return;

    final router = GoRouter.of(context);
    final from = controller.from;

    from != null ? router.go(from) : router.goAdminSchedules(controller.companyId);
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
                Image.asset("images/app_logo-dourado.png", height: 150,),
                Text("Acesso da empresa", style: Theme.of(context).textTheme.titleLarge),
                Obx(
                  () => TextFormField(
                    readOnly: controller.loading.value,
                    controller: controller.username,
                    validator: notAllowedEmptyText,
                    keyboardType: .text,
                    textInputAction: .next,
                    decoration: InputDecoration(labelText: "Usuário"),
                  ),
                ),
                Obx(
                  () => TextFormField(
                    readOnly: controller.loading.value,
                    controller: controller.password,
                    obscureText: controller.hidePassword.value,
                    validator: notAllowedEmptyText,
                    keyboardType: .visiblePassword,
                    textInputAction: .done,
                    onFieldSubmitted: (_) => _submit(context),
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
                ),
                Obx(() {
                  return Visibility(
                    visible: controller.error.value.hasContent,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: .4),
                        border: Border.all(color: Colors.red),
                        borderRadius: 8.borderRadius,
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
                SizedBox(
                  height: 48,
                  width: double.infinity,
                  child: Obx(
                    () => FilledButton(
                      onPressed: !controller.loading.value
                          ? () => _submit(context)
                          : null,
                      child: controller.loading.value
                          ? LoadingIcon()
                          : Text("Acessar"),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
