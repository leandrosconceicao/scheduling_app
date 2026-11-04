import 'dart:async';

abstract interface class ICloudService {
  StreamSubscription schedulingSubscription({
    required String companyId,
    required DateTime selectedDate,
    required void Function(Object?) onData,
    Function(Object error)? onError,
  });
}
