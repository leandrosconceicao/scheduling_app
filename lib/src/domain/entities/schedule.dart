import 'dart:convert';

import 'package:flutter/material.dart';

import '../domain.dart';

final class Schedule {
  DateTime startsAt;
  DateTime endsAt;
  String companyId;
  Client? client;
  String typeId;
  ScheduleState state;
  String id;
  String stateDescription;
  ScheduleLockExpiration? lockExpiration;
  ScheduleType? typeDetail;
  String employeeId;
  Employee? employee;


  Schedule({
    required this.startsAt,
    required this.endsAt,
    required this.companyId,
    required this.client,
    required this.typeId,
    required this.employeeId,
  }) : id = "",
       stateDescription = "",
       state = ScheduleState.open;

  Schedule.fromJson(Map<String, dynamic> json)
    : startsAt = DateTime.parse(json["startsAt"] ?? "").toLocal(),
      endsAt = DateTime.parse(json["endsAt"]).toLocal(),
      companyId = json["companyId"] ?? "",
      client = json["client"] == null ? null : Client.fromJson(json['client']),
      typeId = json["typeId"] ?? "",
      state = ScheduleState.values.firstWhere(
        (e) => e.code == (json["state"] ?? "open"),
      ),
      stateDescription = json['stateDescription'] ?? "Aberto",
      lockExpiration = json['lockPeriodDetail'] == null ? null : ScheduleLockExpiration.fromJson(json['lockPeriodDetail']),
      typeDetail = json['typeDetail'] == null ? null : ScheduleType.fromJson(json['typeDetail']),
      employeeId = json['employeeId'] ?? "",
      employee = json['employeeDetail'] == null ? null : Employee.fromJson(json['employeeDetail']),
      id = json["_id"] ?? "";

  Map<String, dynamic> toJson() {
    return {
      "startsAt": "${startsAt.toIso8601String()}-03:00",
      "endsAt": "${endsAt.toIso8601String()}-03:00",
      "typeId": typeId,
      "employeeId": employeeId,
      "client": client?.toJson()
    };
  }

  Map<String, dynamic> toDeleteJson() {
    return {
      "startsAt": startsAt.toUtc().toIso8601String(),
      "endsAt": endsAt.toUtc().toIso8601String(),
      "client": client?.uid,
    };
  }

  String get key {
    return "$companyId:${startsAt.toIso8601String()}_${endsAt.toIso8601String()}";
  }

  static List<Schedule> toList(List json) =>
      json.map((e) => Schedule.fromJson(e)).toList();

  TimeOfDay get startTime => TimeOfDay.fromDateTime(startsAt);
  TimeOfDay get endTime => TimeOfDay.fromDateTime(endsAt);

  bool get isOpen => state == .open;
  bool get isScheduled => state == .scheduled;
  bool get isClosed => state == .closed;
  bool get isLocked => state == .lock;

  Duration get duration => endsAt.difference(startsAt);

  DateTime? get expiresAt => lockExpiration?.expiresAt;

  String? get clientUid => client?.uid;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Schedule &&
        startsAt.isAtSameMomentAs(other.startsAt) &&
        endsAt.isAtSameMomentAs(other.endsAt) &&
        companyId == other.companyId;
  }

  @override
  int get hashCode => Object.hash(startsAt, endsAt, companyId);  

  @override String toString() {
    return jsonEncode(this);
  }
}
