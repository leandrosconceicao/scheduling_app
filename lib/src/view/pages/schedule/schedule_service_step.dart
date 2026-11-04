import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../domain/domain.dart';
import '../../../shared/shared.dart';
import '../../view.dart';
import 'schedule_step_session.dart';

class ScheduleServiceStep extends GetView<SchedulePageController> {
  const ScheduleServiceStep({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 8.0,
      children: [
        ScheduleStepSession("Escolha o serviço", MdiIcons.contentCut),
        Expanded(
          child: FormField<ScheduleType>(
            autovalidateMode: .onUserInteractionIfError,
            initialValue: controller.selectedType.value,
            validator: (value) {
              if (value == null) {
                return "Selecione o serviço";
              }

              return null;
            },
            builder: (state) {
              return Column(
                spacing: 16.0,
                children: [
                  Visibility(
                    visible: state.hasError,
                    child: FormAlert("Selecione o serviço"),
                  ),
                  Expanded(
                    child: Obx(
                      () => CustomScrollView(
                        slivers: [
                          SliverList.separated(
                            separatorBuilder: (_, _) =>
                                Padding(padding: const .only(bottom: 16.0)),
                            itemCount: controller.types.length,
                            itemBuilder: (_, i) {
                              final service = controller.types[i];

                              return RadioGroup(
                                groupValue: controller.selectedType.value,
                                onChanged: (value) {
                                  state.didChange(value);
                                  controller.selectType(value);
                                },
                                child: RadioListTile(
                                  activeColor: golden,
                                  radioScaleFactor: 1.2,
                                  contentPadding: const .all(16.0),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: 8.borderRadius,
                                    side: BorderSide(
                                      color:
                                          controller.selectedType.value ==
                                              service
                                          ? golden
                                          : grey,
                                    ),
                                  ),
                                  value: service,
                                  title: Text(
                                    service.name,
                                    style: TextStyle(fontWeight: .bold),
                                  ),
                                  subtitle: Text(service.price.ptBrCoin),
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
