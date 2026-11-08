import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

/// Imagem escolhida pelo usuário, pronta para envio à API.
class PickedImage {
  /// Limite aceito pela API (2 MB).
  static const maxBytes = 2 * 1024 * 1024;

  final Uint8List bytes;
  final String name;
  final String contentType;

  const PickedImage({
    required this.bytes,
    required this.name,
    required this.contentType,
  });

  bool get isTooLarge => bytes.length > maxBytes;

  /// Tipo de conteúdo pelo nome do arquivo; a API só aceita JPEG, PNG e WebP.
  static String? contentTypeOf(String filename) {
    final dot = filename.lastIndexOf(".");
    final extension = dot < 0 ? "" : filename.substring(dot + 1).toLowerCase();

    return switch (extension) {
      "jpg" || "jpeg" => "image/jpeg",
      "png" => "image/png",
      "webp" => "image/webp",
      _ => null,
    };
  }
}

/// Abre a galeria e devolve a imagem escolhida, ou `null` se cancelou.
/// Lança [FormatException] quando o formato não é JPEG, PNG ou WebP.
Future<PickedImage?> pickGalleryImage() async {
  final file = await ImagePicker().pickImage(
    source: ImageSource.gallery,
    maxWidth: 1024,
    maxHeight: 1024,
    imageQuality: 85,
  );

  if (file == null) return null;

  final contentType =
      PickedImage.contentTypeOf(file.name) ??
      PickedImage.contentTypeOf(file.path) ??
      (const {"image/jpeg", "image/png", "image/webp"}.contains(file.mimeType)
          ? file.mimeType
          : null);

  if (contentType == null) {
    throw const FormatException("Escolha uma imagem JPEG, PNG ou WebP");
  }

  return PickedImage(
    bytes: await file.readAsBytes(),
    name: file.name,
    contentType: contentType,
  );
}
