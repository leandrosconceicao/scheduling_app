import 'package:flutter/material.dart';

extension FormStateScroll on FormState {
  /// Valida o formulário e, se houver erro, rola até o primeiro campo inválido.
  bool validateAndScroll() {
    final valid = validate();
    if (!valid) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToFirstError());
    }
    return valid;
  }

  void _scrollToFirstError() {
    if (!context.mounted) return;
    Element? firstError;

    void visit(Element element) {
      if (firstError != null) return;
      if (element is StatefulElement) {
        final state = element.state;
        if (state is FormFieldState && state.hasError) {
          firstError = element;
          return;
        }
      }
      element.visitChildElements(visit);
    }

    (context as Element).visitChildElements(visit);

    final target = firstError;
    if (target == null || !target.mounted) return;
    Scrollable.ensureVisible(
      target,
      alignment: 0.1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }
}
