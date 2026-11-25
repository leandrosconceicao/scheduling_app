import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

PopupCloseWatcher watchPopupClose() => PopupCloseWatcher._();

/// Detecta que o popup de login foi fechado: a janela principal perde o foco
/// ao abrir o popup e o recupera quando ele fecha. O SDK do Firebase pode
/// demorar (ou nunca) rejeitar a promise nesse caso.
class PopupCloseWatcher {
  PopupCloseWatcher._() {
    web.window.addEventListener('blur', _onBlur);
    web.window.addEventListener('focus', _onFocus);
  }

  final _completer = Completer<void>();
  bool _blurred = false;

  late final JSFunction _onBlur = ((web.Event _) => _blurred = true).toJS;
  late final JSFunction _onFocus = ((web.Event _) {
    if (_blurred && !_completer.isCompleted) _completer.complete();
  }).toJS;

  Future<void> get refocused => _completer.future;

  void dispose() {
    web.window.removeEventListener('blur', _onBlur);
    web.window.removeEventListener('focus', _onFocus);
  }
}
