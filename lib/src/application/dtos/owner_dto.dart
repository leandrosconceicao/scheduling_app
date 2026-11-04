final class OwnerAuthorizationDto {
  final String username;
  final String token;
  final String? name;
  final String? password;

  OwnerAuthorizationDto(this.username, this.password) : token = "", name = "";

  OwnerAuthorizationDto.fromJson(Map<String, dynamic> json)
    : name = json["name"],
      username = json["username"],
      password = null,
      token = json["token"];

  Map<String, dynamic> toJson() {
    return {"username": username, "password": password};
  }
}
