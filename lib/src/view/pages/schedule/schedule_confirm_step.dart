import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../domain/domain.dart';
import '../../../shared/shared.dart';
import '../../view.dart';
import 'schedule_step_session.dart';

class ScheduleConfirmStep extends GetView<SchedulePageController> with Validators {
  const ScheduleConfirmStep({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          ScheduleStepSession("Telefone para contato", MdiIcons.phone),
          FormField<String>(
            validator: validPhone,
            autovalidateMode: .onUserInteractionIfError,
            builder: (state) {
              return Column(
                spacing: 8.0,
                children: [
                  TextField(
                    decoration: InputDecoration(
                      hintText: "(00) 00000 0000",
                      error: SizedBox()
                    ),
                    onChanged: state.didChange,
                    controller: controller.phoneController,
                  ),
                  Visibility(
                    visible: state.hasError,
                    child: FormAlert(state.errorText ?? "")
                  ),
                ],
              );
            }
          ),
          16.verticalBox,
          ScheduleStepSession(
            "Resumo de agendamento",
            MdiIcons.fileDocumentOutline,
          ),
          16.verticalBox,
          sessionItem(context, 
            "Serviço",
            controller.selectedType.value?.name ?? "",
            trailingInfo: controller.selectedType.value?.price.ptBrCoin ?? "",
          ),
          16.verticalBox,
          Divider(),
          16.verticalBox,
          sessionItem(context, "Barbeiro", controller.selectedEmployee.value?.name ?? ""),
          16.verticalBox,
          sessionItem(context, 
            "Data",
            controller.selectedDate.value?.dateDescription ?? "",
          ),
          16.verticalBox,
          sessionItem(context, 
            "Horário",
            controller.selectedSchedule.value?.startTime.format(context) ?? "",
          ),
          16.verticalBox,
          sessionItem(context, 
            "Duração",
            "${controller.selectedSchedule.value?.duration.inMinutes} min",
          ),
          16.verticalBox,
          Divider(),
          16.verticalBox,
          Row(
            mainAxisAlignment: .spaceBetween,
            children: [
              Text(
                "Total",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: .bold,
                ),
              ),
              Text(
                controller.selectedType.value?.price.ptBrCoin ?? "",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: golden,
                  fontWeight: .bold,
                ),
              ),
            ],
          ),
          32.verticalBox,
          SizedBox(
            height: 56,
            width: double.infinity,
            child: FilledButton(
              style: ButtonStyle(
                backgroundColor: WidgetStatePropertyAll(golden)
              ),
              onPressed: controller.onNextStep, 
              child: Obx(
                () => controller.processing.value ? LoadingIcon() : Text("CONFIRMAR AGENDAMENTO", style: TextStyle(
                  fontSize: 18,
                  fontWeight: .bold
                ),),
              )
            ),
          ),
          16.verticalBox,
          SizedBox(
            height: 56,
            width: double.infinity,
            child: Obx(
              () => TextButton(
                onPressed: controller.processing.value ? null : controller.cancelConfirm,
                child: Text("Cancelar", style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: .bold
                ),)
              ),
            ),
          ),
          16.verticalBox,
          ListTile(
            leading: Icon(MdiIcons.lockOutline, color: golden,),
            title: Text("Seus dados estão seguros conosco."),
          )
        ],
      ),
    );
  }

  Widget sessionItem(BuildContext context, String session, String value, {String? trailingInfo}) {
    return Row(
      crossAxisAlignment: .end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: .start,
            children: [
              Text(
                session,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white70,
                ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: .bold,
                ),
              ),
            ],
          ),
        ),
        Visibility(
          visible: trailingInfo != null,
          child: Text(trailingInfo ?? "", style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: .bold,
            color: Colors.white
          ),),
        ),
      ],
    );
  }
}
