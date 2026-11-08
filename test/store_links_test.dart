import 'package:flutter_test/flutter_test.dart';
import 'package:scheduling_app/src/domain/domain.dart';

Company _company({Map<String, dynamic> address = const {}, List<double>? coords}) {
  return Company.fromJson({
    "_id": "c1",
    "address": address,
    "geoLocation": {"type": "Point", "coordinates": coords ?? []},
  });
}

void main() {
  group('StoreLinks.directions', () {
    test('uses coordinates (GeoJSON is longitude, latitude)', () {
      final uri = StoreLinks.directions(_company(coords: [-46.6, -23.5]))!;

      expect(uri.queryParameters["destination"], "-23.5,-46.6");
    });

    test('falls back to the address', () {
      final uri = StoreLinks.directions(
        _company(address: {"street": "Rua A", "number": "10", "city": "SP"}),
      )!;

      expect(uri.queryParameters["query"], "Rua A, 10, SP");
    });

    test('is null without coordinates or address', () {
      expect(StoreLinks.directions(_company()), isNull);
      expect(StoreLinks.directions(_company(coords: [0, 0])), isNull);
    });
  });

  group('StoreLinks contacts', () {
    test('whatsapp adds the country code to national numbers', () {
      expect(StoreLinks.whatsapp("(11) 98888-7777")!.toString(),
          "https://wa.me/5511988887777");
      expect(StoreLinks.whatsapp("+55 11 98888-7777")!.toString(),
          "https://wa.me/5511988887777");
      expect(StoreLinks.whatsapp(""), isNull);
    });

    test('phone and email', () {
      expect(StoreLinks.phone("(11) 3333-4444")!.toString(), "tel:1133334444");
      expect(StoreLinks.email("a@b.com")!.toString(), "mailto:a@b.com");
      expect(StoreLinks.email("  "), isNull);
    });

    test('social accepts handle, @handle and full URL', () {
      expect(StoreLinks.instagram("@barbearia")!.toString(),
          "https://www.instagram.com/barbearia");
      expect(StoreLinks.instagram("barbearia")!.toString(),
          "https://www.instagram.com/barbearia");
      expect(StoreLinks.facebook("https://facebook.com/x")!.toString(),
          "https://facebook.com/x");
      expect(StoreLinks.instagram("@"), isNull);
    });
  });

  group('Address formatting', () {
    test('omits empty parts', () {
      final address = _company(address: {
        "street": "Rua A",
        "number": "10",
        "neighborhood": "Centro",
        "city": "SP",
        "state": "SP",
      }).address;

      expect(address.streetLine, "Rua A, 10");
      expect(address.cityLine, "Centro, SP - SP");
      expect(_company().address.isEmpty, isTrue);
    });
  });
}
