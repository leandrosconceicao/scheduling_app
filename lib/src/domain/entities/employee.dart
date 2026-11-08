final class Employee {
  final String id;
  final String name;
  final String profilePhotoUrl;
  final String companyId;
  final num rating;
  DateTime? createdAt;
  DateTime? updatedAt;

  Employee(this.name, this.profilePhotoUrl, this.companyId)
    : id = "",
      rating = 0;

  Employee.fromJson(Map<String, dynamic> json)
    : id = json["_id"] ?? "",
      name = json["name"] ?? "",
      profilePhotoUrl = json["profilePhotoUrl"] ?? "",
      companyId = json["companyId"] ?? "",
      rating = json["rating"] ?? 0,
      createdAt = DateTime.tryParse(json["createdAt"] ?? ""),
      updatedAt = DateTime.tryParse(json["updatedAt"] ?? "");

  /// Cópia com o nome novo, preservando id, foto, avaliação e datas.
  Employee copyWith({String? name}) {
    return Employee.fromJson({
      "_id": id,
      "name": name ?? this.name,
      "profilePhotoUrl": profilePhotoUrl,
      "companyId": companyId,
      "rating": rating,
      "createdAt": createdAt?.toIso8601String(),
      "updatedAt": updatedAt?.toIso8601String(),
    });
  }

  Map<String, dynamic> toJson() {
    // A foto é enviada por arquivo, em rota própria.
    return {"name": name};
  }

  static List<Employee> toList(List json) =>
      json.map((e) => Employee.fromJson(e)).toList();
}
