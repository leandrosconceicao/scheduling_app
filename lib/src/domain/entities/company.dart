import 'package:flutter/material.dart';

import '../domain.dart';

final class Company {
  final String id;
  final String cnpj;
  final String name;
  final String logoUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Address address;
  final CompanyConfiguration configuration;
  final Social social;
  final GeoLocation geoLocation;
  final List<ScheduleType> scheduleTypes;

  Company({
    required this.id,
    required this.cnpj,
    required this.name,
    required this.logoUrl,
    required this.address,
    required this.configuration,
    required this.social,
    required this.geoLocation,
    this.createdAt,
    this.updatedAt,
  }) : scheduleTypes = [];

  Company.fromJson(Map<String, dynamic> json)
    : id = json['_id'] ?? '',
      cnpj = json['cnpj'] ?? '',
      name = json['name'] ?? '',
      logoUrl = json['logoUrl'] ?? '',
      createdAt = DateTime.tryParse(json['createdAt'] ?? ''),
      updatedAt = DateTime.tryParse(json['updatedAt'] ?? ''),
      address = Address.fromJson(json['address'] ?? const <String, dynamic>{}),
      configuration = CompanyConfiguration.fromJson(
        json['configuration'] ?? const <String, dynamic>{},
      ),
      social = Social.fromJson(json['social'] ?? const <String, dynamic>{}),
      geoLocation = GeoLocation.fromJson(
        json['geoLocation'] ?? const <String, dynamic>{},
      ),
      scheduleTypes = json['scheduleTypes'] != null
          ? ScheduleType.toList(json['scheduleTypes'])
          : [];

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'cnpj': cnpj,
      'name': name,
      'logoUrl': logoUrl,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'address': address.toJson(),
      'configuration': configuration.toJson(),
      'social': social.toJson(),
      'geoLocation': geoLocation.toJson(),
    };
  }

  static List<Company> toList(List<dynamic> json) =>
      json.map((e) => Company.fromJson(e as Map<String, dynamic>)).toList();
}

extension AddressDisplay on Address {
  /// "Rua X, 123 - Compl" (partes vazias são omitidas).
  String get streetLine {
    final number = this.number.isEmpty ? "" : ", ${this.number}";
    final compl = complement.isEmpty ? "" : " - $complement";
    return street.isEmpty ? "" : "$street$number$compl";
  }

  /// "Bairro, Cidade - UF".
  String get cityLine {
    final place = [neighborhood, city].where((e) => e.isNotEmpty).join(", ");
    if (state.isEmpty) return place;
    return place.isEmpty ? state : "$place - $state";
  }

  /// Endereço completo, usado também como busca no mapa.
  String get fullAddress =>
      [streetLine, cityLine, zipCode].where((e) => e.isNotEmpty).join(", ");

  bool get isEmpty => fullAddress.isEmpty;
}

final class Address {
  final String zipCode;
  final String street;
  final String number;
  final String complement;
  final String neighborhood;
  final String city;
  final String cityCode;
  final String state;
  final String countryCode;

  Address({
    required this.zipCode,
    required this.street,
    required this.number,
    required this.complement,
    required this.neighborhood,
    required this.city,
    required this.cityCode,
    required this.state,
    required this.countryCode,
  });

  Address.fromJson(Map<String, dynamic> json)
    : zipCode = json['zipCode'] ?? '',
      street = json['street'] ?? '',
      number = json['number'] ?? '',
      complement = json['complement'] ?? '',
      neighborhood = json['neighborhood'] ?? '',
      city = json['city'] ?? '',
      cityCode = json['cityCode'] ?? '',
      state = json['state'] ?? '',
      countryCode = json['countryCode'] ?? '';

  Map<String, dynamic> toJson() {
    return {
      'zipCode': zipCode,
      'street': street,
      'number': number,
      'complement': complement,
      'neighborhood': neighborhood,
      'city': city,
      'cityCode': cityCode,
      'state': state,
      'countryCode': countryCode,
    };
  }
}

final class CompanyConfiguration {
  final LunchBreak lunchBreak;
  final int defaultPeriodInMinutes;
  final String openingHours;
  final String closingTime;
  final int lockSchedulePeriodInMinutes;
  final bool showScheduleValues;

