import 'package:get/get.dart';

import '../../../../domain/domain.dart';
import '../../../../shared/shared.dart';

final class CompanyConfigurationController extends GetxController {
  final String companyId;

  final companyData = Rxn<ApiResponse<Company?>>();

  final _service = Get.find<ICompanyService>();

  CompanyConfigurationController(this.companyId);

  @override
  void onInit() {
    loadCompanyData();
    super.onInit();
  }

  void loadCompanyData() async {

    companyData.trigger(null);
    
    if (!companyId.hasContent) {
      companyData.trigger(ApiResponse.notFound(message: "Empresa não localizada"));
      return;
    }

    final response = await _service.getCompany(companyId);

    companyData.trigger(response);
  }
}