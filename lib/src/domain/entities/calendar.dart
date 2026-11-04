import 'package:flutter/material.dart';
import 'package:ltech_core/ltech_core.dart';

final class Calendar {
  DateTime date;

  Calendar(this.date);

  String get weekDay => date.parseWeekDay;

  String get simpleWeek => weekDay.substring(0, 3);

  String get day => date.day.toString();

  int get dayOfweek => date.weekday;

  bool get today => date.weekday == DateTime.now().weekday;

  static List<Calendar> build(DateTimeRange range) {
    final dates = List.generate(range.duration.inDays, (e) {
      final start = range.start.parseStart;

      return Calendar(start.add(Duration(days: e)));
    });

    return dates;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Calendar && date.isAtSameMomentAs(other.date);
  }

  @override
  int get hashCode => date.microsecondsSinceEpoch.hashCode;
}