  /// Dias em que a empresa funciona, ordenados (0 = domingo ... 6 = sábado).
  /// Empresas sem a configuração funcionam todos os dias, como na API.
  final List<WorkingDay> workingDays;

  CompanyConfiguration({
    required this.lunchBreak,
    required this.defaultPeriodInMinutes,
    required this.openingHours,
    required this.closingTime,
    required this.lockSchedulePeriodInMinutes,
    this.showScheduleValues = false,
    List<WorkingDay>? workingDays,
  }) : workingDays = _normalize(workingDays);

  CompanyConfiguration.fromJson(Map<String, dynamic> json)
    : lunchBreak = LunchBreak.fromJson(
        json['lunchBreak'] ?? const <String, dynamic>{},
      ),
      showScheduleValues = json['showSchedulesValues'] ?? false,
      defaultPeriodInMinutes = json['defaultPeriodInMinutes'] is int
          ? json['defaultPeriodInMinutes'] as int
          : int.tryParse('${json['defaultPeriodInMinutes'] ?? 0}') ?? 0,
      openingHours = json['openingHours'] ?? '',
      lockSchedulePeriodInMinutes = json['lockSchedulePeriodInMinutes'] ?? 0,
      closingTime = json['closingTime'] ?? '',
      workingDays = _normalize(
        (json['workingDays'] as List<dynamic>? ?? const [])
            .map(WorkingDay.tryParse)
            .whereType<WorkingDay>()
            .toList(),
      );

  static List<WorkingDay> _normalize(List<WorkingDay>? days) {
    if (days == null || days.isEmpty) {
      return List.unmodifiable(WeekDays.all.map(WorkingDay.new));
    }
    final byDay = {for (final item in days) item.day: item};
    return List.unmodifiable(
      byDay.values.toList()..sort((a, b) => a.day.compareTo(b.day)),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lunchBreak': lunchBreak.toJson(),
      'defaultPeriodInMinutes': defaultPeriodInMinutes,
      'openingHours': openingHours,
      'closingTime': closingTime,
      // A API exige período positivo.
      if (lockSchedulePeriodInMinutes > 0)
        'lockSchedulePeriodInMinutes': lockSchedulePeriodInMinutes,
      'workingDays': workingDays.map((e) => e.toJson()).toList(),
    };
  }

  TimeOfDay get parseOpening => openingHours.parseTimeOfDay;

  TimeOfDay get parseClosing => closingTime.parseTimeOfDay;

  /// Configuração do dia da semana de [date], ou `null` se a empresa não abre.
  WorkingDay? workingDayOf(DateTime date) {
    final day = WeekDays.of(date);
    for (final item in workingDays) {
      if (item.day == day) return item;
    }
    return null;
  }

  bool isOpenOn(DateTime date) => workingDayOf(date) != null;

  /// Horário efetivo no dia de [date] (o do próprio dia ou, na falta dele, o
  /// padrão da empresa), ou `null` se a empresa não abre nesse dia.
  DayHours? hoursOn(DateTime date) {
    final workingDay = workingDayOf(date);
    return workingDay == null ? null : hoursOf(workingDay);
  }

  /// Mesma regra de herança da API: campos omitidos usam o padrão e
  /// `lunchBreak: null` no dia indica que não há almoço.
  DayHours hoursOf(WorkingDay workingDay) {
    final lunch = workingDay.overridesLunchBreak
        ? workingDay.lunchBreak
        : lunchBreak;

    return DayHours(
      openingHours: workingDay.openingHours ?? openingHours,
      closingTime: workingDay.closingTime ?? closingTime,
      lunchBreak: lunch != null && lunch.start.isNotEmpty && lunch.end.isNotEmpty
          ? lunch
          : null,
    );
  }
}

/// Dias da semana no padrão da API (`Date.getDay()`): 0 = domingo ... 6 = sábado.
abstract final class WeekDays {
  static const all = [0, 1, 2, 3, 4, 5, 6];

  static const _names = [
    "domingo",
    "segunda",
    "terça",
    "quarta",
    "quinta",
    "sexta",
    "sábado",
  ];

  static const _short = ["Dom", "Seg", "Ter", "Qua", "Qui", "Sex", "Sáb"];

  /// Converte o `weekday` do Dart (1 = segunda ... 7 = domingo).
  static int of(DateTime date) => date.weekday % 7;

