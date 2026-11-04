import '../../shared/shared.dart';

mixin AlertActions {
  Future showSuccessAlert(String message, {String title = "Atenção"}) {
    return DefaultAlert.show(title: title, message: message);
  }

  Future showErrorAlert(String message, {String title = "Atenção"}) {
    return DefaultAlert.show(title: title, message: message, severity: .error);
  }
}
