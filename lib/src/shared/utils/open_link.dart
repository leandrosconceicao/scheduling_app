import 'package:url_launcher/url_launcher.dart';

/// Abre [uri] fora do app (navegador, mapa, WhatsApp, discador).
/// Retorna `false` quando não foi possível abrir.
Future<bool> openLink(Uri uri) async {
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}
