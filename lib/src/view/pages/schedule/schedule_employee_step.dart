import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../domain/domain.dart';
import '../../../shared/shared.dart';
import '../../view.dart';
import 'schedule_step_session.dart';

class ScheduleEmployeeStep extends GetView<SchedulePageController> {
  const ScheduleEmployeeStep({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 8.0,
      children: [
        ScheduleStepSession("Escolha o barbeiro", MdiIcons.accountOutline),
        Expanded(
          child: FormField<Employee>(
            autovalidateMode: .onUserInteractionIfError,
            initialValue: controller.selectedEmployee.value,
            validator: (value) {
              if (value == null) {
                return "Selecione o barbeiro";
              }

              return null;
            },
            builder: (state) {
              return Column(
                spacing: 16.0,
                children: [
                  Visibility(
                    visible: state.hasError,
                    child: FormAlert("Selecione o barbeiro"),
                  ),
                  Expanded(
                    child: Obx(
                      () => CustomScrollView(
                        slivers: [
                          SliverList.separated(
                            itemCount: controller.employees.length,
                            separatorBuilder: (_, _) =>
                                Padding(padding: const .only(bottom: 16.0)),
                            itemBuilder: (_, i) {
                              final employee = controller.employees[i];

                              return RadioGroup(
                                groupValue:
                                    controller.selectedEmployee.value,
                                onChanged: (value) {
                                  state.didChange(value);
                                  controller.selectedEmployee.trigger(
                                    value,
                                  );
                                },
                                child: RadioListTile(
                                  activeColor: golden,
                                  radioScaleFactor: 1.2,
                                  contentPadding: const .all(16.0),
                                  secondary: EmployeeAvatar(name: employee.name, photoUrl: employee.profilePhotoUrl,),
                                  subtitle: Row(
                                    spacing: 4.0,
                                    children: [
                                      Icon(
                                        MdiIcons.star,
                                        color: golden,
                                      ),
                                      Text(
                                        employee.rating
                                            .toStringAsFixed(1),
                                      ),
                                    ],
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: 8.borderRadius,
                                    side: BorderSide(
                                      color:
                                          controller
                                                  .selectedEmployee
                                                  .value ==
                                              employee
                                          ? golden
                                          : grey,
                                    ),
                                  ),
                                  value: employee,
                                  title: Text(
                                    employee.name,
                                    style: TextStyle(
                                      fontWeight: .bold,
                                    ),
                                  ),
                                  controlAffinity: .trailing,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
