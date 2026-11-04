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

  CompanyConfiguration({
    required this.lunchBreak,
    required this.defaultPeriodInMinutes,
    required this.openingHours,
    required this.closingTime,
    required this.lockSchedulePeriodInMinutes,
    this.showScheduleValues = false,
  });

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
      closingTime = json['closingTime'] ?? '';

  Map<String, dynamic> toJson() {
    return {
      'lunchBreak': lunchBreak.toJson(),
      'defaultPeriodInMinutes': defaultPeriodInMinutes,
      'openingHours': openingHours,
      'closingTime': closingTime,
    };
  }

  TimeOfDay get parseOpening => openingHours.parseTimeOfDay;

  TimeOfDay get parseClosing => closingTime.parseTimeOfDay;
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
