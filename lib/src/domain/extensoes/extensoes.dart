import 'package:flutter/material.dart';
import 'package:ltech_core/ltech_core.dart';
import 'package:money2/money2.dart';

extension Texts on DateTime {
  String get toRequestDate {
    return toIso8601String().split("T")[0];
  }

  String get onlyHours {
    return TimeOfDay(hour: hour, minute: minute).parseToString;
  }

  String get dateDescription {
    return "$day de $parseMonth de $year";
  }
}

extension Times on String {
  TimeOfDay get parseTimeOfDay {
    return TimeOfDay.fromDateTime(
      DateTime.parse("${DateTime.now().toRequestDate}T$this"),
    );
  }
}

extension Monetization on num {
  String get ptBrCoin => "${Money.fromNum(this, isoCode: "BRL", decimalDigits: 2)}";
}