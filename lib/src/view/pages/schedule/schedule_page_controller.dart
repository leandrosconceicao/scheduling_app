import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../domain/domain.dart';
import '../../../shared/shared.dart';
import '../../view.dart';

final class SchedulePageController extends GetxController with AlertActions {
  String companyId;

  StreamSubscription? subscription;

  SchedulePageController(this.companyId);

  final activeStep = 0.obs;

  final service = Get.find<ICompanyService>();

  final authService = Get.find<IAuthService>();

  final cloudService = Get.find<ICloudService>();

  final navigation = Get.find<INavigationService>();

  final companyData = Rxn<Company>();

  final schedules = <Schedule>[].obs;

  final employees = <Employee>[].obs;

  final scheduleTypes = <ScheduleType>[].obs;

  final selectedSchedule = Rxn<Schedule>();  

  final scheduleFormKey = GlobalKey<FormState>();

  final scaffoldKey = GlobalKey<ScaffoldState>();

  static final _now = DateTime.now();

  Runner? runner;

  final selectedPeriod = Rx<DateTimeRange>(
    DateTimeRange(start: _now, end: _now.add(Duration(days: 7))),
  );

  final selectedDate = Rxn<DateTime>();

  final selectedCalender = Rx<Calendar>(Calendar(_now));

  final calendar = <Calendar>[].obs;

  final selectedType = Rxn<ScheduleType>();
  final selectedEmployee = Rxn<Employee>();

  final loading = false.obs;
  final processing = false.obs;

  final pageController = PageController(initialPage: 0);
  final phoneController = MaskedTextController(mask: "(00) 00000-0000");

  bool get typeSelected => selectedType.value != null;
  bool get employeeSelected => selectedEmployee.value != null;
  bool get scheduleSelected => selectedSchedule.value != null;

  bool get confirmationStepEnabled => typeSelected && employeeSelected && scheduleSelected;

  bool get isServiceStep => activeStep.value == 0;
  bool get isEmployeeStep => activeStep.value >= 1;
  bool get isScheduleStep => activeStep.value >= 2;
  bool get isConfirmStep => activeStep.value == 3;

  String get companyLogo => companyData.value?.logoUrl ?? "";
  String get companyName => companyData.value?.name ?? "";
  String get userName => authService.userName;
  String get userEmail => authService.userEmail;
  String get userProfilePhoto => authService.profilePhotoImage;


  bool get isLogged => authService.isLoggedIn && !authService.isAnonymous;

  int? get lockPeriodInMinutes =>
      companyData.value?.configuration.lockSchedulePeriodInMinutes;

  List<ScheduleType> get types => scheduleTypes;

  Client? get clientData => !isLogged
      ? null
      : Client(
          authService.uid,
          authService.userName,
          authService.phoneNumber,
          email: authService.userEmail,
        );

  bool get showScheduleValues =>
      companyData.value?.configuration.showScheduleValues ?? false;

  @override
  void onInit() {
    super.onInit();
    createCalendar();
    Future.wait([loadCompanyData(), loadTypes(), loadEmployees(),]);
    initListener();
    listenCurrentSchedules();
  }

  @override
  void onClose() {
    clearListener();
    clearCurrentRunner();
    super.onClose();
  }

  void listenCurrentSchedules() async {
    runner ??= Runner(
      frequency: const Duration(seconds: 30),
      callback: () async {
        final now = DateTime.now();        

        if (schedules.first.startsAt.isBefore(now)) {
          loadSchedules(true);
        }
      },
    );
    runner?.start();
  }

  void clearCurrentRunner() {
    runner?.stop();
    runner = null;
  }

  void initListener() {
    if (subscription != null) return;

    subscription = cloudService.schedulingSubscription(
      companyId: companyId,
      selectedDate: selectedCalender.value.date,
      onData: listenFunc,
    );
  }

  void listenFunc(Object? value) {
    if (value == null) return;

    loadSchedules();
  }

  void clearListener() {
    subscription?.cancel();
    subscription = null;
  }

  void createCalendar() {
    calendar.clear();
    final dates = Calendar.build(selectedPeriod.value);

    calendar.addAll(dates);
  }

  Future<void> loadCompanyData() async {
    final res = await service.getCompany(companyId);

    companyData.trigger(res.data);
  }

  Future<void> loadEmployees() async {
    
    employees.clear();

    final res = await service.getEmployees(companyId);

    employees.addAll(res.data ?? []);
  }

  Future<void> loadTypes() async {
    scheduleTypes.clear();

    final res = await service.getScheduleTypes(companyId);

    scheduleTypes.addAll(res.data ?? []);
  }

  Future<void> loadSchedules([bool clear = false]) async {
    loading.toggle();
    if (clear) {
      schedules.clear();
    }

    final res = await service.getSchedules(
      companyId,
      startsAt: selectedDate.value,
    );

    // checkItemsOnBasket(res.data ?? []);

    // reloadBasket(res.data ?? []);

    loading.toggle();

    if (schedules.isEmpty) {
      schedules.addAll(res.data ?? []);
      return;
    }

    for (int i = 0; i < (res.data ?? []).length; i++) {
      final updated = res.data![i];
      schedules[i] = updated;
    }

    schedules.refresh();
  }

