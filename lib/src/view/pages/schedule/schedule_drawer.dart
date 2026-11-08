import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../../routes/routes.dart';
import '../../../shared/shared.dart';
import '../../view.dart';
import 'home/home_section.dart';

/// Menu lateral da tela inicial: loja, conta do cliente, atalhos e acesso
/// administrativo.
class ScheduleDrawer extends StatelessWidget {
  final SchedulePageController controller;

  const ScheduleDrawer({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.black,
      child: SafeArea(
        child: Obx(() {
          final logged = controller.isLogged;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _StoreHeader(controller: controller),
              Divider(color: grey, height: 1),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _AccountCard(controller: controller),
                    ),
                    if (logged) ...[
                      const SizedBox(height: 16),
                      _DrawerItem(
                        icon: MdiIcons.calendarCheckOutline,
                        label: "Meus agendamentos",
                        onTap: () {
                          final router = GoRouter.of(context);
                          Navigator.of(context).pop();
                          router.pushMySchedules(controller.companyId);
                        },
                      ),
                    ],
                  ],
                ),
              ),
              Divider(color: grey, height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: logged
                    ? _DrawerItem(
                        icon: MdiIcons.logout,
                        label: "Sair da conta",
                        onTap: controller.logout,
                      )
                    : _DrawerItem(
                        icon: MdiIcons.shieldAccountOutline,
                        label: "Acesso administrador",
                        onTap: () {
                          final router = GoRouter.of(context);
                          Navigator.of(context).pop();
                          router.pushAdminLogin(controller.companyId);
                        },
                      ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

/// Logo e nome da loja no topo do menu.
class _StoreHeader extends StatelessWidget {
  final SchedulePageController controller;

  const _StoreHeader({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      child: Row(
        spacing: 12,
        children: [
          EmployeeAvatar(
            name: controller.companyName,
            photoUrl: controller.companyLogo,
            radius: 28,
          ),
          Expanded(
            child: Text(
              controller.companyName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dados do cliente logado ou convite para entrar na conta.
class _AccountCard extends StatelessWidget {
  final SchedulePageController controller;

  const _AccountCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;

    if (!controller.isLogged) {
      return HomeCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            Text(
              "Entre na sua conta",
              style: theme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              "Acompanhe e gerencie seus agendamentos.",
              style: theme.bodyMedium,
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  controller.navigateToLogin();
                },
                icon: Icon(MdiIcons.loginVariant),
                label: const Text("Fazer login"),
              ),
            ),
          ],
        ),
      );
    }

    return HomeCard(
      child: Row(
        spacing: 12,
        children: [
          EmployeeAvatar(
            name: controller.userName,
            photoUrl: controller.userProfilePhoto,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 2,
              children: [
                Text(
                  controller.userName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (controller.userEmail.isNotEmpty)
                  Text(
                    controller.userEmail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.bodySmall,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Item de navegação do menu.
class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      leading: Icon(icon, color: golden),
      title: Text(label, style: Theme.of(context).textTheme.bodyLarge),
      trailing: Icon(MdiIcons.chevronRight, color: grey),
      onTap: onTap,
    );
  }
}
