final class Client {
  String uid;
  String name;
  String phoneNumber;
  String? email;

  Client(this.uid, this.name, this.phoneNumber, {this.email});

  Client.fromJson(Map<String, dynamic> json)
    : uid = json['uid'] ?? "",
      name = json['name'] ?? "",
      phoneNumber = json['phoneNumber'] ?? "",
      email = json['email'];

  Map<String, dynamic> toJson() {
    return {
      "uid": uid,
      "phoneNumber": phoneNumber,
      "name": name,
      if (email?.isNotEmpty ?? false) "email": email,
    };
  }
}
