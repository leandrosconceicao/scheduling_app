import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../domain/domain.dart';
import '../../../shared/shared.dart';
import '../../view.dart';
import 'schedule_step_session.dart';

class ScheduleDateStep extends GetView<SchedulePageController> with Validators {
  const ScheduleDateStep({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: ScheduleStepSession(
            "Escolha a data",
            MdiIcons.calendarMultiselectOutline,
          ),
        ),
        8.sliverVertialBox,
        SliverToBoxAdapter(
          child: FormField<DateTime>(
            autovalidateMode: .onUserInteractionIfError,
            initialValue: controller.selectedDate.value,
            validator: (value) {
              if (value == null) {
                return "Selecione a data";
              }
              return null;
            },
            builder: (state) {
              return Column(
                spacing: 8.0,
                children: [
                  Visibility(
                    visible: state.hasError,
                    child: FormAlert("Selecione a data"),
                  ),
                  Obx(
                    () => Container(
                      padding: const .only(top: 24.0),
                      decoration: BoxDecoration(
                        borderRadius: 8.borderRadius,
                        border: Border.all(color: grey),
                      ),
                      child: CalendarDatePicker(
                        initialDate: controller.selectedDate.value,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                        onDateChanged: (value) {
                          state.didChange(value);
                          controller.selectDate(value);
                        },
                        selectableDayPredicate: (day) {
                          final now = DateTime.now();

                          return day.isAfter(
                            DateTime(now.year, now.month, now.day - 1),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        8.sliverVertialBox,
        SliverToBoxAdapter(
          child: ScheduleStepSession(
            "Escolha o horário",
            MdiIcons.clockOutline,
          ),
        ),
        8.sliverVertialBox,
        SliverToBoxAdapter(
          child: FormField<Schedule>(
            initialValue: controller.selectedSchedule.value,
            autovalidateMode: .onUserInteractionIfError,
            validator: (value) {
              if (value == null) return "Selecione o horário";

              return null;
            },
            builder: (state) => Column(
              children: [
                Visibility(
                  visible: state.hasError,
                  child: FormAlert("Selecione o horário"),
                ),
                8.verticalBox,
                Obx(() {
                  if (controller.schedules.isEmpty) {
                    return Text("Nenhum horário disponível");
                  }
                  return GridView.count(
                    shrinkWrap: true,
                    crossAxisCount: 3,
                    childAspectRatio: 6 / 2,
                    mainAxisSpacing: 8.0,
                    crossAxisSpacing: 8.0,
                    children: controller.schedules.map((schedule) {
                      return InkWell(
                        onTap: schedule.isOpen
                            ? () {
                              state.didChange(schedule);
                              controller.selectSchedule(schedule);
                            }
                            : null,
                        child: Obx(
                          () => Container(
                            decoration: BoxDecoration(
                              borderRadius: 8.borderRadius,
                              border: Border.all(
                                color:
                                    controller.selectedSchedule.value ==
                                        schedule
                                    ? golden
                                    : grey,
                              ),
                            ),
                            child: Center(
                              child: Text(schedule.startTime.format(context)),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                }),
              ],
            ),
          ),
        ),
        // Obx(() {
        //   if (controller.schedules.isEmpty) {
        //     return SliverToBoxAdapter(child: Text("Nenhum horário disponível"));
        //   }
        //   return SliverGrid.builder(
        //     itemCount: controller.schedules.length,
        //     gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        //       childAspectRatio: 6 / 2,
        //       crossAxisCount: 3,
        //       mainAxisSpacing: 8.0,
        //       crossAxisSpacing: 8.0,
        //     ),
        //     itemBuilder: (_, i) {
        //       final schedule = controller.schedules[i];
        //       return InkWell(
        //         onTap: schedule.isOpen
        //             ? () => controller.selectSchedule(schedule)
        //             : null,
        //         child: Obx(
        //           () => Container(
        //             decoration: BoxDecoration(
        //               borderRadius: 8.borderRadius,
        //               border: Border.all(
        //                 color: controller.selectedSchedule.value == schedule
        //                     ? golden
        //                     : grey,
        //               ),
        //             ),
        //             child: Center(
        //               child: Text(schedule.startTime.format(context)),
        //             ),
        //           ),
        //         ),
        //       );
        //     },
        //   );
        // }),
      ],
    );
  }
}
