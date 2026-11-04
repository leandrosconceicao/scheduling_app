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


  Map<String, dynamic> toJson() {
    return {"name": name, "profilePhotoUrl": profilePhotoUrl};
  }

  static List<Employee> toList(List json) =>
      json.map((e) => Employee.fromJson(e)).toList();
}
