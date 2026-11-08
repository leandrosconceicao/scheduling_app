import 'package:flutter_test/flutter_test.dart';
import 'package:scheduling_app/src/domain/domain.dart';

CompanyConfiguration _config({
  String open = "09:00",
  String close = "19:00",
  String lunchStart = "12:00",
  String lunchEnd = "13:00",
}) {
  return CompanyConfiguration.fromJson({
    "openingHours": open,
    "closingTime": close,
    "lunchBreak": {"start": lunchStart, "end": lunchEnd},
  });
}

StoreStatus? _at(int hour, int minute, [CompanyConfiguration? config]) =>
    StoreStatus.of(config ?? _config(), DateTime(2026, 11, 8, hour, minute));

void main() {
  group('StoreStatus', () {
    test('is open during opening hours', () {
      final status = _at(10, 30)!;

      expect(status.kind, StoreStatusKind.open);
      expect(status.label, "Aberto agora · fecha às 19:00");
    });

    test('opens exactly at opening time and closes exactly at closing', () {
      expect(_at(9, 0)!.isOpen, isTrue);
      expect(_at(19, 0)!.kind, StoreStatusKind.closed);
    });

    test('reports lunch break', () {
      final status = _at(12, 30)!;

      expect(status.kind, StoreStatusKind.lunch);
      expect(status.label, "Pausa para almoço · volta às 13:00");
      expect(_at(13, 0)!.isOpen, isTrue);
    });

    test('is closed before opening and after closing', () {
      expect(_at(8, 59)!.label, "Fechado · abre hoje às 09:00");
      expect(_at(21, 0)!.label, "Fechado · abre amanhã às 09:00");
    });

    test('works without a lunch break', () {
      final config = _config(lunchStart: "", lunchEnd: "");

      expect(_at(12, 30, config)!.isOpen, isTrue);
    });

    test('ignores a lunch break outside opening hours', () {
      final config = _config(lunchStart: "20:00", lunchEnd: "21:00");

      expect(_at(10, 0, config)!.isOpen, isTrue);
    });

    test('returns null when hours are missing or invalid', () {
      expect(_at(10, 0, _config(open: "")), isNull);
      expect(_at(10, 0, _config(close: "abc")), isNull);
      expect(_at(10, 0, _config(open: "19:00", close: "09:00")), isNull);
    });

    test('accepts seconds in the time strings', () {
      expect(_at(10, 0, _config(open: "09:00:00", close: "18:00:00"))!.isOpen,
          isTrue);
    });
  });
}
