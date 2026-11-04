import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:ltech_core/ltech_core.dart';

import '../../../domain/domain.dart';
import '../../../routes/routes.dart';
import '../../view.dart';
import 'schedule_drawer.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage>
    with SingleTickerProviderStateMixin {
  final controller = Get.find<SchedulePageController>();

  final mainPageController = PageController(initialPage: 0);

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Title(
      title: "Faça seu agendamento",
      color: golden,
      child: Scaffold(
        backgroundColor: Colors.black,
        drawer: ScheduleDrawer(),
        appBar: AppBar(
          actions: [
            IconButton(onPressed: () {}, icon: Icon(MdiIcons.bellOutline)),
          ],
        ),
        body: Column(
          children: [
            Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: 280,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/images/barber_bg.jpg'),
                      fit: BoxFit.cover,
                      opacity: .4,
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Align(
                    alignment: .centerLeft,
                    child: Padding(
                      padding: const .only(left: 16.0),
                      child: Column(
                        mainAxisSize: .min,
                        crossAxisAlignment: .start,
                        spacing: 8.0,
                        children: [
                          Obx(
                            () => Container(
                              height: 81,
                              width: 81,
                              decoration: BoxDecoration(
                                shape: .circle,
                                image: DecorationImage(
                                  image: CachedNetworkImageProvider(controller.companyLogo),
                                )
                              ),
                            ),
                          ),
                          RichText(
                            text: TextSpan(
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontSize: 32,
                                color: Colors.white,
                              ),
                              children: [
                                TextSpan(text: "Seu estilo,\n"),
                                TextSpan(
                                  text: "nossa paixão.",
                                  style: TextStyle(color: golden),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            "Agende seu horário e viva a melhor\nexperiência de barbearia.",
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontSize: 24,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: .spaceAround,
              children: [
                optionCard(
                  MdiIcons.calendarMultiselectOutline,
                  "Agendar",
                  onTap: () {
                    GoRouter.of(context).pushScheduleForm(controller.companyId);
                  },
                ),
                optionCard(MdiIcons.contentCut, "Serviços", onTap: () => changePage(0)),
                optionCard(MdiIcons.accountOutline, "Barbeiros", onTap: () => changePage(1)),
              ],
            ),
            16.verticalBox,
            Expanded(
              child: Padding(
                padding: const .symmetric(horizontal: 16.0),
                child: PageView(
                  controller: mainPageController,
                  children: [
                    CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: pageSession("Nossos serviços"),
                        ),
                        Obx(() {
                          return SliverList.separated(
                            separatorBuilder: (_, _) =>
                              Padding(padding: const .only(bottom: 16.0)),
                              itemCount: controller.types.length,
                              itemBuilder: (_, i) {
                                final type = controller.types[i];

                                return ListTile(
                                  contentPadding: const .all(16.0),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: 8.borderRadius,
                                    side: BorderSide(color: grey),
                                  ),
                                  title: Text(type.name),
                                  subtitle: Text(type.price.ptBrCoin),
                                );
                              },
                            );
                        })
                      ],
                    ),
                    CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: pageSession("Nossos barbeiros"),
                        ),
                        Obx(
                          () => SliverList.separated(
                            separatorBuilder: (_, _) =>
                                Padding(padding: const .only(bottom: 16.0)),
                            itemCount: controller.employees.length,
                            itemBuilder: (_, i) {
                              final employee = controller.employees[i];
                          
                              return ListTile(
                                contentPadding: const .all(16.0),
                                leading: CircleAvatar(
                                  backgroundColor: golden,
                                  child: CachedNetworkImage(
                                    imageUrl: employee.profilePhotoUrl,
                                    errorWidget: (_, _, _) {
                                      return Icon(MdiIcons.accountOutline);
                                    },
                                  ),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: 8.borderRadius,
                                  side: BorderSide(
                                    color: grey,
                                  ),
                                ),
                                title: Text(employee.name),
                                subtitle: Row(
                                  spacing: 4.0,
                                  children: [
                                    Icon(MdiIcons.star, color: golden),
                                    Text(employee.rating.toStringAsFixed(1)),
                                  ],
                                ),
                              );
                            },
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
    );
  }

  Widget optionCard(IconData icon, String label, {void Function()? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 180,
        width: 140,
        decoration: BoxDecoration(
          border: Border.all(color: golden),
          borderRadius: 16.borderRadius,
        ),
        child: Column(
          spacing: 16.0,
          mainAxisAlignment: .center,
          children: [
            Icon(icon, size: 48),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget pageSession(String title) {
    return Padding(
      padding: const .only(bottom: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Colors.white,
          fontSize: 24,
        ),
      ),
    );
  }

  void changePage(int page) {
    mainPageController.animateToPage(page, duration: const Duration(milliseconds: 400), curve: Curves.easeIn);
  }
}
