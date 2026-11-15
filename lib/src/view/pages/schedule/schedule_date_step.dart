import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../domain/domain.dart';
import '../../../shared/shared.dart';
import '../../view.dart';
import 'schedule_step_session.dart';

class ScheduleDateStep extends GetView<SchedulePageController> with Validators {
  const ScheduleDateStep({super.key});

  /// Leva o usuário até a seção de horários, abaixo do calendário.
  void _scrollToTimes() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = controller.timeSectionKey.currentContext;
      if (ctx == null) return;
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
        alignment: 0.05,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // Column (e não slivers) para que todos os campos fiquem construídos e
    // sejam validados mesmo fora da tela.
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ScheduleStepSession(
            "Escolha a data",
            MdiIcons.calendarMultiselectOutline,
          ),
          8.verticalBox,
          FormField<DateTime>(
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
                          _scrollToTimes();
                        },
                        selectableDayPredicate: (day) {
                          final now = DateTime.now();

                          return day.isAfter(
                                DateTime(now.year, now.month, now.day - 1),
                              ) &&
                              controller.isOpenOn(day);
                        },
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          8.verticalBox,
          KeyedSubtree(
            key: controller.timeSectionKey,
            child: ScheduleStepSession(
              "Escolha o horário",
              MdiIcons.clockOutline,
            ),
          ),
          8.verticalBox,
          FormField<Schedule>(
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
                  if (controller.loading.value && controller.schedules.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24.0),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (controller.schedules.isEmpty) {
                    return Text("Nenhum horário disponível");
                  }
                  return GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 3,
                    childAspectRatio: 6 / 2,
                    mainAxisSpacing: 8.0,
                    crossAxisSpacing: 8.0,
                    children: controller.schedules.map((schedule) {
                      final available = schedule.isOpen;
                      return InkWell(
                        borderRadius: 8.borderRadius,
                        onTap: available
                            ? () {
                                state.didChange(schedule);
                                controller.selectSchedule(schedule);
                              }
                            : null,
                        child: Obx(() {
                          final selected =
                              controller.selectedSchedule.value == schedule;
                          return Container(
                            decoration: BoxDecoration(
                              color: available
                                  ? null
                                  : grey.withValues(alpha: 0.15),
                              borderRadius: 8.borderRadius,
                              border: Border.all(
                                color: !available
                                    ? grey.withValues(alpha: 0.4)
                                    : selected
                                    ? golden
                                    : grey,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                schedule.startTime.format(context),
                                style: available
                                    ? null
                                    : TextStyle(
                                        color: grey.withValues(alpha: 0.6),
                                        decoration:
                                            TextDecoration.lineThrough,
                                      ),
                              ),
                            ),
                          );
                        }),
                      );
                    }).toList(),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
