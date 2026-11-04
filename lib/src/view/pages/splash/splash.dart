import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'splash_controller.dart';

class SplashPage extends GetView<SplashController> {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Obx(() {
          if (controller.error.value.isEmpty) {
            return CircularProgressIndicator();
          }
          return Column(
            mainAxisSize: .min,
            spacing: 16,
            children: [
              Text(controller.error.value),
              FilledButton(
                onPressed: controller.navigateToCompanyDomain,
                child: Text("Tentar novamente"),
              ),
            ],
          );
        }),
      ),
    );
  }
}
