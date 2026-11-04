import 'dart:convert';

final class ScheduleLockExpiration {
  DateTime expiresAt;
  String uid;

  ScheduleLockExpiration.fromJson(Map<String, dynamic> json) :
    uid = json['uid'] ?? "",
    expiresAt = json['expiresAt'] != null ? DateTime.parse(json['expiresAt'] ?? "").toLocal() : DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      "uid": uid,
      "expiresAt": expiresAt.toIso8601String()
    };
  }

  @override
  String toString() {
    return jsonEncode(this);
  }
}