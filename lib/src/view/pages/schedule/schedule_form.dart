import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../shared/shared.dart';
import '../../view.dart';
import 'schedule_confirm_step.dart';
import 'schedule_date_step.dart';
import 'schedule_employee_step.dart';
import 'schedule_service_step.dart';

class ScheduleForm extends StatefulWidget {
  const ScheduleForm({super.key});

  @override
  State<ScheduleForm> createState() => _ScheduleFormState();
}

class _ScheduleFormState extends State<ScheduleForm> {

  final controller = Get.find<SchedulePageController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Agende seu horário")),
      body: Column(
        children: [
          Padding(
            padding: const .symmetric(vertical: 24.0, horizontal: 32),
            child: Obx(
              () => Row(
                children: [
                  Expanded(child: stepIcon(1, "Serviço", filledStep: true)),
                  Expanded(
                    child: stepDivider(true),
                  ),
                  Expanded(child: stepIcon(2, "Barbeiro", filledStep: controller.isEmployeeStep)),
                  Expanded(
                    child: stepDivider(controller.isScheduleStep),
                  ),
                  Expanded(child: stepIcon(3, "Horário", filledStep: controller.isScheduleStep)),
                  Expanded(
                    child: stepDivider(controller.isConfirmStep),
                  ),
                  Expanded(child: stepIcon(4, "Confirmar", filledStep: controller.isConfirmStep)),
                ],
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Card(
                child: Padding(
                  padding: const .symmetric(horizontal: 16.0, vertical: 24.0),
                  child: Form(
                    key: controller.scheduleFormKey,
                    child: PageView(
                      onPageChanged: controller.activeStep.trigger,
                      physics: NeverScrollableScrollPhysics(),
                      controller: controller.pageController,
                      children: [ScheduleServiceStep(), ScheduleEmployeeStep(), ScheduleDateStep(), ScheduleConfirmStep()],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: .symmetric(horizontal: 16.0, vertical: 24.0),
        child: Obx(
          () => Visibility(
            visible: controller.activeStep.value < 3,
            child: Row(
              spacing: 8.0,
              children: [
                Visibility(
                  visible: controller.activeStep.value > 0,
                  child: Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        onPressed: controller.goBack,
                        child: Text("Retornar", style: TextStyle(color: Colors.white, fontWeight: .bold),)
                      ),
                    )
                  )
                ),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: FilledButton(
                      style: ButtonStyle(
                        backgroundColor: WidgetStatePropertyAll(golden)
                      ),
                      onPressed: controller.onNextStep,
                      child: controller.processing.value ? LoadingIcon() : Text("Próximo", style: TextStyle(
                        fontWeight: .bold
                      ),),
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

  Divider stepDivider([bool stepFilled = false]) {
    return Divider(
      color: stepFilled ? golden : null,
    );
  }

  Widget stepIcon(int step, String description, {bool filledStep = false}) {
    return Column(
      spacing: 8.0,
      children: [
        Container(
          height: 40,
          width: 40,
          decoration: BoxDecoration(
            shape: .circle,
            color: filledStep ? golden : null,
            border: filledStep ? null : BoxBorder.all(color: Colors.white),
          ),
          child: Center(child: Text("$step")),
        ),
        Text(description, textAlign: .center, style: TextStyle(
          fontSize: 12
        ),),
      ],
    );
  }
}