import 'dart:typed_data';

import '../../shared/shared.dart';

/// Envio de arquivo por PUT (multipart, campo `file`). O `IHttpClient` do
/// `ltech_core` só tem `postForm`, e as rotas de imagem da API usam PUT.
abstract interface class IFormUploadClient {
  Future<ApiResponse<T?>> putForm<T>({
    required String endpoint,
    required Uint8List bytes,
    required String filename,
    required String contentType,
    Map<String, String>? headers,
    Duration? timeout,
    T Function(dynamic)? parser,
    void Function(int, int)? onSendProgress,
  });
}