  static String name(int day) => _names[day];

  static String shortName(int day) => _short[day];
}

/// Dia de funcionamento. Campos `null` herdam o horário padrão da empresa.
final class WorkingDay {
  final int day;
  final String? openingHours;
  final String? closingTime;

  /// Almoço próprio do dia; só vale quando [overridesLunchBreak] é verdadeiro
  /// (`null` nesse caso indica que não há almoço no dia).
  final LunchBreak? lunchBreak;
  final bool overridesLunchBreak;

  const WorkingDay(
    this.day, {
    this.openingHours,
    this.closingTime,
    this.lunchBreak,
    this.overridesLunchBreak = false,
  });

  /// Aceita o número do dia ou o objeto `{ day, openingHours?, ... }`.
  static WorkingDay? tryParse(dynamic json) {
    if (json is num) return _validDay(json.toInt()) ? WorkingDay(json.toInt()) : null;
    if (json is! Map) return null;

    final day = json['day'];
    if (day is! num || !_validDay(day.toInt())) return null;

    String? time(String key) {
      final value = json[key];
      return value is String && value.isNotEmpty ? value : null;
    }

    final lunch = json['lunchBreak'];
    return WorkingDay(
      day.toInt(),
      openingHours: time('openingHours'),
      closingTime: time('closingTime'),
      overridesLunchBreak: json.containsKey('lunchBreak'),
      lunchBreak: lunch is Map
          ? LunchBreak.fromJson(Map<String, dynamic>.from(lunch))
          : null,
    );
  }

  static bool _validDay(int day) => day >= 0 && day <= 6;

  Map<String, dynamic> toJson() {
    return {
      'day': day,
      if (openingHours != null) 'openingHours': openingHours,
      if (closingTime != null) 'closingTime': closingTime,
      if (overridesLunchBreak) 'lunchBreak': lunchBreak?.toJson(),
    };
  }
}

/// Horário efetivo de um dia de funcionamento.
final class DayHours {
  final String openingHours;
  final String closingTime;
  final LunchBreak? lunchBreak;

  const DayHours({
    required this.openingHours,
    required this.closingTime,
    this.lunchBreak,
  });

  @override
  bool operator ==(Object other) =>
      other is DayHours &&
      other.openingHours == openingHours &&
      other.closingTime == closingTime &&
      other.lunchBreak?.start == lunchBreak?.start &&
      other.lunchBreak?.end == lunchBreak?.end;

  @override
  int get hashCode =>
      Object.hash(openingHours, closingTime, lunchBreak?.start, lunchBreak?.end);
}

final class LunchBreak {
  final String start;
  final String end;

  LunchBreak({required this.start, required this.end});

  LunchBreak.fromJson(Map<String, dynamic> json)
    : start = json['start'] ?? '',
      end = json['end'] ?? '';

  Map<String, dynamic> toJson() {
    return {'start': start, 'end': end};
  }

  TimeOfDay get startTimeOfDay => start.parseTimeOfDay;

  TimeOfDay get endTimeOfDay => end.parseTimeOfDay;
}

final class Social {
  final String instagram;
  final String facebook;
  final String whatsapp;
  final String email;
  final String phone;

  Social({
    required this.instagram,
    required this.facebook,
    required this.whatsapp,
    required this.email,
    required this.phone,
  });

  Social.fromJson(Map<String, dynamic> json)
    : instagram = json['instagram'] ?? '',
      facebook = json['facebook'] ?? '',
      whatsapp = json['whatsapp'] ?? '',
      email = json['email'] ?? '',
      phone = json['phone'] ?? '';

  Map<String, dynamic> toJson() {
    return {
      'instagram': instagram,
      'facebook': facebook,
      'whatsapp': whatsapp,
      'email': email,
      'phone': phone,
    };
  }
}

final class GeoLocation {
  final String type;
  final List<double> coordinates;

  GeoLocation({required this.type, required this.coordinates});

  GeoLocation.fromJson(Map<String, dynamic> json)
    : type = json['type'] ?? 'Point',
      coordinates = (json['coordinates'] as List<dynamic>? ?? const [])
          .map((e) => (e as num).toDouble())
          .toList();

  Map<String, dynamic> toJson() {
    return {'type': type, 'coordinates': coordinates};
  }
}
