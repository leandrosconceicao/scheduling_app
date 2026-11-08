import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../../routes/routes.dart';
import '../../view.dart';

class ScheduleDrawer extends StatefulWidget {
  const ScheduleDrawer({super.key});

  @override
  State<ScheduleDrawer> createState() => _ScheduleDrawerState();
}

class _ScheduleDrawerState extends State<ScheduleDrawer> {
  final controller = Get.find<SchedulePageController>();

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Obx(
        () => Column(
          children: [
            Expanded(
              child: Column(
                children: [
                  Stack(
                    children: [
                      UserAccountsDrawerHeader(
                        decoration: BoxDecoration(color: grey),
                        currentAccountPicture: CachedNetworkImage(
                          imageUrl: controller.userProfilePhoto,
                          errorWidget: (_, _, _) {
                            return CircleAvatar(
                              backgroundColor: golden,
                              child: Icon(MdiIcons.accountOutline),
                            );
                          },
                        ),
                        accountName: Visibility(
                          visible: controller.isLogged,
                          replacement: TextButton(
                            onPressed: controller.navigateToLogin,
                            child: Text("Faça seu login"),
                          ),
                          child: Text(
                            controller.userName,
                            style: TextStyle(color: white),
                          ),
                        ),
                        accountEmail: Visibility(
                          visible: controller.isLogged,
                          child: Text(
                            controller.userEmail,
                            style: TextStyle(color: white),
                          ),
                        ),
                      ),
                      Align(
                        alignment: .topRight,
                        child: Visibility(
                          visible: controller.isLogged,
                          child: Padding(
                            padding: const .only(top: 8.0, right: 16.0),
                            child: IconButton(
                              tooltip: "Fazer logout",
                              onPressed: controller.logout,
                              icon: Icon(MdiIcons.logout),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Visibility(
                    visible: controller.isLogged,
                    child: ListTile(
                      leading: Icon(MdiIcons.calendarCheckOutline),
                      onTap: () {
                        final router = GoRouter.of(context);
                        Navigator.of(context).pop();
                        router.pushMySchedules(controller.companyId);
                      },
                      title: Text("Meus agendamentos"),
                    ),
                  ),
                ],
              ),
            ),
            Visibility(
              visible: !controller.isLogged,
              child: Padding(
                padding: const .only(bottom: 32),
                child: OutlinedButton(
                  onPressed: () {
                    GoRouter.of(context).pushAdminLogin(controller.companyId);
                  },
                  child: Text("Acesso Administrador"),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
