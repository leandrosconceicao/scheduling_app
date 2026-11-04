import 'dart:async';

import 'package:firebase_database/firebase_database.dart';

import '../../domain/domain.dart';

final class CloudService implements ICloudService {
  String get _enviroment => const String.fromEnvironment("ENVIRONMENT");

  bool get isDevelopment => _enviroment == "development";

  @override
  StreamSubscription<dynamic> schedulingSubscription({
    required String companyId,
    required DateTime selectedDate,
    required void Function(Object?) onData,
    Function(Object error)? onError,
  }) {
    return (isDevelopment
            ? FirebaseDatabase.instance.ref(_enviroment).child(companyId)
            : FirebaseDatabase.instance.ref(companyId))
        .child(selectedDate.toRequestDate)
        .onValue
        .listen(
          (DatabaseEvent event) => onData(event.snapshot.value),
          onError: onError,
        );
  }
}