  void selectSchedule(Schedule? data) async {
    selectedSchedule.trigger(data);
  }

  void selectCalendar(Calendar date) {
    if (selectedCalender.value == date) {
      return;
    }
    clearListener();
    selectSchedule(null);
    selectedCalender.trigger(date);
    loadSchedules(true);
    initListener();
  }

  Future<void> navigateToLogin() async {
    final logged = await navigation.requestLogin(companyId);
    if (logged) initListener();
  }

  void logout() {
    authService.logout();
    scaffoldKey.currentState?.closeDrawer();
    clearListener();
    clearForm();
  }

  void clearForm() {
    clearSelectedSchedule();
    clearSelectedType();
    clearSelectedEmployee();
    _changePage(0);
  }

  Future<({bool isSuccess, Schedule? result})> lockSchedule(
    Schedule value,
  ) async {
    processing.toggle();

    final response = await service.lockSchedule(companyId, value);

    processing.toggle();

    if (response.statusCode == 401) {
      AppAlertDialog.show(body: "Sessão expirada, faça seu login e tente novamente").then((_) {
        navigateToLogin();
      });
      return (isSuccess: false, result: null);
    }

    if (!response.result) {
      AppAlertDialog.show(body:  response.description);
      return (isSuccess: false, result: null);
    }
    return (isSuccess: true, result: response.data);
  }

  void clearSelectedSchedule() {
    selectedSchedule.trigger(null);
  }

  void clearSelectedType() {
    selectedType.trigger(null);
  }

  void clearSelectedEmployee() {
    selectedEmployee.trigger(null);
  }

  void selectType(ScheduleType? type) {
    selectedType.trigger(type);
  }  

  void openDrawer() {
    scaffoldKey.currentState?.openDrawer();
  }

  void closeDrawer() {
    scaffoldKey.currentState?.closeDrawer();
  }
  

  void onNextStep() {    
    if (!scheduleFormKey.currentState!.validate()) {
      return;
    }
    switch (activeStep.value) {
      case 0:
        navigateToServices();
        break;
      case 1:
        navigateToScheduling();
        break;
      case 2:
        navigateToConfirm();
      case 3:
        confirmSchedule();
        break;
    }
  }

  void navigateToConfirm() async {

    if (!isLogged) {
      navigateToLogin();
      return;
    }
    
    final res = await lockSchedule(_selectedSchedule!);

    if (!res.isSuccess) {
      return;
    }

    _changePage(3);
  }

  void navigateToServices() {
    _changePage(1);
  }

  void navigateToScheduling() {
    _changePage(2);
  }

  /// Atualiza a etapa na hora (sem esperar a animação) e só anima se o
  /// formulário estiver aberto.
  void _changePage(int page) {
    activeStep.value = page;
    if (!pageController.hasClients) return;
    pageController.animateToPage(page, duration: const Duration(milliseconds: 400), curve: Curves.easeIn);
  }

  void goBack() {
    _changePage(activeStep.value - 1);
  }

  /// Trata o "voltar" (AppBar, botão do sistema ou do navegador) no formulário.
  ///
  /// Retorna `true` quando a tela pode ser fechada; caso contrário, volta uma
  /// etapa. Na confirmação, libera o horário reservado antes de voltar.
  bool handleFormBack() {
    if (processing.value) return false;

    switch (activeStep.value) {
      case 0:
        return true;
      case 3:
        cancelConfirm();
        return false;
      default:
        goBack();
        return false;
    }
  }

  void selectDate(DateTime date) {
    clearSelectedSchedule();
    selectedDate.trigger(date);
    loadSchedules(true);
  }

  void confirmSchedule() async {

    if (_selectedSchedule == null) {
      showErrorAlert("Dados selecionados são inválidos");
      return;
    }

    if (!isLogged) {
      navigateToLogin();
      return;
    }

    processing.toggle();

    final res = await service.createSchedule(companyId, _selectedSchedule!);

    processing.toggle();

    if (!res.result) {
      showErrorAlert(res.description);
      return;
    }    

    clearForm();
    
    await showSuccessAlert("Agendamento confirmado com sucesso");

    navigation.toSchedule(companyId);
    
  }
  Schedule? get _selectedSchedule {
    if (!confirmationStepEnabled) {
      return null;
    }

    return Schedule(
      startsAt: selectedSchedule.value!.startsAt, 
      endsAt: selectedSchedule.value!.endsAt, 
      companyId: companyId, 
      client: clientData, 
      typeId: selectedType.value!.id!, 
      employeeId: selectedEmployee.value!.id
    );
  }

  void cancelConfirm() async {
    processing.toggle();
    
    await service.removeLockSchedule(companyId, selectedSchedule.value!);

    processing.toggle();
    
    goBack();
  }
}
