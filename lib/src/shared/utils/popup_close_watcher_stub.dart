import 'dart:async';

/// Fora da web não há popup: nunca sinaliza.
PopupCloseWatcher watchPopupClose() => PopupCloseWatcher._();

class PopupCloseWatcher {
  PopupCloseWatcher._();

  final _never = Completer<void>();

  /// Completa quando a janela principal recupera o foco depois de perdê-lo.
  Future<void> get refocused => _never.future;

  void dispose() {}
}
