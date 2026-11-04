class ScheduleType {
  final String? id;
  final String companyId;
  String name;
  DateTime? createdAt;
  DateTime? updatedAt;
  num price;

  ScheduleType(this.companyId, this.name, this.price, {this.id});

  ScheduleType.fromJson(Map<String, dynamic> json)
    : id = json['_id'] ?? "",
      companyId = json['companyId'] ?? "",
      name = json['name'] ?? "",
      createdAt = DateTime.tryParse(json['createdAt'] ?? ""),
      updatedAt = DateTime.tryParse(json['updatedAt'] ?? ""),
      price = json['priceAsNumber'] ?? 0.0;

  Map<String, dynamic> toJson() {
    return {"name": name, "price": price};
  }

  static List<ScheduleType> toList(List json) =>
      json.map((e) => ScheduleType.fromJson(e)).toList();

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ScheduleType &&
        other.id == id &&
        other.name == name;
  }

  @override
  int get hashCode => Object.hash(id, name);
}
