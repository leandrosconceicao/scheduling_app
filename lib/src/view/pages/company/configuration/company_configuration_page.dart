import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../../../routes/routes.dart';
import '../../../view.dart';

class CompanyConfigurationPage extends GetView<CompanyConfigurationController> {
  const CompanyConfigurationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Configurações")),
      body: Obx(() {
        if (controller.companyData.value == null) {
          return Center(child: CircularProgressIndicator());
        }

        final res = controller.companyData.value!;

        if (!res.result) {
          return Center(child: Text(res.description),);
        }

        return CustomScrollView(
          slivers: [
            SliverList.list(
              children: [
                ListTile(
                  leading: Icon(MdiIcons.contentCut),
                  title: Text("Serviços"),
                  subtitle: Text("Cadastre e edite os serviços oferecidos"),
                  trailing: Icon(MdiIcons.chevronRight),
                  onTap: () => GoRouter.of(
                    context,
                  ).goAdminConfigServices(controller.companyId),
                ),
              ],
            ),
          ],
        );
      }),
    );
  }
}
