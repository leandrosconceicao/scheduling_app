import '../entities/company.dart';

/// Monta os links externos da loja (mapa, WhatsApp, redes sociais).
/// Cada método devolve `null` quando o dado não está preenchido.
abstract final class StoreLinks {
  /// Rota até a loja. Prefere as coordenadas (GeoJSON: `[longitude, latitude]`)
  /// e cai para a busca pelo endereço.
  static Uri? directions(Company company) {
    final coords = company.geoLocation.coordinates;
    if (coords.length >= 2 && !(coords[0] == 0 && coords[1] == 0)) {
      return Uri.https("www.google.com", "/maps/dir/", {
        "api": "1",
        "destination": "${coords[1]},${coords[0]}",
      });
    }
    final address = company.address.fullAddress;
    if (address.isEmpty) return null;
    return Uri.https("www.google.com", "/maps/search/", {
      "api": "1",
      "query": address,
    });
  }

  static Uri? whatsapp(String value) {
    var digits = _digits(value);
    if (digits.isEmpty) return null;
    // Número nacional (DDD + número) ganha o código do Brasil.
    if (digits.length <= 11) digits = "55$digits";
    return Uri.https("wa.me", "/$digits");
  }

  static Uri? phone(String value) {
    final digits = _digits(value);
    return digits.isEmpty ? null : Uri(scheme: "tel", path: digits);
  }

  static Uri? email(String value) {
    final email = value.trim();
    return email.isEmpty ? null : Uri(scheme: "mailto", path: email);
  }

  static Uri? instagram(String value) => _social(value, "www.instagram.com");

  static Uri? facebook(String value) => _social(value, "www.facebook.com");

  /// Aceita URL completa ou só o usuário (com ou sem "@").
  static Uri? _social(String value, String host) {
    final handle = value.trim();
    if (handle.isEmpty) return null;
    if (handle.startsWith("http://") || handle.startsWith("https://")) {
      return Uri.tryParse(handle);
    }
    final user = handle.replaceFirst(RegExp(r"^@"), "");
    return user.isEmpty ? null : Uri.https(host, "/$user");
  }

  static String _digits(String value) => value.replaceAll(RegExp(r"\D"), "");
}
