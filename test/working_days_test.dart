import 'package:flutter_test/flutter_test.dart';
import 'package:scheduling_app/src/domain/domain.dart';

// 2026-11-08 é domingo; 2026-11-09, segunda; 2026-11-14, sábado.
CompanyConfiguration _config([List<dynamic>? workingDays]) {
  return CompanyConfiguration.fromJson({
    "openingHours": "09:00",
    "closingTime": "19:00",
    "lunchBreak": {"start": "12:00", "end": "13:00"},
    "workingDays": ?workingDays,
  });
}

final _weekdaysAndShortSaturday = [
  for (final day in [1, 2, 3, 4, 5]) {"day": day},
  {"day": 6, "openingHours": "08:00", "closingTime": "12:00", "lunchBreak": null},
];

void main() {
  group("CompanyConfiguration.workingDays", () {
    test("defaults to every day when the API sends nothing", () {
      final config = _config();

      expect(config.workingDays.map((e) => e.day), [0, 1, 2, 3, 4, 5, 6]);
      expect(config.isOpenOn(DateTime(2026, 11, 8)), isTrue);
    });

    test("accepts plain numbers and objects, sorted by day", () {
      final config = _config([5, {"day": 1}, 3]);

      expect(config.workingDays.map((e) => e.day), [1, 3, 5]);
      expect(config.isOpenOn(DateTime(2026, 11, 9)), isTrue);
      expect(config.isOpenOn(DateTime(2026, 11, 8)), isFalse);
    });

    test("applies per-day hours and inherits the rest", () {
      final config = _config(_weekdaysAndShortSaturday);

      final saturday = config.hoursOn(DateTime(2026, 11, 14))!;
      expect(saturday.openingHours, "08:00");
      expect(saturday.closingTime, "12:00");
      expect(saturday.lunchBreak, isNull);

      final monday = config.hoursOn(DateTime(2026, 11, 9))!;
      expect(monday.openingHours, "09:00");
      expect(monday.lunchBreak?.start, "12:00");

      expect(config.hoursOn(DateTime(2026, 11, 8)), isNull);
    });

    test("serializes working days in the API format", () {
      final json = _config(_weekdaysAndShortSaturday).toJson();

      expect((json["workingDays"] as List).last, {
        "day": 6,
        "openingHours": "08:00",
        "closingTime": "12:00",
        "lunchBreak": null,
      });
      expect((json["workingDays"] as List).first, {"day": 1});
    });
  });

  group("StoreStatus with working days", () {
    final config = _config(_weekdaysAndShortSaturday);

    test("is closed on a day off and points to the next opening", () {
      final status = StoreStatus.of(config, DateTime(2026, 11, 8, 10))!;

      expect(status.kind, StoreStatusKind.closed);
      expect(status.label, "Fechado hoje · abre amanhã às 09:00");
    });

    test("uses the day's own hours", () {
      final saturday = StoreStatus.of(config, DateTime(2026, 11, 14, 11))!;
      expect(saturday.label, "Aberto agora · fecha às 12:00");

      // Sem almoço no sábado.
      expect(StoreStatus.of(config, DateTime(2026, 11, 14, 11, 59))!.isOpen,
          isTrue);
    });

    test("skips days off when announcing the next opening", () {
      final status = StoreStatus.of(config, DateTime(2026, 11, 14, 13))!;

      expect(status.label, "Fechado · abre segunda às 09:00");
    });
  });

  group("WeeklyHours", () {
    test("groups consecutive days with the same hours", () {
      final groups = WeeklyHours.of(_config(_weekdaysAndShortSaturday));

      expect(groups.map((e) => e.label), ["Seg a Sex", "Sáb", "Dom"]);
      expect(groups.last.closed, isTrue);
    });

    test("collapses an all-week schedule", () {
      final groups = WeeklyHours.of(_config());

      expect(groups.map((e) => e.label), ["Todos os dias"]);
    });
  });

  test("Schedule sends the phone number at the body root", () {
    final json = Schedule(
      startsAt: DateTime(2026, 11, 9, 9),
      endsAt: DateTime(2026, 11, 9, 9, 30),
      companyId: "c",
      client: Client("uid", "Ana", "11999999999"),
      typeId: "t",
      employeeId: "e",
    ).toJson();

    expect(json["phoneNumber"], "11999999999");
  });
}
