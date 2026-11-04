import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../domain/domain.dart';

class SplashController extends GetxController {
  final service = Get.find<ICompanyService>();

  final navigation = Get.find<INavigationService>();

  static const isDevelopment = String.fromEnvironment("ENVIRONMENT") == "development";

  static const defaultHost = String.fromEnvironment("DEFAULT_HOST");

  final error = "".obs;

  @override
  void onInit() {
    super.onInit();
    navigateToCompanyDomain();
  }

  Future<void> navigateToCompanyDomain() async {
    error.trigger("");

    String subdomain = defaultHost;
    if (kIsWeb && !isDevelopment) {
      subdomain = Uri.base.host.split(".")[0];
    }
    final res = await service.getCompanyBySubdomain(subdomain);

    final companyId = res.data?.id ?? "";

    if (companyId.isEmpty) {
      error.trigger("Não foi possível localizar o estabelecimento");
      return;
    }

    navigation.toSchedule(companyId);
  }
}
