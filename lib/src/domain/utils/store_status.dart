import '../entities/company.dart';

enum StoreStatusKind { open, lunch, closed }

/// Situação da loja num instante: aberta, em pausa de almoço ou fechada.
final class StoreStatus {
  final StoreStatusKind kind;

  /// Texto curto para o selo, ex.: "Aberto agora · fecha às 19:00".
  final String label;

  const StoreStatus(this.kind, this.label);

  bool get isOpen => kind == StoreStatusKind.open;

  /// Calcula a situação pelos dias e horários de funcionamento da empresa.
  ///
  /// Retorna `null` quando o horário de hoje não está configurado (ou é
  /// inválido), para a tela esconder o selo em vez de mostrar algo errado.
  static StoreStatus? of(CompanyConfiguration config, DateTime now) {
    final today = config.hoursOn(now);

    if (today == null) {
      return StoreStatus(
        StoreStatusKind.closed,
        _nextOpening(config, now, "Fechado hoje"),
      );
    }

    final opening = _minutes(today.openingHours);
    final closing = _minutes(today.closingTime);
    if (opening == null || closing == null || closing <= opening) return null;

    final current = now.hour * 60 + now.minute;
    final lunchStart = _minutes(today.lunchBreak?.start ?? "");
    final lunchEnd = _minutes(today.lunchBreak?.end ?? "");
    final hasLunch =
        lunchStart != null &&
        lunchEnd != null &&
        lunchStart < lunchEnd &&
        lunchStart >= opening &&
        lunchEnd <= closing;

    if (current < opening) {
      return StoreStatus(
        StoreStatusKind.closed,
        "Fechado · abre hoje às ${_format(opening)}",
      );
    }
    if (current >= closing) {
      return StoreStatus(
        StoreStatusKind.closed,
        _nextOpening(config, now, "Fechado"),
      );
    }
    if (hasLunch && current >= lunchStart && current < lunchEnd) {
      return StoreStatus(
        StoreStatusKind.lunch,
        "Pausa para almoço · volta às ${_format(lunchEnd)}",
      );
    }
    return StoreStatus(
      StoreStatusKind.open,
      "Aberto agora · fecha às ${_format(closing)}",
    );
  }

  /// "Fechado · abre amanhã às 09:00" ou "... abre segunda às 09:00",
  /// pelo próximo dia de funcionamento com horário válido.
  static String _nextOpening(
    CompanyConfiguration config,
    DateTime now,
    String prefix,
  ) {
    for (var offset = 1; offset <= 7; offset++) {
      final date = DateTime(now.year, now.month, now.day + offset);
      final hours = config.hoursOn(date);
      final opening = _minutes(hours?.openingHours ?? "");
      final closing = _minutes(hours?.closingTime ?? "");
      if (opening == null || closing == null || closing <= opening) continue;

      final when = offset == 1 ? "amanhã" : WeekDays.name(WeekDays.of(date));
      return "$prefix · abre $when às ${_format(opening)}";
    }
    return prefix;
  }

  /// "09:00" ou "09:00:00" em minutos desde a meia-noite.
  static int? _minutes(String value) {
    final parts = value.trim().split(":");
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
    return hour * 60 + minute;
  }

  static String _format(int minutes) {
    final h = (minutes ~/ 60).toString().padLeft(2, "0");
    final m = (minutes % 60).toString().padLeft(2, "0");
    return "$h:$m";
  }
}

/// Dias consecutivos (de segunda a domingo) com o mesmo horário, para exibir
/// a semana de forma compacta: "Seg a Sex", "Sáb", "Dom".
final class WeeklyHours {
  /// Dias do grupo no padrão da API (0 = domingo ... 6 = sábado).
  final List<int> days;

  /// `null` quando a empresa não abre nesses dias.
  final DayHours? hours;

  const WeeklyHours(this.days, this.hours);

  bool get closed => hours == null;

  bool contains(DateTime date) => days.contains(WeekDays.of(date));

  String get label {
    if (days.length == 7) return "Todos os dias";
    final first = WeekDays.shortName(days.first);
    final last = WeekDays.shortName(days.last);
    return switch (days.length) {
      1 => first,
      2 => "$first e $last",
      _ => "$first a $last",
    };
  }

  /// Semana a partir de segunda, agrupando dias seguidos com o mesmo horário.
  static List<WeeklyHours> of(CompanyConfiguration config) {
    const order = [1, 2, 3, 4, 5, 6, 0];
    final groups = <WeeklyHours>[];

    for (final day in order) {
      final workingDay = config.workingDays.where((e) => e.day == day);
      final hours = workingDay.isEmpty ? null : config.hoursOf(workingDay.first);

      if (groups.isNotEmpty && groups.last.hours == hours) {
        groups.last.days.add(day);
      } else {
        groups.add(WeeklyHours([day], hours));
      }
    }
    return groups;
  }
}
