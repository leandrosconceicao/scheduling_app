import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:ltech_core/ltech_core.dart';

import 'firebase_options.dart';
import 'src/application/application.dart';
import 'src/core/core.dart';
import 'src/domain/domain.dart';
import 'src/repository/repository.dart';
import 'src/routes/routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  GoRouter.optionURLReflectsImperativeAPIs = true;
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform
  );
  dependencyInjection();
  runApp(MyApp());
}

void dependencyInjection() {
  Get.put<ILocalRepository>(LocalRepository());
  Get.put<IOwnerSessionService>(
    OwnerSessionService(Get.find<ILocalRepository>()),
  );
  Get.put<ICloudService>(CloudService());
  Get.put<IAuthService>(AuthService());
  Get.put<IHttpClient>(HttpClient());
  Get.put<ICompanyService>(
    CompanyConfigService(
      Get.find<IHttpClient>(),
      Get.find<IOwnerSessionService>(),
    ),
  );
  Get.put<IOwnerScheduleService>(
    OwnerScheduleService(
      Get.find<IHttpClient>(),
      Get.find<IOwnerSessionService>(),
    ),
  );
  Get.lazyPut<INavigationService>(
    () => GoRouterNavigationService(AppRouter().instance),
    fenix: true,
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: AppRouter().instance,
      scaffoldMessengerKey: scaffoldMessengerKey,
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      supportedLocales: const [Locale("pt")],
    );
  }
}
